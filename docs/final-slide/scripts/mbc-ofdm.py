import bisect
import os
import signal
from typing import Any, List, Tuple

import matplotlib.pyplot as plt
import matplotlib_fontja
import numpy as np
from numpy.typing import NDArray

signal.signal(signal.SIGINT, signal.SIG_DFL)

start_dir = os.getcwd()
# このファイルがあるディレクトリまで移動
os.chdir(os.path.dirname(os.path.abspath(__file__)))
# 1つ上のディレクトリに移動
os.chdir("..")

N: int = 10000
tau: float = 2 * np.pi
t = np.linspace(0, 6 * np.pi, N)
x1 = np.sin(t) * np.exp(-t / tau)
x2 = np.sin(2 * t) * np.exp(-t / tau)
x3 = np.sin(3 * t) * np.exp(-t / tau)

fig, (ax1, ax2, ax3) = plt.subplots(3, 1)
ax1.plot(t, x1)
ax1.set_xticks([])
ax1.set_yticks([])
ax1.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=1,
)
ax1.spines["right"].set_visible(False)
ax1.spines["top"].set_visible(False)
ax1.spines["bottom"].set_visible(False)
ax1.spines["left"].set_visible(False)
ax2.plot(t, x2)
ax2.set_xticks([])
ax2.set_yticks([])
ax2.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=1,
)
ax2.spines["right"].set_visible(False)
ax2.spines["top"].set_visible(False)
ax2.spines["bottom"].set_visible(False)
ax2.spines["left"].set_visible(False)
ax3.plot(t, x3)
ax3.set_xticks([])
ax3.set_yticks([])
ax3.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=1,
)
ax3.spines["right"].set_visible(False)
ax3.spines["top"].set_visible(False)
ax3.spines["bottom"].set_visible(False)
ax3.spines["left"].set_visible(False)

plt.tight_layout()

# plt.show()

os.makedirs("assets", exist_ok=True)
plt.savefig("assets/mbc-ofdm.png", dpi=300)
os.chdir(start_dir)
