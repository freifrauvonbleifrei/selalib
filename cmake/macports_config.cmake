SET(CMAKE_Fortran_COMPILER   "/opt/local/bin/gfortran-mp-4.8"  CACHE FILEPATH " " FORCE)
SET(FFTW_LIBRARY             "/opt/local/lib/libfftw3.a"       CACHE FILEPATH " " FORCE)
#SET(CMAKE_BUILD_TYPE         Release                           CACHE STRING   " " FORCE)
SET(CMAKE_CXX_COMPILER       "/opt/local/bin/g++-mp-4.8"       CACHE FILEPATH " " FORCE)
SET(CMAKE_C_COMPILER         "/opt/local/bin/gcc-mp-4.8"       CACHE FILEPATH " " FORCE)
SET(FFTW_ROOT                "/opt/local"                      CACHE PATH     " " FORCE)
SET(HDF5_PARALLEL_ENABLED    ON                                CACHE BOOL     " " FORCE)
SET(HDF5_ROOT                "/opt/local"                      CACHE PATH     " " FORCE)
SET(MPIEXEC                  "/opt/local/bin/mpirun"       CACHE FILEPATH " " FORCE)
SET(MPI_C_COMPILER           "/opt/local/bin/mpicc"        CACHE FILEPATH " " FORCE)
SET(MPI_C_INCLUDE_PATH       "/opt/local/include"              CACHE PATH     " " FORCE)
SET(MPI_CXX_COMPILER         "/opt/local/bin/mpicxx"       CACHE FILEPATH " " FORCE)
SET(MPI_CXX_INCLUDE_PATH     "/opt/local/include"              CACHE PATH     " " FORCE)
SET(MPI_Fortran_COMPILER     "/opt/local/bin/mpif90"       CACHE FILEPATH " " FORCE)
SET(MPI_Fortran_INCLUDE_PATH "/opt/local/lib"                  CACHE PATH     " " FORCE)
SET(MPI_C_LIBRARIES          "/opt/local/lib/libmpi.dylib"     CACHE FILEPATH " " FORCE)
SET(MPI_CXX_LIBRARIES        "/opt/local/lib/libmpi_cxx.dylib" CACHE FILEPATH " " FORCE)
SET(MPI_Fortran_LIBRARIES    "/opt/local/lib/libmpi_f90.dylib" CACHE FILEPATH " " FORCE)
SET(SUITESPARSE_ROOT         "/opt/local"                      CACHE PATH     " " FORCE)
