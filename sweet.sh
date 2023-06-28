#!/bin/bash
#set -e
echo -e "$blue << Cleaning Previous build!! >> \n white"
rm -rf /var/www/html/sweet/MerakiKernel-sweet-*.zip

echo -e "$green << initializing compilation script >> \n $white"
echo -e "$green << Cloning Kernel from Cykeek-Labs >> \n $white"
git clone https://github.com/Cykeek-Labs/Kernel_xiaomi_sm6150 sm6150
echo -e "$green << cloned kernel successfully >> \n $white"

echo -e "$yellow << Entered sm6150 Folder!! >> \n $white"
cd sm6150
echo

# Tool Chain
echo -e "$green << cloning gcc >> \n $white"
git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
echo -e "$green << cloned gcc successfully >> \n $white"

# Clang
echo -e "$green << cloning clang >> \n $white"
git clone -b 17 --depth=1 https://gitlab.com/PixelOS-Devices/playgroundtc.git "$HOME"/clang
echo -e "$green << cloned  clang successfully >> \n $white"

KERNEL_DEFCONFIG=vendor/sweet_user_defconfig
date=$(date +"%Y-%m-%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
export zipname="MerakiKernel-sweet-${date}.zip"
export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
export PATH="$HOME/clang/bin:$PATH"
export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:sp>


# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
make $KERNEL_DEFCONFIG O=out CC=clang
make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee out/error.log
export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz
export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

find out/arch/arm64/boot/dts/ -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb
if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ] && [ -f "out/arch/arm64/boot/dtb" ]; then
        echo "------ Finishing  Build ------"
        echo "------ Cloning AnyKernel -----"
        git clone -q https://github.com/Sm6150-Sweet/AnyKernel3
        cp out/arch/arm64/boot/Image.gz AnyKernel3
        cp out/arch/arm64/boot/dtb AnyKernel3
        cp out/arch/arm64/boot/dtbo.img AnyKernel3
        rm -f *zip
        cd AnyKernel3
        sed -i "s/is_slot_device=0/is_slot_device=auto/g" anykernel.sh
        zip -r9 "../${zipname}" * -x '*.git*' README.md *placeholder >> /dev/null
                cd ..
        rm -rf AnyKernel3
        echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
        echo ""
        echo -e ${zipname} " is ready!"
        echo ""
        # Upload Zip
        echo -e "$green << Uploading Zip >> \n $white"
        cp -a ${zipname} /var/www/html/sweet/
        echo -e "$green << Uploading Done>> \n $white"
        # Remove
        rm ${zipname}
        rm -rf out
else
        echo -e "\n Compilation Failed!"
        cat out/error.log | curl -F 'f:1=<-' ix.io
        rm -rf out
        exit
fi
