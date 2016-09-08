from __future__ import print_function

import numpy as np
import matplotlib.pyplot as plt
from collections import OrderedDict
from zealpy_BOT  import zealpy_BOT

#===============================================================================
# INPUT PARAMETERS
#===============================================================================

kmode_list = [0.1, 0.2, 0.3, 0.4, 0.5]

xmin = -2.
xmax = 2.
ymin = 0.0001
ymax = 1.

#===============================================================================
# EXECUTION (with terminal output)
#===============================================================================

zeros_dict = OrderedDict()

for kmode in kmode_list:
    zp = zealpy_BOT(
        kmode  = kmode,
        a_bump = 0.4,
        v0     = 2.0,
        sigmab = 0.1,
        kbT    = 1.0,
        l0ld   = 18.0)
    zp.get_zeros( xmin, xmax, ymin, ymax )
    zeros_dict[kmode] = np.array( zp.zeros )

    print( 'mode:', kmode )
    print( 'zero with largest imaginary part:', \
        zp.zeros[np.argmax(np.imag(zp.zeros))] )

#===============================================================================
# PLOTS
#===============================================================================

fig = plt.figure()
ax = fig.add_subplot( 1,1,1 )

for kmode, zeros in zeros_dict.items():
    ax.plot( zeros.real, zeros.imag, '.', label='k={}'.format( kmode ) )

ax.axis( [-1.,1.,-1.,1.] )
ax.set_title( 'Zeros of dispersion relation' )
ax.set_xlabel( r'Re($\omega$)', size=14 )
ax.set_ylabel( r'Im($\omega$)', size=14, rotation='horizontal' )
ax.grid()
ax.legend()
fig.show()

msg = '\nPress ENTER to quit'
try:
    raw_input( msg )
except NameError:
    input( msg )
plt.close('all')
