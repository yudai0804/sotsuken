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
x = np.sin(2 * t) * np.exp(-t / tau)
plt.figure()

plt.plot(t, x, linewidth=3)

plt.xticks([])
plt.yticks([])

plt.hlines(
    0,
    xmin=t[0],
    xmax=t[-1],
    color="black",
    linewidth=1,
)

# 外枠を消す
plt.gca().spines["right"].set_visible(False)
plt.gca().spines["top"].set_visible(False)
plt.gca().spines["bottom"].set_visible(False)
plt.gca().spines["left"].set_visible(False)

plt.tight_layout()

# plt.show()

os.makedirs("assets", exist_ok=True)
plt.savefig("assets/mbc-bpsk.png", dpi=300)
os.chdir(start_dir)
