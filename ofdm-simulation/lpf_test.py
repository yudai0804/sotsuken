# 一次のローパスフィルタのシミュレーション

import numpy as np
import numpy.testing as npt
from numpy.typing import NDArray
from typing import Any, List, Tuple
import scipy.signal
import scipy.interpolate
import matplotlib.pyplot as plt
import cmath
import bisect
import math
import sys
import random

import signal

signal.signal(signal.SIGINT, signal.SIG_DFL)

"""
|G(jω)| = 1/sqrt(1+(ωCR)^2)
        = 1/sqrt(1+(2πfCR)^2)
        = 1/sqrt(1+(f/fc)^2)
fc≡1/(2πCR)
"""

f_cutoff: float = 10000
f_end: float = 100000
f: NDArray[np.float64] = np.arange(int(f_end), dtype=np.float64)
X: NDArray[np.float64] = 1 / (1 + (f / f_cutoff) ** 2) ** 0.5
plt.figure()
plt.plot(f, X)
plt.axvline(6000, color="black", lw=0.5, ls="--")
plt.axvline(f_cutoff, color="black", lw=0.5, ls="--")
plt.axvline(12800 * 2, color="black", lw=0.5, ls="--")
plt.show()
