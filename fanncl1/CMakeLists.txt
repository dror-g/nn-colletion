ADD_SUBDIRECTORY( include ) 
cmake_minimum_required(VERSION 2.8)
INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/src/include)
ADD_DEFINITIONS(-D_REENTRANT)
if (WIN32)
ADD_DEFINITIONS(-DFANN_DLL_EXPORTS)
endif (WIN32)
##############-Set Compiler-##########
SET(CMAKE_C_COMPILER clang)

########### next target ###############

SET(floatfann_LIB_SRCS
	floatfann.c simpleCL.c
)

ADD_LIBRARY(floatfann SHARED ${floatfann_LIB_SRCS})

SET_TARGET_PROPERTIES(floatfann PROPERTIES VERSION ${VERSION} SOVERSION 2 )
INSTALL(TARGETS floatfann DESTINATION ${LIB_INSTALL_DIR} )


########### next target ###############

#SET(doublefann_LIB_SRCS
#	doublefann.c simpleCL.c
#)

#ADD_LIBRARY(doublefann SHARED ${doublefann_LIB_SRCS})

#SET_TARGET_PROPERTIES(doublefann PROPERTIES VERSION ${VERSION} SOVERSION 2 )
#INSTALL(TARGETS doublefann DESTINATION ${LIB_INSTALL_DIR} )
SET(SAFEFLAGS "-fstack-protector --param=ssp-buffer-size=1 -fPIE -Wformat -Wformat-security -Werror=format-security -pipe")# -fmudflap")# -msafe-dma")
#AMD
SET(CMAKE_C_FLAGS "-I/home/inferno/Soft/fann/src/include -I/opt/AMDAPP/include -pthreads -L/usr/lib/ -L/usr/lib/x86_64-linux-gnu/ -march=native -O2 -std=c99 -pipe -lOpenCL -ggdb ${SAFEFLAGS}")
SET(CMAKE_LINK_FLAGS "-L/usr/lib/ -L/usr/lib/x86_64-linux-gnu/ -pie -lOpenCL -O1")

#FREEOCL
#SET(CMAKE_C_FLAGS "-I/home/inferno/Soft/fann/src/include -I/opt/AMDAPP/include -L/usr/local/freeocl/lib -march=native -mtune=generic -O1 -msse -msse2 -msse3 -mssse3 -std=c99 -fPIC -lnsl -lutil -lm -ldl -lrt -lOpenCL -Wl,--export-dynamic -g")
#SET(CMAKE_LINK_FLAGS "-L/usr/local/freeocl/lib -L/usr/lib/llvm-3.0/lib/ -fPIC -lnsl -lutil -lm -ldl -lrt -lOpenCL -Wl,--export-dynamic -std=c99 -g")

#NVIDIA
#SET(CMAKE_C_FLAGS "-I/home/inferno/Soft/fann/src/include -I/opt/AMDAPP/include -march=native -mtune=generic -Os -msse -msse2 -msse3 -mssse3 -fPIC -g")
#SET(CMAKE_LINK_FLAGS "-L/usr/lib/nvidia-current/ -L/usr/lib/llvm-2.9/lib/  -fPIC -lnsl -lutil -lm -ldl -lrt -Wl,--export-dynamic -lOpenCL -S")
########### next target ###############

#POCL
#SET(CMAKE_C_FLAGS "-I/home/inferno/Soft/fann/src/include -L/usr/local/lib/ -I/usr/local/include -march=native -mtune=generic -std=c99 -O3 -msse -msse2 -msse3 -mssse3 -fPIC -g")
#SET(CMAKE_LINK_FLAGS "-L/usr/local/lib/ -L/usr/lib/llvm-3.2/lib/  -fPIC -lnsl -lutil -lm -ldl -lrt -Wl,--export-dynamic -lOpenCL -g")

#SnuCL
#SET(CMAKE_C_FLAGS "-I/home/inferno/Soft/fann/src/include -I/home/inferno/Soft/opencl/snucl/inc -L/home/inferno/Soft/opencl/snucl/lib/ -march=native -mtune=generic -O1 -msse -msse2 -msse3 -mssse3 -std=c99 -fPIC -lnsl -lutil -lm -ldl -lrt -lsnucl -Wl,--export-dynamic -g")
#SET(CMAKE_LINK_FLAGS "-L/home/inferno/Soft/opencl/snucl/lib/ -L/usr/lib/llvm-3.0/lib/ -fPIC -lnsl -lutil -lm -ldl -lrt -lsnucl -Wl,--export-dynamic -std=c99 -g")

SET(fann_LIB_SRCS
	floatfann.c simpleCL.c
)
find_library(TSAN_LIB tsan)
find_library(M_LIB m)
find_library(CL_LIB OpenCL)
ADD_LIBRARY(fann SHARED ${fann_LIB_SRCS})
TARGET_LINK_LIBRARIES(fann ${M_LIB} ${CL_LIB})
SET_TARGET_PROPERTIES(fann PROPERTIES VERSION ${VERSION} SOVERSION 2 )
INSTALL(TARGETS fann DESTINATION ${LIB_INSTALL_DIR} )

