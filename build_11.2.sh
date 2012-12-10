#!/bin/sh

set -e
set -u

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR"

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"

echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
../fetchurl "http://zlib.net/zlib-1.2.7.tar.bz2"
../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
../fetchurl "http://download.sourceforge.net/libpng/libpng-1.5.13.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/ogg/libogg-1.3.0.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
../fetchurl "http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2"
../fetchurl "http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.bz2?use_mirror=auto"
../fetchurl "ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20121029-2245-stable.tar.bz2"
../fetchurl "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.bz2"
../fetchurl "http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz?use_mirror=auto"
../fetchurl "http://www.ffmpeg.org/releases/ffmpeg-0.11.2.tar.gz"
../fetchurl "http://sourceforge.net/projects/sox/files/sox/14.4.0/sox-14.4.0.tar.gz"

echo "*** Building yasm ***"
cd "$BUILD_DIR/yasm-1.2.0"
./configure --prefix=$TARGET_DIR
make -j 8 && make install

echo "*** Building zlib ***"
cd "$BUILD_DIR/zlib-1.2.7"
./configure --prefix=$TARGET_DIR
make -j 8 && make install

echo "*** Building bzip2 ***"
cd "$BUILD_DIR/bzip2-1.0.6"
make
make install PREFIX=$TARGET_DIR

echo "*** Building libpng ***"
cd "$BUILD_DIR/libpng-1.5.13"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

# Ogg before vorbis
echo "*** Building libogg ***"
cd "$BUILD_DIR/libogg-1.3.0"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

# Vorbis before theora
echo "*** Building libvorbis ***"
cd "$BUILD_DIR/libvorbis-1.3.3"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

echo "*** Building libtheora ***"
cd "$BUILD_DIR/libtheora-1.1.1"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

echo "*** Building livpx ***"
cd "$BUILD_DIR/libvpx-v1.1.0"
./configure --prefix=$TARGET_DIR --disable-shared
make -j 8 && make install

echo "*** Building faac ***"
cd "$BUILD_DIR/faac-1.28"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
# FIXME: gcc incompatibility, does not work with log()
sed -i -e "s|^char \*strcasestr.*|//\0|" common/mp4v2/mpeg4ip.h
make -j 8 && make install

echo "*** Building x264 ***"
cd "$BUILD_DIR/x264-snapshot-20121029-2245-stable"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install


echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install
#rm $TARGET_DIR/lib/libxvidcore.so.*

echo "*** Building lame ***"
cd "$BUILD_DIR/lame-3.99.5"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

# FIXME: only OS-sepcific
rm -f "$TARGET_DIR/lib/*.dylib"
rm -f "$TARGET_DIR/lib/*.so"

# FFMpeg
echo "*** Building FFmpeg ***"
cd "$BUILD_DIR/ffmpeg-0.11.2"
patch -p1 <../../ffmpeg_config_11.2.patch
CFLAGS="-I$TARGET_DIR/include" LDFLAGS="-L$TARGET_DIR/lib -lm" ./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --disable-ffplay --disable-ffserver --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-nonfree --enable-version3 --enable-libvpx --disable-devices
make -j 8 && make install

# SOX
echo "*** Building Sox ***"
cd "$BUILD_DIR/sox-14.4.0"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 8 && make install

# reminder
echo "NOTE: all files were cached in ~/.cache/fetchurl. remove that dir if no longer needed."

