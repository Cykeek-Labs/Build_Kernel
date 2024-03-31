############################################
#    Initializing Environment variables    #
############################################

# Initialize Repository
Source='https://github.com/Cykeek/kernel_realme_sm8350'
Branch='test'
Folder='sm8350'
echo -e "<< Repository Has Successfully Been Cloned in $Folder >>"

# Add Checks whether the defined folder is Available or not
if [ -d $Folder ]; then
	echo
	echo " $Folder Already there!! "
	echo
	echo " Skipping Cloning Process!! "
	cd $Folder
	echo "<< You're now in $PWD >>"
	echo
else
	git clone $Source -b "$Branch" $Folder
	cd $Folder
	echo "<< You're now in $PWD >>"
	echo
fi

# Store Kernel Folder location in KERNEL_DIR
Kernel_Dir=$(pwd) # inside the kernel folder location is stored in kernel_Dir

# Cleanup Some directories
refresh() {
	clear
	rm -rf out/
	rm -rf anykernel/
	rm -rf .config
	find "$Kernel_Dir" -type f -name "*.a.symversions" -delete # Remove every files named as '.a.symversions' from every directory in current directory recursively
	find "$Kernel_Dir/arch/arm64/boot/dts/vendor/oplus/" -type f -name "*.dtbo" -delete # Remove every files named as '.dtbo' from every directory in current directory recursively
	echo -e "<< Residuals Cleaned >>"
	echo
}

refresh

# Configure kernel Workflow
Defconfig="vendor/lahaina-qgki_defconfig" # Define Stock Defconfig
DTB_PATH="$Kernel_Dir/out/arch/arm64/boot/dts" # Define Stock DTBs paths
DTBO_PATH="$Kernel_Dir/out/arch/arm64/boot" # Define Stock DTBOs paths
IMG="$Kernel_Dir/out/arch/arm64/boot/Image" # Define Output Image format refer to arch/arm64/Makefile:"ifeq ($(CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP),y)"

# Generating .config (adapted from 'https://github.com/narikootam-dev/Kernel-Compile-Script/blob/sweet/regen.sh')
generate_config(){
	echo "<< Generating .config >>"
	make $Defconfig
	cp .config arch/arm64/configs/$Defconfig
	echo -e "<< regenerated $Defconfig >>"
	echo
}

# Define Arch
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

# Define KBUILD Information
HOST="Google"
USER="Cykeek"
echo -e "<< Host Build Set to: >>"
echo -e " HOST= $HOST "
echo -e " USER= $USER "
echo

################################
# Configure Toolchains / Clang #
################################
# Choose your desired option
# Toolchain= 'clang' OR 'gcc'
Toolchain='clang'
Clang_Name='playground'
Toolchain_Source="https://gitlab.com/PixelOS-Devices/playgroundtc.git"

# GCC Compiler Links
GCC_Source_32="https://github.com/mvaisakh/gcc-arm"
GCC_Source_64="https://github.com/mvaisakh/gcc-arm64"

# Compiler Setup
if [ "$Toolchain" = "clang" ]; then
	if [ ! -d "$HOME/clang" ]; then
		echo -e "<< You Choose $Toolchain for this operation >>"
		echo
		git clone --depth=1 $Toolchain_Source "$HOME/clang"
		echo
	fi
	export PATH="$HOME/clang/bin:$PATH"
	export STRIP="$HOME/clang/aarch64-linux-gnu/bin/strip"
	echo
	echo -e "<< Clang Setup has been successfully processed!! >>"
	echo
elif [ "$Toolchain" = "gcc" ]; then
	if [ ! -d "$HOME/gcc32" ] && [ ! -d "$HOME/gcc64" ]; then
		echo -e "<< You Choose $Toolchain for this operation >>"
		echo
		git clone --depth=1 "$GCC_Source_64" "$HOME/gcc64"
		git clone --depth=1 "$GCC_Source_32" "$HOME/gcc32"
		echo
	fi
	export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
    export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
    export KBUILD_COMPILER_STRING=$("$HOME/gcc64/bin/aarch64-elf-gcc" --version | head -n 1)
	echo
	echo -e "<< GCC Setup has been successfully processed!! >>"
	echo
fi

# Build Kernel
build_kernel(){
	if [ "$Toolchain" = "clang" ]; then
		generate_config
		make $Defconfig O=out
		make -j$(nproc --all) O=out \
		ARCH=arm64 \
		CC=clang \
		AR=llvm-ar \
		NM=llvm-nm \
		BRAND_SHOW_FLAG=realme \
		CROSS_COMPILE=aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
		DTC_FLAGS+=-q \
		DTC_EXT=$(which dtc) \
		LLVM_IAS=1 \
		LLVM=1 \
		STRIP=llvm-strip \
       	OBJCOPY=llvm-objcopy \
       	OBJDUMP=llvm-objdump \
       	OBJSIZE=llvm-size \
       	READELF=llvm-readelf \
       	HOSTCC=clang \
       	HOSTCXX=clang++ \
       	HOSTAR=llvm-ar \
		HOSTLD=ld.lld \
		KBUILD_BUILD_USER=$USER \
		KBUILD_BUILD_HOST=$HOST \
		CONFIG_DEBUG_SECTION_MISMATCH=y \
		CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee "$Kernel_Dir/out/error.log"
   	elif [ "$Toolchain" = "gcc" ]; then
		make $Defconfig O=out
		make -j$(nproc --all) O=out \
       	ARCH=arm64 \
       	CROSS_COMPILE=aarch64-elf- \
       	CROSS_COMPILE_ARM32=arm-eabi- 2>&1 | tee "$Kernel_Dir/out/error.log"
    fi

	# Show Build Time
	Start=$(date +"%s")
	End=$(date +"%s")
	Diff=$(($End - $Start))
}

# Configure OUT Folder
if [ -d "$Kernel_Dir/out" ]; then
	echo "<< OUT directory found >>"
	echo "<< Cloning DTS files >>"
	mkdir -p $Kernel_Dir/out/arch/arm64/
	cp -r $Kernel_Dir/arch/arm64/boot/ $Kernel_Dir/out/arch/arm64/
	mkdir -p $Kernel_Dir/out/arch/arm64/boot/dts/
	cp -r $Kernel_Dir/arch/arm64/boot/dts/vendor/* $Kernel_Dir/out/arch/arm64/boot/dts/vendor/
	echo "<< DTS Files Copied >>"
else
	echo "<< OUT Folder not found >>"
	mkdir $Kernel_Dir/out
	echo
	echo "<< OUT Folder Created >>"
	echo
	echo "<< Cloning DTS files >>"
	mkdir -p $Kernel_Dir/out/arch/arm64/
	cp -r $Kernel_Dir/arch/arm64/boot/ $Kernel_Dir/out/arch/arm64/
	mkdir -p $Kernel_Dir/out/arch/arm64/boot/dts/
	cp -r $Kernel_Dir/arch/arm64/boot/dts/vendor/* $Kernel_Dir/out/arch/arm64/boot/dts/vendor/
	echo "<< DTS Files Copied >>"
fi

# Execute kernel Build Action
echo "<< Kernel Compiling Started!! >>"
echo
make O=out clean && make O=out mrproper
build_kernel || error=true
DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
if [ -f "$IMG" ]; then
	echo -e "<< Build Completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >>"
	sleep 1s
	echo
	echo "<< Clearing residuals >>"
else
	echo -e "<< Error found !! >>"
	exit 1
fi	

# Authorships:
# 1. TogoFire
# 1. KanishkTheDerp
# 1. MarijnS95
# 1. jerpelea
