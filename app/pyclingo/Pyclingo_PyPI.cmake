## Copy sources of libraries in the current folder to prepare setuptools source package
# Why do we need to copy all sources here before the packaging ?
# Setuptools doesn't know about the out of source build. In order to fix this,
# all Python and C sources have to be copied in the python source tree into the CMAKE_CURRENT_BINARY_DIR.

# libpotassco
file(COPY "${PROJECT_SOURCE_DIR}/clasp/libpotassco/potassco" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/libpotassco/"
    FILES_MATCHING PATTERN *.h*)
file(COPY "${PROJECT_SOURCE_DIR}/clasp/libpotassco/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/libpotassco/")

# libreify
file(COPY "${PROJECT_SOURCE_DIR}/libreify/reify" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libreify/"
    FILES_MATCHING PATTERN *.h*)
file(COPY "${PROJECT_SOURCE_DIR}/libreify/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libreify/")

# libgringo
file(COPY "${PROJECT_SOURCE_DIR}/libgringo/gringo" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libgringo/"
    FILES_MATCHING PATTERN *.h*)
file(COPY "${PROJECT_SOURCE_DIR}/libgringo/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libgringo/")
# Don't forget pre-generated files in libgringo/gen:
# src/input/groundtermgrammar/*
# src/input/nongroundgrammar/*
# 3 headers in src/input
file(COPY "${PROJECT_SOURCE_DIR}/libgringo/gen/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libgringo/"
    FILES_MATCHING PATTERN "*.*")

# clasp
# Headers and .inl files
file(COPY "${PROJECT_SOURCE_DIR}/clasp/clasp" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/")
file(COPY "${PROJECT_SOURCE_DIR}/clasp/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/")
# Copy clasp/clasp/config.h generated with cmake
file(COPY "${PROJECT_BINARY_DIR}/clasp/clasp" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/")

# libclingo
file(COPY "${PROJECT_SOURCE_DIR}/libclingo/src" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libclingo/")
# Don't forget headers in libclingo/
file(COPY "${PROJECT_SOURCE_DIR}/libclingo/" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libclingo/"
    FILES_MATCHING PATTERN *.h*
)
file(COPY "${PROJECT_SOURCE_DIR}/clasp/app/clasp_app.cpp" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/app/")
file(COPY "${PROJECT_SOURCE_DIR}/clasp/app/clasp_app.h" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/clasp/app/")

# libpyclingo
file(COPY "${PROJECT_SOURCE_DIR}/libpyclingo/"
    DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/libpyclingo/"
    FILES_MATCHING PATTERN *.cc PATTERN *.h
)

# pyclingo itself
file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/main.cc" DESTINATION ${CMAKE_CURRENT_BINARY_DIR})


## Get all sources files and format them into a string that will be inserted in the setup.py
file(GLOB_RECURSE LIB_SOURCES
    "${CMAKE_CURRENT_BINARY_DIR}/*.cpp" "${CMAKE_CURRENT_BINARY_DIR}/*.cc"
)
# Remove the current path (not needed for setup.py) for each file
set(PYTHON_STRIPPED_SOURCES)
foreach(file ${LIB_SOURCES})
    string(REPLACE "${CMAKE_CURRENT_BINARY_DIR}/" "" file ${file})
    set(PYTHON_STRIPPED_SOURCES "${PYTHON_STRIPPED_SOURCES}\"${file}\", ")
endforeach()

# Configure setup.py with project version and sources
set(SETUP_PY_IN "${CMAKE_CURRENT_SOURCE_DIR}/setup.py.in")
set(SETUP_PY    "${CMAKE_CURRENT_BINARY_DIR}/setup.py")
configure_file(${SETUP_PY_IN} ${SETUP_PY})

# Copy additional files that will be integrated in the source package
file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/MANIFEST.in" DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
file(COPY "${PROJECT_SOURCE_DIR}/README.md" DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
file(COPY "${PROJECT_SOURCE_DIR}/LICENSE.md" DESTINATION ${CMAKE_CURRENT_BINARY_DIR})


## Pyclingo targets

# Build
# timestamp: the output from python setup.py build is not a good candidate to detect
# if build has to run, because it is placed in architecture- and platform-specific
# directories like lib.linux-x86_64-2.6.
# A timestamp file is generated each time the source dependencies changes.
set(OUTPUT      "${CMAKE_CURRENT_BINARY_DIR}/build")
add_custom_command(OUTPUT ${OUTPUT}/timestamp
                   COMMAND ${PYTHON_EXECUTABLE}
                   ARGS ${SETUP_PY} build
                   COMMAND ${CMAKE_COMMAND} -E touch ${OUTPUT}/timestamp
)
add_custom_target(pyclingo_pypi ALL DEPENDS ${OUTPUT}/timestamp COMMENT "Building pyclingo for pypi...")
# Install in dev mode
# This makes symlinks from the actual Python environment to the current module
# and allows to modify files without to reinstall it.
# Moreover, this install/uninstall method is much proper than the old and deprecated one:
# "python setup.py install"
add_custom_target(pyclingo_pypi_dev_install
                  COMMAND ${PYTHON_EXECUTABLE} ${SETUP_PY} develop
                  COMMENT "Install pyclingo for pypi in develop mode...")
# Uninstall in dev mode
add_custom_target(pyclingo_pypi_dev_uninstall
                  COMMAND ${PYTHON_EXECUTABLE} ${SETUP_PY} develop --uninstall
                  COMMENT "Uninstall pyclingo for pypi previously installed in develop mode...")
# Make a source package
add_custom_target(pyclingo_pypi_dist_package
                  COMMAND ${PYTHON_EXECUTABLE} ${SETUP_PY} sdist
                  COMMENT "Build pyclingo for pypi source package...")
# Make a binary package
add_custom_target(pyclingo_pypi_bdist_wheel_package
                  COMMAND ${PYTHON_EXECUTABLE} ${SETUP_PY} bdist_wheel
                  COMMENT "Build pyclingo for pypi binary package...")
# Proper uninstall if package was installed with a basic "make install"
add_custom_target(pyclingo_pypi_uninstall
                  COMMAND cat files.txt | xargs rm -rf && rm files.txt
                  COMMENT "Uninstall pyclingo for pypi...")
# Install with cmake
install(CODE "execute_process(COMMAND ${PYTHON_EXECUTABLE} ${SETUP_PY} install --record files.txt)")