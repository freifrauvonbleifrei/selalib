SET(HDF5_ROOT $ENV{HDF5_ROOT} CACHE PATH "HDF5 location")

IF(NOT HDF5_FOUND AND HDF5_ENABLED)

   SET(HDF5_PATHS $ENV{HDF5_HOME}
                  ${HDF5_ROOT} 
                  $ENV{HDF5ROOT} 
                  /usr 
                  /usr/lib64/mpich2 
                  /usr/lib64/openmpi 
                  /usr/local 
                  /opt/local)

   FIND_PATH(HDF5_INCLUDE_DIR NAMES H5pubconf.h
   HINTS ${HDF5_PATHS} $ENV{HDF5_INCLUDEDIR} /usr/include/openmpi-x86_64 /usr/include/mpich2-x86_64 
   PATH_SUFFIXES / include hdf5/include 
   DOC "PATH to H5pubconf.h")

   FIND_PATH(HDF5_INCLUDE_DIR_FORTRAN NAMES hdf5.mod
   HINTS ${HDF5_PATHS} $ENV{HDF5_INCLUDEDIR} /usr/include/openmpi-x86_64 /usr/include/mpich2-x86_64 
   PATH_SUFFIXES / include hdf5/include include/fortran
   DOC "PATH to hdf5.mod")

   FIND_LIBRARY(HDF5_C_LIBRARY NAMES libhdf5.a hdf5
   HINTS ${HDF5_PATHS} $ENV{HDF5_LIBRARYDIR}
   PATH_SUFFIXES lib hdf5/lib lib/x86_64-linux-gnu
   DOC "PATH TO libhdf5")

   FIND_LIBRARY(HDF5_FORTRAN_LIBRARY NAMES libhdf5_fortran.a hdf5_fortran
   HINTS ${HDF5_PATHS} $ENV{HDF5_LIBRARYDIR}
   PATH_SUFFIXES lib hdf5/lib lib/x86_64-linux-gnu
   DOC "PATH TO libhdf5_fortran")

   FIND_LIBRARY(ZLIB_LIBRARIES NAMES z sz
                HINTS ${HDF5_PATHS} 
	          PATH_SUFFIXES lib hdf5/lib
	          DOC "PATH TO zip library")

   SET(HDF5_LIBRARIES ${HDF5_FORTRAN_LIBRARY} ${HDF5_C_LIBRARY} ${ZLIB_LIBRARIES})

   MESSAGE(STATUS "HDF5_INCLUDE_DIR:${HDF5_INCLUDE_DIR}")
   MESSAGE(STATUS "HDF5_INCLUDE_DIR_FORTRAN:${HDF5_INCLUDE_DIR_FORTRAN}")
   MESSAGE(STATUS "HDF5_LIBRARIES:${HDF5_LIBRARIES}")
   MESSAGE(STATUS "ZLIB_LIBRARIES:${ZLIB_LIBRARIES}")

   IF(DEFINED HDF5_FORTRAN_LIBRARY)
      SET(HDF5_FOUND YES)
   ENDIF()


ENDIF()


IF(HDF5_FOUND)

   MESSAGE(STATUS "HDF5 FOUND")

   SET( HDF5_IS_PARALLEL FALSE )

   MACRO(CHECK_HDF5_DEPS HDF5_HAVE_STRING HDF5_HAVE_BOOL)
      FILE( STRINGS "${HDF5_INCLUDE_DIR}/H5pubconf.h" 
            HDF5_HAVE_DEFINE REGEX ${HDF5_HAVE_STRING} )
      IF( HDF5_HAVE_DEFINE )
         SET( ${HDF5_HAVE_BOOL} TRUE )
      ELSE()
         SET( ${HDF5_HAVE_BOOL} FALSE )
      ENDIF()
   ENDMACRO(CHECK_HDF5_DEPS)
   
   IF( EXISTS "${HDF5_INCLUDE_DIR}/H5pubconf.h" )
      CHECK_HDF5_DEPS("HAVE_PARALLEL 1" HDF5_IS_PARALLEL)
      CHECK_HDF5_DEPS("HAVE_LIBPTHREAD 1" HDF5_HAVE_LIBPTHREAD)
      CHECK_HDF5_DEPS("HAVE_GPFS 1" HDF5_HAVE_GPFS)
      CHECK_HDF5_DEPS("HAVE_LIBDL 1" HDF5_HAVE_LIBDL)
      CHECK_HDF5_DEPS("HAVE_LIBSZ 1" HDF5_HAVE_LIBSZ)
   ENDIF()

   SET( HDF5_IS_PARALLEL ${HDF5_IS_PARALLEL} CACHE BOOL
       "HDF5 library compiled with parallel IO support" )
   MARK_AS_ADVANCED( HDF5_IS_PARALLEL )

   IF(HDF5_IS_PARALLEL) 
      MESSAGE(STATUS "HDF5 parallel supported")
      ADD_DEFINITIONS(-DHDF5_PARALLEL)
   ELSE(HDF5_IS_PARALLEL)
      MESSAGE(STATUS "HDF5 parallel not supported")
   ENDIF()

   SET( HDF5_HAVE_LIBPTHREAD ${HDF5_HAVE_LIBPTHREAD} CACHE BOOL
       "HDF5 library compiled with pthread library" )
   MARK_AS_ADVANCED( HDF5_HAVE_LIBPTHREAD )
   IF(HDF5_HAVE_LIBPTHREAD)
      FIND_LIBRARY(PTHREAD_LIBRARY NAMES pthread)
      SET(HDF5_LIBRARIES ${HDF5_LIBRARIES} ${PTHREAD_LIBRARY})
   ENDIF()

   SET( HDF5_HAVE_GPFS ${HDF5_HAVE_GPFS} CACHE BOOL
       "HDF5 library compiled with GPFS" )
   MARK_AS_ADVANCED( HDF5_HAVE_GPFS )
   IF(HDF5_HAVE_GPFS)
      FIND_LIBRARY(GPFS_LIBRARY NAMES gpfs)
      SET(HDF5_LIBRARIES ${HDF5_LIBRARIES} ${GPFS_LIBRARY})
   ENDIF()

   SET( HDF5_HAVE_LIBDL ${HDF5_HAVE_LIBDL} CACHE BOOL
       "HDF5 library compiled with LIBDL" )
   MARK_AS_ADVANCED( HDF5_HAVE_LIBDL )
   IF(HDF5_HAVE_LIBDL)
      FIND_LIBRARY(DL_LIBRARY NAMES dl)
      SET(HDF5_LIBRARIES ${HDF5_LIBRARIES} ${DL_LIBRARY})
   ENDIF()

   SET( HDF5_HAVE_LIBSZ ${HDF5_HAVE_LIBSZ} CACHE BOOL
       "HDF5 library compiled with LIBSZ" )
   MARK_AS_ADVANCED( HDF5_HAVE_LIBSZ )
   IF(HDF5_HAVE_LIBSZ)
      FIND_LIBRARY(SZ_LIBRARY NAMES sz)
      SET(HDF5_LIBRARIES ${HDF5_LIBRARIES} ${SZ_LIBRARY})
   ENDIF()

   INCLUDE_DIRECTORIES(${HDF5_INCLUDE_DIR})
   INCLUDE_DIRECTORIES(${HDF5_INCLUDE_DIR_FORTRAN})
   MESSAGE(STATUS "HDF5_LIBRARIES:${HDF5_LIBRARIES}")

ELSE()

   MESSAGE(STATUS "Build SeLaLib without HDF5... binary output only for serial applications ")
   ADD_DEFINITIONS(-DNOHDF5)
   SET(HDF5_ENABLED OFF CACHE BOOL " " FORCE)
   SET(HDF5_LIBRARIES "")

ENDIF()


IF(HDF5_ENABLED AND HDF5_IS_PARALLEL)
   IF(MPI_ENABLED)
   ELSE()
      MESSAGE(STATUS "HD5 is PARALLEL and needs MPI, please set MPI_ENABLED")
      MESSAGE(STATUS "HD5 is set to OFF")
      SET(HDF5_ENABLED OFF CACHE BOOL " " FORCE)
      ADD_DEFINITIONS(-DNOHDF5)
   ENDIF(MPI_ENABLED)
ENDIF(HDF5_ENABLED AND HDF5_IS_PARALLEL)
