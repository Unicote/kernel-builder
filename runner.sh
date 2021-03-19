#!/bin/bash
echo "***Kernel Builder***"
BUILD_START=$(date +"%s")
apt-get update
apt-get upgrade -y
apt-get -y update && apt-get -y upgrade && apt-get -y install bc build-essential zip curl libstdc++6 git wget python gcc clang libssl-dev repo rsync flex bison
echo $TG_API > /tmp/TG_API
echo $TG_CHAT > /tmp/TG_CHAT
echo $DEFCONFIG > /tmp/DEFCONFIG
echo $LINK > /tmp/LINK
echo $BRANCH > /tmp/BRANCH
echo $DEVICE > /tmp/DEVICE
export TELEGRAM_TOKEN=$(cat /tmp/TG_API)
export TELEGRAM_CHAT=$(cat /tmp/TG_CHAT)
export KBUILD_BUILD_USER="Unicote"
export KBUILD_BUILD_HOST="K703LX"
export ARCH=arm64
export SUBARCH=arm64
export TZ=Europe/Moscow
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
echo `pwd` > /tmp/loc
alias python=python3
ls
git clone $(cat /tmp/LINK) -b $(cat /tmp/BRANCH) kernel
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
ls
CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/ */ /g' -e 's/[[:space:]]*$//')
TANGGAL=$(date +"%F-%S")
## Copy this script inside the kernel directory
KERNEL_DEFCONFIG=surya_defconfig
export CONFIG_PATH=$PWD/arch/arm64/configs/surya_defconfig
export PATH=$PWD/clang/bin:$PATH
ANYKERNEL3_DIR=$PWD/kernel/AnyKernel3/
IMAGE=kernel/out/arch/arm64/boot/Image.gz-dtb
export ARCH=arm64
export SUBARCH=arm64
# Speed up build process
MAKE="./makeparallel"
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo "**** Kernel defconfig is set to $(cat /tmp/DEFCONFIG) ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
bot/telegram -M "• UniKernel •
Build started on drone.io
Device: Poco X3 (surya)
branch: main
Using compiler: $CLANG_VERSION
Started on: $(date)
Build Status: #Wip"

cd kernel
function compile() {
   make O=out ARCH=arm64 surya_defconfig
       make -j$(nproc --all) O=out \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip
                      
if [ -f out/arch/arm64/boot/Image.gz-dtb ]
  then
     ls .
     cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
     cp out/arch/arm64/boot/dtbo.img AnyKernel3
     zipping
  else
     ls .
     error
  fi
}

echo "**** Done, here is your sha1 ****"
#-----------------------------------------#
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 UniKernel-surya-$TANGGAL.zip *
    upload
}
#-----------------------------------------#
function upload() {
    ZIP=$(echo *.zip)
    bot/telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    ls .
    cd ../..
    bot/telegram -f kernel/AnyKernel3/UniKernel-surya-$TANGGAL.zip

}
#-------------------------------------------#
function error() {
    cd ..
    ls .
    bot/telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds
$((TIME_DIFF / 60)) minute(s) and $((TIME_DIFF % 60)) seconds"
    exit 1
}
CLANG_TRIPLE=aarch64-linux-gnu- 2>&1| tee error.log
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))
compile
