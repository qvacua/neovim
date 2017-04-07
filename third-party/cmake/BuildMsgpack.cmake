include(CMakeParseArguments)

# BuildMsgpack(CONFIGURE_COMMAND ... BUILD_COMMAND ... INSTALL_COMMAND ...)
# Reusable function to build msgpack, wraps ExternalProject_Add.
# Failing to pass a command argument will result in no command being run
function(BuildMsgpack)
  cmake_parse_arguments(_msgpack
    ""
    ""
    "CONFIGURE_COMMAND;BUILD_COMMAND;INSTALL_COMMAND"
    ${ARGN})

  if(NOT _msgpack_CONFIGURE_COMMAND AND NOT _msgpack_BUILD_COMMAND
       AND NOT _msgpack_INSTALL_COMMAND)
    message(FATAL_ERROR "Must pass at least one of CONFIGURE_COMMAND, BUILD_COMMAND, INSTALL_COMMAND")
  endif()

  ExternalProject_Add(msgpack
    PREFIX ${DEPS_BUILD_DIR}
    URL ${MSGPACK_URL}
    DOWNLOAD_DIR ${DEPS_DOWNLOAD_DIR}/msgpack
    DOWNLOAD_COMMAND ${CMAKE_COMMAND}
      -DPREFIX=${DEPS_BUILD_DIR}
      -DDOWNLOAD_DIR=${DEPS_DOWNLOAD_DIR}/msgpack
      -DURL=${MSGPACK_URL}
      -DEXPECTED_SHA256=${MSGPACK_SHA256}
      -DTARGET=msgpack
      -DUSE_EXISTING_SRC_DIR=${USE_EXISTING_SRC_DIR}
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/DownloadAndExtractFile.cmake
    CONFIGURE_COMMAND "${_msgpack_CONFIGURE_COMMAND}"
    BUILD_COMMAND "${_msgpack_BUILD_COMMAND}"
    INSTALL_COMMAND "${_msgpack_INSTALL_COMMAND}")
endfunction()

set(MSGPACK_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/msgpack
  -DMSGPACK_ENABLE_CXX=OFF
  -DMSGPACK_BUILD_TESTS=OFF
  -DMSGPACK_BUILD_EXAMPLES=OFF
  -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
  -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
  "-DCMAKE_C_FLAGS:STRING=${CMAKE_C_COMPILER_ARG1} -fPIC"
  -DCMAKE_GENERATOR=${CMAKE_GENERATOR})

set(MSGPACK_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${CMAKE_BUILD_TYPE})
set(MSGPACK_INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install --config ${CMAKE_BUILD_TYPE})

if(MINGW AND CMAKE_CROSSCOMPILING)
  get_filename_component(TOOLCHAIN ${CMAKE_TOOLCHAIN_FILE} REALPATH)
  set(MSGPACK_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/msgpack
    -DMSGPACK_ENABLE_CXX=OFF
    -DMSGPACK_BUILD_TESTS=OFF
    -DMSGPACK_BUILD_EXAMPLES=OFF
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
    # Pass toolchain
    -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Hack to avoid -rdynamic in Mingw
    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="")
elseif(MSVC)
  # Same as Unix without fPIC
  set(MSGPACK_CONFIGURE_COMMAND ${CMAKE_COMMAND} ${DEPS_BUILD_DIR}/src/msgpack
    -DMSGPACK_ENABLE_CXX=OFF
    -DMSGPACK_BUILD_TESTS=OFF
    -DMSGPACK_BUILD_EXAMPLES=OFF
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_DIR}
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    "-DCMAKE_C_FLAGS:STRING=${CMAKE_C_COMPILER_ARG1}"
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    # Make sure we use the same generator, otherwise we may
    # accidentaly end up using different MSVC runtimes
    -DCMAKE_GENERATOR=${CMAKE_GENERATOR})
  # Place the DLL in the bin folder
  set(MSGPACK_INSTALL_COMMAND ${MSGPACK_INSTALL_COMMAND}
    COMMAND ${CMAKE_COMMAND} -E copy ${DEPS_INSTALL_DIR}/lib/msgpack.dll ${DEPS_INSTALL_DIR}/bin)
endif()

BuildMsgpack(CONFIGURE_COMMAND ${MSGPACK_CONFIGURE_COMMAND}
  BUILD_COMMAND ${MSGPACK_BUILD_COMMAND}
  INSTALL_COMMAND ${MSGPACK_INSTALL_COMMAND})

list(APPEND THIRD_PARTY_DEPS msgpack)
