cmake_minimum_required(VERSION 3.8)

project(quest CXX)

file(GLOB_RECURSE sources
  src/*.cc src/*.h
  src/*.c
)

# Add the src directory to the include path
include_directories(src)

# Add liblua include directory if provided (for independent builds)
if(liblua_INCLUDE_DIR)
    include_directories(${liblua_INCLUDE_DIR})
endif()

add_executable(${PROJECT_NAME} ${sources})
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "qc")

# Find and link dependencies

# liblua
# Try to find liblua as a target first (when built as part of main project)
if(TARGET liblua)
    target_link_libraries(${PROJECT_NAME} liblua)
else()
    # When building independently, use provided paths
    if(liblua_INCLUDE_DIR)
        target_include_directories(${PROJECT_NAME} PRIVATE ${liblua_INCLUDE_DIR})
    endif()
    if(liblua_LIBRARY)
        target_link_libraries(${PROJECT_NAME} ${liblua_LIBRARY})
    else()
        # Fallback: try to find liblua library
        find_library(LIBLUA_LIB 
            NAMES liblua libliblua
            PATHS "${CMAKE_CURRENT_SOURCE_DIR}/../../lib" "/app/lib"
            NO_DEFAULT_PATH
        )
        if(LIBLUA_LIB)
            target_link_libraries(${PROJECT_NAME} ${LIBLUA_LIB})
        else()
            message(FATAL_ERROR "Could not find liblua library. Please provide liblua_LIBRARY")
        endif()
    endif()
endif()
