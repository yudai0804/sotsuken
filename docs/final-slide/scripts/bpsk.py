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
t = np.linspace(0, 8 * np.pi, N)
x = np.sin(t)
# 2つ目のシンボルだけ位相をπずらす
for i in range(N // 4, N // 4 + N // 8):
    x[i], x[i + N // 8] = x[i + N // 8], x[i]
plt.figure()

plt.plot(t, x, linewidth=3)

plt.xticks([])
plt.yticks([])

# 外枠を消す
plt.gca().spines["right"].set_visible(False)
plt.gca().spines["top"].set_visible(False)
plt.gca().spines["bottom"].set_visible(False)
plt.gca().spines["left"].set_visible(False)

vt = [t[0], t[2500], t[5000], t[7500], t[9999]]

plt.vlines(
    vt,
    ymin=-1,
    ymax=1,
    color="black",
    linewidth=1,
)

plt.tight_layout()

# plt.show()

os.makedirs("assets", exist_ok=True)
plt.savefig("assets/bpsk.png", dpi=300)
os.chdir(start_dir)
