IF(Fortran_COMPILER STREQUAL 'INTEL')
  SET(BLA_VENDOR "Intel")
ENDIF()

IF (APPLE)

   FIND_LIBRARY(LAPACK_LIBRARIES  lapack)
   FIND_LIBRARY(BLAS_LIBRARIES    blas)

ELSEIF($ENV{HOST} STREQUAL "hydra01")

   SET(LAPACK_LIBRARIES -L/u/system/SLES11/soft/intel/12.1/mkl/lib/intel64 -lmkl_lapack95_lp64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core)
   SET(LAPACK_FOUND TRUE)
   SET(BLAS_FOUND TRUE)

ELSEIF($ENV{HOST} STREQUAL "hpc")

   SET(MKLPATH  "/opt/intel/Compiler/11.1/072/mkl/lib/em64t")
   SET(LAPACK_LIBRARIES -L${MKLPATH} -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -openmp -lpthread)
   SET(LAPACK_FOUND TRUE)
   SET(BLAS_FOUND TRUE)

ELSEIF($ENV{MKLROOT} MATCHES "composer")

   INCLUDE_DIRECTORIES($ENV{MKLROOT}/include)
   IF(${CMAKE_SYSTEM_PROCESSOR} MATCHES "x86_64")
      SET(LAPACK_LIBRARIES -L$ENV{MKLROOT}/lib/intel64 -mkl=sequential)
   ELSE()
      SET(LAPACK_LIBRARIES -L$ENV{MKLROOT}/lib/ia32 -mkl=sequential)
   ENDIF()
   SET(LAPACK_FOUND TRUE)
   SET(BLAS_FOUND TRUE)

ELSE()

   FIND_PACKAGE(LAPACK REQUIRED)
   FIND_PACKAGE(BLAS   REQUIRED)

ENDIF()

IF(LAPACK_FOUND AND BLAS_FOUND)

  MESSAGE(STATUS "LAPACK and BLAS libraries are ${LAPACK_LIBRARIES}")

ELSE(LAPACK_FOUND AND BLAS_FOUND)

  MESSAGE(STATUS "Failed to link LAPACK, BLAS, ATLAS libraries with environments. Going to search standard paths.")
  FIND_LIBRARY(LAPACK_LIBRARIES lapack)
  FIND_LIBRARY(BLAS_LIBRARIES blas)

  IF(LAPACK_LIBRARIES AND BLAS_LIBRARIES)

    MESSAGE(STATUS "LAPACK_LIBRARIES=${LAPACK_LIBRARIES}")
    MESSAGE(STATUS "BLAS_LIBRARIES=${BLAS_LIBRARIES}")
    SET(LAPACK_FOUND TRUE)
    SET(BLAS_FOUND TRUE)

  ENDIF(LAPACK_LIBRARIES AND BLAS_LIBRARIES)

ENDIF(LAPACK_FOUND AND BLAS_FOUND)

SET(LINK_LIBRARIES ${LAPACK_LIBRARIES} ${BLAS_LIBRARIES})
