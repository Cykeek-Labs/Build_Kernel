#!/bin/bash
#
# Copyright (C) 2020 Fox kernel project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out/
rm -rf anykernel/

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks
# Clone Kernel
# DEVICE = your device codename
# KERNEL_NAME = the name of ur kranul
#
# DEFCONFIG = defconfig that will be used to compile the kernel
#
# AnyKernel = the url of your modified anykernel script
# AnyKernelbranch = the branch of your modified anykernel script
#
# HOSST = build host
# USEER = build user
#
# TOOLCHAIN = the toolchain u want to use "gcc/clang"
echo -e "$green << cloning kernel >> \n $white"
git clone https://github.com/Cykeek-Labs/kernel_realme_sdm710 stable_sdm710
cd stable_sdm710
echo
echo -e "$green << kernel cloned >> \n $white"

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi


DEVICE="Realme 3 Pro"
CODENAME="RMX1851"
KERNEL_NAME="Meraki"

DEFCONFIG="lineageos_RMX1851_defconfig"

AnyKernel="https://github.com/Cykeek-Labs/AnyKernel3.git"
AnyKernelbranch="main"

HOSST="CykeekLabs"
USEER="Cykeek"

TOOLCHAIN="clang"

# Now let's clone gcc/clang on HOME dir
# And after that , the script start the compilation of the kernel it self
# For regen the defconfig . use the regen.sh script

if [ "$TOOLCHAIN" == gcc ]; then
        if [ ! -d "$HOME/cykeek/gcc64" ] && [ ! -d "$HOME/cykeek/gcc32" ]
        then
                echo -e "$green << cloning gcc from arter >> \n $white"
                git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/cykeek/gcc64
                git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/cykeek/gcc32
        fi
        export PATH="$HOME/cykeek/gcc64/bin:$HOME/cykeek/gcc32/bin:$PATH"
        export STRIP="$HOME/cykeek/gcc64/aarch64-elf/bin/strip"
        export KBUILD_COMPILER_STRING=$("$HOME"/cykeek/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
elif [ "$TOOLCHAIN" == clang ]; then
        if [ ! -d "$HOME/cykeek/playground_clang" ]
        then
                echo -e "$green << cloning playground clang >> \n $white"
                git clone -b 17 --depth=1 https://gitlab.com/PixelOS-Devices/playgroundtc.git "$HOME"/cykeek/playground_clang
        fi
        export PATH="$HOME/cykeek/playground_clang/bin:$PATH"
        export STRIP="$HOME/cykeek/playground_clang/aarch64-linux-gnu/bin/strip"
        export KBUILD_COMPILER_STRING=$("$HOME"/cykeek/playground_clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
fi

# Setup build process

build_kernel() {
Start=$(date +"%s")

if [ "$TOOLCHAIN" == clang  ]; then
        echo clang
        make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              CC=clang \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              STRIP=llvm-strip \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              OBJSIZE=llvm-size \
                              READELF=llvm-readelf \
                              HOSTCC=clang \
                              HOSTCXX=clang++ \
                              HOSTAR=llvm-ar \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                              CONFIG_DEBUG_SECTION_MISMATCH=y \
                              CONFIG_NO_ERROR_ON_MISMATCH=y   2>&1 | tee out/error.log
elif [ "$TOOLCHAIN" == gcc  ]; then
        echo gcc
        make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              CROSS_COMPILE=aarch64-elf- \
                              CROSS_COMPILE_ARM32=arm-eabi- 2>&1 | tee out/error.log
fi

End=$(date +"%s")
Diff=$(($End - $Start))
}

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb

# Let's start

echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"

mkdir -p out/
echo -e "$green << Copying dts >> \n $white"
mkdir -p out/arch/arm64/
cp -r arch/arm64/boot out/arch/arm64/
rm -rf out/arch/arm64/boot/dts/qcom
mkdir -p out/arch/arm64/boot/dts/qcom/
cp arch/arm64/boot/dts/qcom/*.dts* out/arch/arm64/boot/dts/qcom/

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)

        if [ -f "$IMG" ]; then
                echo -e "$green << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
        else
                echo -e "$red << Failed to compile the kernel , Check up to find the error >>$white"
                cat out/error.log | curl -F 'f:1=<-' ix.io
                rm -rf testing.log
                rm -rf anykernel/
                rm -rf out/
                exit 1
        fi

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone "$AnyKernel" --single-branch -b "$AnyKernelbranch" anykernel
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" anykernel/
                cd anykernel
                mv Image.gz-dtb zImage
                export ZIP="$KERNEL_NAME"-"$CODENAME"-"$DATE"
                zip -r "$ZIP" *
                curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/Hunter-commits/AnyKernel/master/zipsigner-3.0.jar
                java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
                echo -e "$green Uploading... \n $red"
                # curl -sL https://git.io/file-transfer | sh && ./transfer "$ZIP".zip
                curl -T "$ZIP".zip temp.sh
                echo -e "$red Uploaded!! \n $white"
                cd ..
                rm -rf anykernel/
                rm -rf out/
                exit
        fi
