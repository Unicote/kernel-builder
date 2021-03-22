#!/bin/bash
echo "***Kernel Builder***"
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
DATE=$(TZ=Europe/Moscow date +"%Y%m%d-%T")
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
echo `pwd` > /tmp/loc
alias python=python3
ls
CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/ */ /g' -e 's/[[:space:]]*$//')
KERNEL_DEFCONFIG=surya_defconfig
export CONFIG_PATH=$PWD/arch/arm64/configs/surya_defconfig
export PATH=$PWD/clang/bin:$PATH
IMAGE=out/arch/arm64/boot/Image.gz-dtb
export ARCH=arm64
export SUBARCH=arm64

MODEL="POCO X3 NFC"
DEVICE=surya
DISTRO=$(cat /etc/issue)
KERVER=$(make kernelversion)
PROCS=$(nproc --all)
KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
LINKER=ld.lld
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_HEAD=$(git log --oneline -1)
AUTHOR="Unicote"
export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
export CI_BRANCH=$DRONE_BRANCH	
export BASEDIR=$DRONE_REPO_NAME # overriding
export SERVER_URL="${DRONE_SYSTEM_PROTO}://${DRONE_SYSTEM_HOSTNAME}/${AUTHOR}/${BASEDIR}/${KBUILD_BUILD_VERSION}"

echo "**** Kernel defconfig is set to $(cat /tmp/DEFCONFIG) ****"
echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"
bot/telegram -M "*${KBUILD_BUILD_VERSION} CI Build Triggered*
*Docker OS*: $DISTRO
*Kernel Version*: $KERVER
*Date*: $(TZ=Europe/Moscow date)
*Device*: $MODEL ($DEVICE)
*Pipeline Host*: $KBUILD_BUILD_HOST
*Host Core Count*: $PROCS
*Compiler Used*: $KBUILD_COMPILER_STRING
*Linker*: $LINKER
*Branch*: $CI_BRANCH
*Top Commit*: $COMMIT_HEAD"
bot/telegram -D "Link: $SERVER_URL"

#-----------------------------------------#
function compile() {
   BUILD_START=$(date +"%s")
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
     BUILD_END=$(date +"%s")
     BUILD_DIFF=$((BUILD_END - BUILD_START))
     zipping
  else
     BUILD_END=$(date +"%s")
     BUILD_DIFF=$((BUILD_END - BUILD_START))
     ls .
     error
  fi
}

echo "**** Done, here is your sha1 ****"
#-----------------------------------------#
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 UNIKERNEL-SURYA-$DATE.zip *
    upload
}
#-----------------------------------------#
function upload() {
    ZIP=$(echo *.zip)
    cd ..
    bot/telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    bot/telegram -f AnyKernel3/UNIKERNEL-SURYA-$DATE.zip
    ls .

}
#-----------------------------------------#
function error() {
    ls .
    bot/telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    exit 1
}
CLANG_TRIPLE=aarch64-linux-gnu- 2>&1| tee error.log
compile
