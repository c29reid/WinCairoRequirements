include(vcpkg_common_functions)

set(LIBRESSL_VERSION 3.0.2)

# Get archive
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz"
    FILENAME "libressl-${LIBRESSL_VERSION}.tar.gz"
    SHA512 19226da3bc9776e1da40b8e94dfa53564d5e6acc80edee539ba12d7a75c1bb8c0603e7633f26a6ef8b12adc56bb677ccda448575aa6be2ad3df5447465a4b080
)

# Patches
set(LIBRESSL_PATCHES
    ${CMAKE_CURRENT_LIST_DIR}/patches/0001-Remove-postfix-from-archive-name.patch
    ${CMAKE_CURRENT_LIST_DIR}/patches/0002-Disable-additional-warnings-for-Visual-Studio.patch
)

# Extract archive
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${LIBRESSL_VERSION}
    PATCHES ${LIBRESSL_PATCHES}
)

# Run CMake build
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DLIBRESSL_APPS=OFF
        -DLIBRESSL_TESTS=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

# Prepare distribution
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/share/man)
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/libressl RENAME copyright)
file(
    INSTALL 
        ${SOURCE_PATH}/apps/openssl/cert.pem
        ${SOURCE_PATH}/apps/openssl/openssl.cnf
        ${SOURCE_PATH}/apps/openssl/x509v3.cnf
    DESTINATION ${CURRENT_PACKAGES_DIR}/etc/ssl
)
file(WRITE ${CURRENT_PACKAGES_DIR}/share/libressl/version ${LIBRESSL_VERSION})
