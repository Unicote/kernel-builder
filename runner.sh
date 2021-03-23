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
export TZ=Europe/Moscow
export DEBIAN_FRONTEND=noninteractive
export DATE=$(TZ=Europe/Moscow date +"%Y%m%d-%T")
export DEFCONFIG=surya_defconfig
export KERNEL_DIR="$(pwd)"
export ARCH=arm64
export SUBARCH=arm64
export MODEL="POCO X3 NFC"
export DEVICE=surya
export DISTRO=$(cat /etc/issue)
export KERVER=$(make kernelversion)
export PROCS=$(nproc --all)
export LINKER=ld.lld
export CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
export AUTHOR="Unicote"
export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
export CI_BRANCH=$DRONE_BRANCH	
export BASEDIR=$DRONE_REPO_NAME # overriding
export SERVER_URL="${DRONE_SYSTEM_PROTO}://${DRONE_SYSTEM_HOSTNAME}/${AUTHOR}/${BASEDIR}/${KBUILD_BUILD_VERSION}"

msg() {
	echo
    echo -e "\e[1;32m$*\e[0m"
    echo
}

err() {
    echo -e "\e[1;41m$*\e[0m"
    exit 1
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata
echo `pwd` > /tmp/loc
alias python=python3


clone() {
	echo " "
	msg "|| Cloning Clang-13 ||"
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
	TC_DIR=$KERNEL_DIR/clang

	msg "|| Cloning Anykernel ||"
	git clone --depth 1 --no-single-branch https://github.com/"$AUTHOR"/AnyKernel3.git
}

export CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/ */ /g' -e 's/[[:space:]]*$//')
export CONFIG_PATH=$PWD/arch/arm64/configs/surya_defconfig
export PATH=$PWD/clang/bin:$PATH
export IMAGE=out/arch/arm64/boot/Image.gz-dtb
export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
export KBUILD_BUILD_HOST=$DRONE_SYSTEM_HOST
export KBUILD_BUILD_USER=$AUTHOR
SUBARCH=$ARCH
KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
PATH=$TC_DIR/bin/:$PATH

echo -e "***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************"

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
msg "|| Started Compilation ||"
   BUILD_START=$(date +"%s")
   make O=out ARCH=arm64 surya_defconfig
       make -j$(nproc --all) O=out \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip | tee error.log
                      
        BUILD_END=$(date +"%s")
        BUILD_DIFF=$((BUILD_END - BUILD_START))

  if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/Image.gz-dtb ]
    then
         cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
         zipping
    else
        bot/telegram -f "error.log" "Build failed to compile after $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    exit 1
  fi
	
}

echo "**** Done, here is your sha1 ****"
#-----------------------------------------#
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 UNICORE-SURYA-$DATE.zip *
    upload
}
#-----------------------------------------#
function upload() {
    ZIP=$(echo *.zip)
    cd ..
    bot/telegram -f AnyKernel3/UNICORE-SURYA-$DATE.zip "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

}
clone
compile
