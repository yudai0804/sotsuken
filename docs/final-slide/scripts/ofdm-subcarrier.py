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
t = np.linspace(0, 2 * np.pi, N)
x0 = np.cos(0 * t)
x1 = np.cos(t + np.pi)
x2 = np.cos(2 * t)
x3 = np.cos(3 * t)
x4 = np.cos(4 * t + np.pi)
x5 = np.cos(5 * t)
x6 = np.cos(6 * t)
x7 = np.cos(7 * t + np.pi)
ofdm = x0 + x1 + x2 + x3 + x4 + x5 + x6 + x7

fig, (ax0, ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8) = plt.subplots(9, 1)

width = 2.0
ax_width = 1.0

ax0.set_xticks([])
ax0.set_yticks([])
ax0.spines["right"].set_visible(False)
ax0.spines["top"].set_visible(False)
ax0.spines["bottom"].set_visible(False)
ax0.spines["left"].set_visible(False)
ax0.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax0.plot(t, x0, linewidth=width)


ax1.set_xticks([])
ax1.set_yticks([])
ax1.spines["right"].set_visible(False)
ax1.spines["top"].set_visible(False)
ax1.spines["bottom"].set_visible(False)
ax1.spines["left"].set_visible(False)
ax1.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax1.plot(t, x1, linewidth=width)

ax2.set_xticks([])
ax2.set_yticks([])
ax2.spines["right"].set_visible(False)
ax2.spines["top"].set_visible(False)
ax2.spines["bottom"].set_visible(False)
ax2.spines["left"].set_visible(False)
ax2.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax2.plot(t, x2, linewidth=width)

ax3.set_xticks([])
ax3.set_yticks([])
ax3.spines["right"].set_visible(False)
ax3.spines["top"].set_visible(False)
ax3.spines["bottom"].set_visible(False)
ax3.spines["left"].set_visible(False)
ax3.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax3.plot(t, x3, linewidth=width)

ax4.set_xticks([])
ax4.set_yticks([])
ax4.spines["right"].set_visible(False)
ax4.spines["top"].set_visible(False)
ax4.spines["bottom"].set_visible(False)
ax4.spines["left"].set_visible(False)
ax4.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax4.plot(t, x4, linewidth=width)

ax5.set_xticks([])
ax5.set_yticks([])
ax5.spines["right"].set_visible(False)
ax5.spines["top"].set_visible(False)
ax5.spines["bottom"].set_visible(False)
ax5.spines["left"].set_visible(False)
ax5.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax5.plot(t, x5, linewidth=width)

ax6.set_xticks([])
ax6.set_yticks([])
ax6.spines["right"].set_visible(False)
ax6.spines["top"].set_visible(False)
ax6.spines["bottom"].set_visible(False)
ax6.spines["left"].set_visible(False)
ax6.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax6.plot(t, x6, linewidth=width)

ax7.set_xticks([])
ax7.set_yticks([])
ax7.spines["right"].set_visible(False)
ax7.spines["top"].set_visible(False)
ax7.spines["bottom"].set_visible(False)
ax7.spines["left"].set_visible(False)
ax7.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax7.plot(t, x7, linewidth=width)

ax8.set_xticks([])
ax8.set_yticks([])
ax8.spines["right"].set_visible(False)
ax8.spines["top"].set_visible(False)
ax8.spines["bottom"].set_visible(False)
ax8.spines["left"].set_visible(False)
ax8.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=ax_width,
)
ax8.plot(t, ofdm, linewidth=width)

plt.tight_layout()

# plt.show()

os.makedirs("assets", exist_ok=True)
plt.savefig("assets/ofdm-subcarrier.png", dpi=300)
os.chdir(start_dir)
