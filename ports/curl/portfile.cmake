include(vcpkg_common_functions)

set(CURL_VERSION 7.68.0)
string(REPLACE "." "_" CURL_TAG ${CURL_VERSION})

# Get archive
vcpkg_download_distfile(ARCHIVE
    URLS "https://github.com/curl/curl/releases/download/curl-${CURL_TAG}/curl-${CURL_VERSION}.zip"
    FILENAME "curl-${CURL_VERSION}.zip"
    SHA512 a0c65f0a7657c95a673ce03f88c7a7db3c9362bfe495208f952676db9a4e438b3e5db41cb29b16d00cbbc923734ef894c03453d698a868417a3344571d01e2c8
)

# Patches
set(CURL_PATCHES
    ${CMAKE_CURRENT_LIST_DIR}/patches/0001-Adjust-CMake-for-vcpkg.patch
    # Remove after https://github.com/curl/curl/pull/4784 lands in a release
    ${CMAKE_CURRENT_LIST_DIR}/patches/0002-ConnectionExists-respect-the-max_concurrent_streams-limits.patch
    # Remove after https://github.com/curl/curl/pull/4858 lands in a release
    ${CMAKE_CURRENT_LIST_DIR}/patches/0003-multi_done-if-multiplexed-make-conn-data-point-to-another-transfer.patch
)

# Extract archive
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${CURL_VERSION}
    PATCHES ${CURL_PATCHES}
)

# Run CMake build
set(BUILD_OPTIONS
    # BUILD options
    -DBUILD_CURL_EXE=OFF
    -DBUILD_TESTING=OFF
    # CMAKE options
    -DCMAKE_USE_GSSAPI=OFF
    -DCMAKE_USE_LIBSSH2=OFF
    -DCMAKE_USE_OPENLDAP=OFF
    # CURL options
    -DCURL_BROTLI=ON
    -DCURL_ZLIB=ON
    -DCURL_DISABLE_COOKIES=ON
    -DCURL_DISABLE_CRYPTO_AUTH=OFF
    -DCURL_DISABLE_DICT=ON
    -DCURL_DISABLE_FILE=OFF
    -DCURL_DISABLE_FTP=ON
    -DCURL_DISABLE_GOPHER=ON
    -DCURL_DISABLE_HTTP=OFF
    -DCURL_DISABLE_IMAP=ON
    -DCURL_DISABLE_LDAP=ON
    -DCURL_DISABLE_LDAPS=ON
    -DCURL_DISABLE_POP3=ON
    -DCURL_DISABLE_PROXY=OFF
    -DCURL_DISABLE_RTSP=ON
    -DCURL_DISABLE_SMTP=ON
    -DCURL_DISABLE_TELNET=ON
    -DCURL_DISABLE_TFTP=ON
    # ENABLE options
    -DENABLE_ARES=OFF
    -DENABLE_MANUAL=OFF
    -DENABLE_THREADED_RESOLVER=ON
    # USE options
    -DUSE_NGHTTP2=ON
    -DUSE_WIN32_LDAP=OFF
)

# Check for IPV6 feature
if (ipv6 IN_LIST FEATURES)
    message(STATUS "Enabling IPV6")
    set(BUILD_OPTIONS ${BUILD_OPTIONS} -DENABLE_IPV6=ON)
else ()
    set(BUILD_OPTIONS ${BUILD_OPTIONS} -DENABLE_IPV6=OFF)
endif ()

if (NOT VCPKG_CMAKE_SYSTEM_NAME OR VCPKG_CMAKE_SYSTEM_NAME MATCHES "^Windows")
    set(VCPKG_WINDOWS ON)
endif ()

string(COMPARE EQUAL ${VCPKG_LIBRARY_LINKAGE} static CURL_STATICLIB)
if (VCPKG_WINDOWS)
    list(APPEND BUILD_OPTIONS -DCURL_STATIC_CRT=${CURL_STATICLIB})
endif ()

set(USE_OPENSSL ON)
if (NOT ssl IN_LIST FEATURES)
    message(STATUS "Using system SSL library")

    if (VCPKG_WINDOWS)
        set(USE_OPENSSL OFF)
        set(USE_WINSSL ON)
    endif ()
endif ()

if (NOT VCPKG_WINDOWS OR VCPKG_TARGET_ARCHITECTURE MATCHES "^arm")
    message(STATUS "Cross compiling curl")

    # When cross compiling curl it does not have the ability to use CMake's try_run
    # functionality so these values need to be set properly for the platform
    if (DEFINED CURL_CROSS_BUILD_OPTIONS)
        list(APPEND BUILD_OPTIONS ${CURL_CROSS_BUILD_OPTIONS})
    else ()
        message(FATAL_ERROR "CURL_CROSS_BUILD_OPTIONS needs to be set in the triplet file when cross compiling to communicate values determined by try_run")
    endif ()
endif ()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS 
        ${BUILD_OPTIONS}
        -DCURL_STATICLIB=${CURL_STATICLIB}
        -DCMAKE_USE_OPENSSL=${USE_OPENSSL}
        -DCMAKE_USE_WINSSL=${USE_WINSSL}
    OPTIONS_DEBUG
        -DENABLE_DEBUG=ON
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

# Prepare distribution
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/curl RENAME copyright)
file(WRITE ${CURRENT_PACKAGES_DIR}/share/curl/version ${CURL_VERSION})
