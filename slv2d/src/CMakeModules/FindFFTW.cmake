# FFTW_INCLUDE_DIR = fftw3.f03
# FFTW_LIBRARIES = libfftw3.a
# FFTW_FOUND = true if FFTW3 is found

SET(TRIAL_PATHS
 $ENV{FFTW_HOME}/include
 /usr/include
 /usr/local/include
 /opt/include
 /usr/apps/include
 )

 SET(TRIAL_LIBRARY_PATHS
 $ENV{FFTW_HOME}/lib
 /usr/lib
 /usr/local/lib
 /opt/lib
 /sw/lib
 )

FIND_PATH(FFTW_INCLUDE_DIR fftw3.f03 ${TRIAL_PATHS})
FIND_LIBRARY(FFTW_LIBRARY fftw3 ${TRIAL_LIBRARY_PATHS})
FIND_LIBRARY(FFTW_THREADS_LIBRARY fftw3_threads ${TRIAL_LIBRARY_PATHS})
SET(FFTW_LIBRARIES ${FFTW_LIBRARY} ${FFTW_THREADS_LIBRARY})

SET(FFTW_FOUND FALSE)
IF(FFTW_INCLUDE_DIR AND FFTW_LIBRARIES)
MESSAGE(STATUS "FFTW_INCLUDE_DIRS=${FFTW_INCLUDE_DIR}")
MESSAGE(STATUS "FFTW_LIBRARIES=${FFTW_LIBRARIES}")
SET(FFTW_FOUND TRUE)
ENDIF()

MARK_AS_ADVANCED(
FFTW_INCLUDE_DIR
FFTW_LIBRARIES
FFTW_FOUND
)
