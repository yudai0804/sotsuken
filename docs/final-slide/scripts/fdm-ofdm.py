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

xs = 0
xe = 7 * np.pi
x = np.linspace(xs, xe, 1000)
y_fig1 = np.sin(x)
for i in range(len(y_fig1)):
    if y_fig1[i] < 0:
        y_fig1[i] = 0
y_fig2_sin = np.abs(np.sin(2 * x))
y_fig2_cos = np.abs(np.cos(2 * x))

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))
xticks = []
for i in range(4):
    xticks.append((0.5 + 2 * i) * np.pi)
ax1.set_xticks([])
ax1.vlines(
    xticks,
    ymin=0,
    ymax=1,
    color="black",
    linewidth=3,
    linestyle=":",
)
ax1.plot(x, y_fig1, color="red", linewidth=3)
ax1.set_yticks([])
ax1.grid(False)

ax2.grid(False)

xticks = []
for i in range(4):
    xticks.append((0.5 + 2 * i) * np.pi)
ax2.vlines(
    xticks,
    ymin=0,
    ymax=1,
    color="black",
    linewidth=3,
    linestyle=":",
)
ax2.plot(x, y_fig2_cos, color="blue", linewidth=3)
ax2.plot(x, y_fig2_sin, color="red", linewidth=3)
ax2.set_xticks([])
ax2.set_yticks([])

plt.tight_layout()
# plt.show()
os.makedirs("assets", exist_ok=True)
plt.savefig("assets/fdm-ofdm.png", dpi=300)
os.chdir(start_dir)
