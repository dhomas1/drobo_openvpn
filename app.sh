### PCRE ###
_build_pcre() {
local VERSION="8.37"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --enable-shared --disable-static \
  --disable-cpp --enable-utf --enable-unicode-properties
make
make install
popd
}

### LIBSEPOL ###
_build_libsepol() {
local VERSION="2.4"
local FOLDER="libsepol-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make install ARCH="arm" DESTDIR="${DEPS}" PREFIX="${DEPS}" \
  LIBDIR="${DEST}/lib" SHLIBDIR="${DEST}/lib"
rm -vf "${DEST}/lib/libsepol.a"
popd
}

### LIBSELINUX ###
# requires pcre, libsepol
_build_libselinux() {
local VERSION="2.4"
local FOLDER="libselinux-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make install ARCH="arm" DESTDIR="${DEPS}" PREFIX="${DEPS}" \
  LIBDIR="${DEST}/lib" SHLIBDIR="${DEST}/lib"
rm -vf "${DEST}/lib/libselinux.a"
popd
}

### LZO ###
_build_lzo() {
local VERSION="2.09"
local FOLDER="lzo-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.oberhumer.com/opensource/lzo/download/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --enable-shared --disable-static
make
make install
popd
}

### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### OPENVPN ###
_build_openvpn() {
local VERSION="2.3.8"
local FOLDER="openvpn-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://swupdate.openvpn.org/community/releases/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man" \
  --enable-shared --disable-static \
  --with-crypto-library=openssl \
  --disable-plugin-auth-pam --enable-selinux \
  --enable-password-save
make
make install
popd
}

_build() {
  _build_pcre
  _build_libsepol
  _build_libselinux
  _build_lzo
  _build_zlib
  _build_openssl
  _build_openvpn
  _package
}
