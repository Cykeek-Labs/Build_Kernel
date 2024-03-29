#!/bin/bash
# clear out screen
clear

banner(){
echo "###########################"
echo "#                         #"
echo "# Made By: CYKEEK         #"
echo "# Kernel Build Script     #"
echo "# For msm4.9 Kernel Based #"
echo "#                         #"
echo "###########################"
echo
}

# Define colors
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Function to display a message in green
green_message() {
  echo -e "$green$1$white"
}

# Function to display a message in yellow
yellow_message() {
  echo -e "$yellow$1$white"
}

# Function to display a message in red
red_message() {
  echo -e "$red$1$white"
}

clean() {
  echo
  # Clean out residuals
  red_message "<< Clean out residuals!! >>"
  sleep 1s
  echo
  rm -rf out/
  rm -rf anykernel/
  green_message "<< Residuals Cleaned!! >>"
}

# Input branch name and folder name
branch='ksu/master'
folder='msm-4.9'
repo_link='https://github.com/KanishkTheDerp/msm-4.9'
green_message "File will be saved in $folder"

sleep 1s

# Check if the folder already exists
if [ -d "$folder" ]; then
        echo
        yellow_message "This $folder is already saved, nothing to clone!"
        cd $folder
        clean
        echo
else
        yellow_message "Downloading your files from $repo_link from branch $branch....."
        echo
        git clone $repo_link -b "$branch" $folder
        cd $folder
        yellow_message "Your files have been successfully saved in $folder"
        echo
        sleep 1s
fi

# Configure build information
DEVICE="Google Pixel 3"
CODENAME="blueline"
KERNEL_NAME="MSM-4.9"
KERNEL_VER="4.9"
echo
yellow_message "Device Name is $DEVICE and Kernel Name is $KERNEL_NAME"
sleep 1s
echo

# Define Your DEFCONFIG
DEFCONFIG="b1c1_defconfig"
yellow_message "Your DEFCONFIG is $DEFCONFIG"
sleep 1s
echo

# Define Your AnyKernel Links
AnyKernel="https://github.com/Cykeek-Labs/AnyKernel3"
AnyKernelbranch="blueline"
yellow_message "Anykernel Link set to $AnyKernel -b $AnyKernelbranch"
sleep 1s
echo

# Define KBUILD Information
HOST="HyperServers"
USER="Cykeek"
yellow_message "Host Build Set to \nHOST=$HOST and USER=$USER"
sleep 1s
echo

# Define Toolchain
# 1.clang
# 2.GCC
# Define according tou your Kernel Source
TOOLCHAIN="clang"
CLANG_NAME="playground"
TOOLCHAIN_SOURCE="https://gitlab.com/PixelOS-Devices/playgroundtc.git"

GCC_Source_32="https://github.com/mvaisakh/gcc-arm"
GCC_Source_64="https://github.com/mvaisakh/gcc-arm64"

# Automation for toolchain and gcc builds
if [ "$TOOLCHAIN" == "gcc" ]; then
    if [ ! -d "$HOME/gcc64" ] && [ ! -d "$HOME/gcc32" ]; then
      yellow_message "Your Choose $TOOLCHAIN"
      echo
      sleep 1s
      green_message "<< Cloning GCC from arter >>"
      git clone --depth=1 "$GCC_Source_64" "$HOME/gcc64"
      git clone --depth=1 "$GCC_Source_32" "$HOME/gcc32"
    fi
    export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
    export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
    export KBUILD_COMPILER_STRING=$("$HOME/gcc64/bin/aarch64-elf-gcc" --version | head -n 1)
elif [ "$TOOLCHAIN" == "clang" ]; then
    if [ ! -d "$HOME/cycle/playground" ]; then
      yellow_message "Your Choose $TOOLCHAIN"
      echo
      sleep 1s
      green_message "<< Cloning r416183b1 Clang >>"
      git clone -b 17 --depth=1 "$TOOLCHAIN_SOURCE" "$HOME/cycle/playground"
    fi
    export PATH="$HOME/cycle/playground/bin:$PATH"
    export STRIP="$HOME/cycle/playground/aarch64-linux-gnu/bin/strip"
    export KBUILD_COMPILER_STRING=$("$HOME/cycle/playground/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:>]//g')
fi

# Function to build the kernel
build_kernel() {
        green_message "Executing kernel Build..."
        sleep 1s
        echo
        echo "Your Kernel Version is $KERNEL_VER"
        echo
        sleep 1s
        Start=$(date +"%s")

        if [ "$TOOLCHAIN" == "clang" ]; then
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
                CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee out/error.log
        elif [ "$TOOLCHAIN" == "gcc" ]; then
                make -j$(nproc --all) O=out \
                ARCH=arm64 \
                CROSS_COMPILE=aarch64-elf- \
                CROSS_COMPILE_ARM32=arm-eabi- 2>&1 | tee out/error.log
        fi

        End=$(date +"%s")
        Diff=$(($End - $Start))
}

# Define kernel Image location
export IMG="out/arch/arm64/boot/Image.lz4-dtb"

# Define Arch
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

# Define KBUILD HOST and USER
export KBUILD_BUILD_HOST="$HOST"
export KBUILD_BUILD_USER="$USER"

# Pre-configured Actions
green_message "Creating workspace for Kernel. Please Wait!"
echo
sleep 1s
mkdir -p out/
yellow_message "<< Copying DTS Files!! >>"
echo
sleep 1s
mkdir -p out/arch/arm64/
cp -r arch/arm64/boot out/arch/arm64/
rm -rf out/arch/arm64/boot/dts/qcom
mkdir -p out/arch/arm64/boot/dts/qcom/
cp arch/arm64/boot/dts/qcom/*.dts* out/arch/arm64/boot/dts/qcom/
green_message "<< DTS copied successfully!! >>"
echo
sleep 1s

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

# Execute kernel Building Action
yellow_message "<< Compiling the kernel >>"
echo
sleep 1s
build_kernel || error=true
DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
if [ -f "$IMG" ]; then
        green_message "<< Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >>"
        sleep 2s
        echo

        # Now Clone AnyKernel
        clear
        sleep 2s
        yellow_message "<< Cloning AnyKernel from your repo >>"
        git clone "$AnyKernel" --single-branch -b "$AnyKernelbranch" anykernel
        echo
        green_message "<< AnyKernel Cloned Successfully!! >>"

        # Move Images into anykernel Folder
        yellow_message "<< Making kernel zip >>"
        sleep 1s
        cp -r "$IMG" anykernel/ # Copy $IMG into anykernel folder
        rm -rf *zip # Remove previous residuals if have any!!
        cd anykernel
        mv Image.lz4-dtb zImage
        export ZIP="$KERNEL_NAME"-"$CODENAME"-"$DATE"
        echo

        # Zip it
        yellow_message "<< Zipping Imgs...>>"
        sleep 2s
        zip -r "$ZIP" *
        curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/Hunter-commits/AnyKernel/master/zipsigner-3.0.jar
        java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
        green_message "Files processed. The file name is $ZIP.zip Please Wait...."
        if [ -d "$ZIP.zip" ]; then
                pdup $ZIP.zip
                echo
                clean
                exit 1
        fi
else
        red_message "Failed to compile the kernel, check output for errors."
        cat out/error.log
        exit 1
fi
