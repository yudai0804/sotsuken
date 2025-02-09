# OFDMに使用する有限長cosのフーリエ変換はTsinc(ω+ω0)+Tsinc(ω-ω0)となる

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
low = -2
high = 9
SUBCARRIER_NUMBER: int = 8
f = np.linspace(low, high, N)
X = np.zeros((SUBCARRIER_NUMBER, N))
for i in range(SUBCARRIER_NUMBER):
    X[i] = abs(np.sinc(f - i))
plt.figure()

tick_labels = [f"f{i}" for i in range(SUBCARRIER_NUMBER)]
plt.xticks(np.arange(SUBCARRIER_NUMBER), tick_labels)
plt.yticks([0.0, 0.5, 1.0])
# メモリの向きを内側にする。plt.plotの前に呼び出す必要あり。
plt.rcParams["xtick.direction"] = "in"
plt.rcParams["ytick.direction"] = "in"
plt.tick_params(width=1, length=10, labelsize=22)

plt.vlines(
    np.arange(SUBCARRIER_NUMBER),
    ymin=0,
    ymax=1.1,
    color="black",
    linestyle=":",
    linewidth=2.5,
)

for i in range(SUBCARRIER_NUMBER):
    # 左から見ていったときに左側のグラフが先で重ならないようにする。そっちのほうが見やすいので。
    plt.plot(f, X[SUBCARRIER_NUMBER - i - 1], linewidth=3)

plt.xlabel("f[Hz]", fontsize=22)
# plt.ylabel("スペクトル", fontsize=22)

plt.tight_layout()

# plt.show()

os.makedirs("assets", exist_ok=True)
# word用なので、svgではなくpng
plt.savefig("assets/ofdm-sinc-spectrum.png")
os.chdir(start_dir)
