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
branch='stable'
folder='sdm710'
repo_link='https://github.com/Cykeek-Labs/kernel_realme_sdm710'
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
DEVICE="Realme 3 Pro"
CODENAME="RMX1851"
KERNEL_NAME="Meraki-SDM710"
KERNEL_VER="4.9"
echo
yellow_message "Device Name is $DEVICE and Kernel Name is $KERNEL_NAME"
sleep 1s
echo

# Define Your DEFCONFIG
DEFCONFIG="lineageos_RMX1851_defconfig"
yellow_message "Your DEFCONFIG is $DEFCONFIG"
sleep 1s
echo

# Define Your AnyKernel Links
AnyKernel="https://github.com/Cykeek-Labs/AnyKernel3.git"
AnyKernelbranch="main"
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
CLANG_NAME="Playground"
TOOLCHAIN_SOURCE="https://gitlab.com/PixelOS-Devices/playgroundtc.git"

GCC_Source_32="https://github.com/mvaisakh/gcc-arm"
GCC_Source_64="https://github.com/mvaisakh/gcc-arm64"

# Automation for toolchain and gcc builds
if [ "$TOOLCHAIN" == "gcc" ]; then
    if [ ! -d "$HOME/cykeek/gcc64" ] && [ ! -d "$HOME/cykeek/gcc32" ]; then
      yellow_message "Your Choose $TOOLCHAIN"
      echo
      sleep 1s
      green_message "<< Cloning GCC from arter >>"
      git clone --depth=1 "$GCC_Source_64" "$HOME/cykeek/gcc64"
      git clone --depth=1 "$GCC_Source_32" "$HOME/cykeek/gcc32"
    fi
    export PATH="$HOME/cykeek/gcc64/bin:$HOME/cykeek/gcc32/bin:$PATH"
    export STRIP="$HOME/cykeek/gcc64/aarch64-elf/bin/strip"
    export KBUILD_COMPILER_STRING=$("$HOME/cykeek/gcc64/bin/aarch64-elf-gcc" --version | head -n 1)
elif [ "$TOOLCHAIN" == "clang" ]; then
    if [ ! -d "$HOME/cykeek/playground_clang" ]; then
      yellow_message "Your Choose $TOOLCHAIN"
      echo
      sleep 1s
      green_message "<< Cloning Playground Clang >>"
      git clone -b 17 --depth=1 "$TOOLCHAIN_SOURCE" "$HOME/cykeek/playground_clang"
    fi
    export PATH="$HOME/cykeek/playground_clang/bin:$PATH"
    export STRIP="$HOME/cykeek/playground_clang/aarch64-linux-gnu/bin/strip"
    export KBUILD_COMPILER_STRING=$("$HOME/cykeek/playground_clang/bin/clang" --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:>]//g')
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
export IMG="out/arch/arm64/boot/Image.gz-dtb"

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
        mv Image.gz-dtb zImage
        export ZIP="$KERNEL_NAME"-"$CODENAME"-"$DATE"
        echo

        # Zip it
        yellow_message "<< Zipping Imgs...>>"
        sleep 2s
        zip -r "$ZIP" *
        curl -sLo zipsigner-3.0.jar https://raw.githubusercontent.com/Hunter-commits/AnyKernel/master/zipsigner-3.0.jar
        java -jar zipsigner-3.0.jar "$ZIP".zip "$ZIP"-signed.zip
        green_message "Files processed. The file name is $ZIP.zip Please Wait...."
        echo
        sleep 1s

        # Check Upload server Connection is alive or not
        # banner
        upload_banner() {
          clear
          sleep 2s
          echo "###########################################"
          sleep 1s
          echo "#             UPLOADING                   #"
          sleep 1s
          echo "# NOTICE: Don't Upload any Pirate Stuff   #"
          sleep 1s
          echo "# in devuploads or temp.sh u might kill   #"
          sleep 1s
          echo "# their services with copyrights like our #"
          sleep 1s
          echo "# beloved temp.sh #RIP                    #"
          sleep 1s
          echo "###########################################"
          sleep 1s
          echo
        }
        # Temp.sh
        server_address="temp.sh"

        # Devuploads
        Server_Name="devuploads.com" # before adding any website name check whethere it's pinging or not like 'ping google.com'
        server_address1="https://devuploads.com/upload.sh" # Specific to Upload server upload automtion!! refer to website or contact admin
        KEY="" # Devuploads provide API key to establish connections

        # Custom
        custom_service="/var/www/html/RMX1851/"

        # Check if the server is alive using ping
        if ping -c 1 "$server_address" &> /dev/null; then
                upload_banner
                green_message "Server $server_address is alive."
                red_message "Uploading..."
                echo
                sleep 1s
                curl -T "$ZIP".zip temp.sh
                red_message "Uploaded!!"
                cd ..
                clean
                banner
                exit 1
        elif ping -c 1 "$Server_Name" &> /dev/null; then
                upload_banner
                green_message "Devuploads is Alive."
                red_message "Uploading..."
                echo
                sleep 1s
                bash <(curl -s $server_address1) -f "$ZIP".zip -k $KEY
                sleep 1s
                echo "$ZIP.zip is uploaded!!"
                cd ..
                clean
                banner
                exit 1
        else
                # custom command for custom upload folder
                upload_banner
                green_message "$server_address is down."
                green_message "as of now upload service has been switched to $custom_service"
                sleep 2s
                echo
                echo "Cleanup Previous Uploaded Folder!!"
                rm -rf /var/www/html/RMX1851/Meraki-SDM710-RMX1851-*.zip # clean out previous similar files to avoid conflicts @_@
                echo
                sleep 1s
                green_message "residuals Cleaned up in $custom_service"
                echo
                red_message "Uploading......"
                echo
                sleep 1s
                cp -a "$ZIP".zip "$custom_service"
                red_message "Uploaded!!"
                echo
                sleep 1s
                echo "Please head to http://94.130.205.48/RMX1851/$ZIP.zip"
                sleep 1s
                cd ..
                clean
                banner
                exit 1
        fi
else
        red_message "Failed to compile the kernel, check output for errors."
        cat out/error.log | curl -F 'f:1=<-' ix.io
        clean
        exit 1
fi
