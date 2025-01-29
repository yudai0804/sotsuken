import os
import signal
from typing import Any, List, Tuple

import matplotlib.pyplot as plt
import matplotlib_fontja
import numpy as np
from numpy.typing import NDArray

signal.signal(signal.SIGINT, signal.SIG_DFL)

SUBCARRIER_INTERVAL: float = 46.875
N: int = 1024
N2: int = N // 2
index = np.zeros(N2, np.int32)
X = np.zeros(N2, np.float64)

start_dir = os.getcwd()
# このファイルがあるディレクトリまで移動
os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")
with open("data/serial_data_line7=-9.5,master=0,master_out=10", "r") as file:
    for i in range(N2):
        numbers = file.readline().replace(" ", "").split(",")
        index[i] = int(numbers[0])
        X[i] = float(numbers[2])

plt.figure()
# メモリの向きを内側にする。plt.plotの前に呼び出す必要あり。
plt.rcParams["xtick.direction"] = "in"
plt.rcParams["ytick.direction"] = "in"
plt.plot(index[0:130] * SUBCARRIER_INTERVAL, X[0:130])
plt.xlabel("周波数[Hz]", fontsize=22)
plt.ylabel("フーリエ係数", fontsize=22)
plt.xticks([0, 2000, 4000, 6000])
plt.yticks([-0.25, 0.0, 0.25, 0.5])
plt.tick_params(width=1, length=10, labelsize=22)
plt.ylim(-0.30, 0.55)
plt.tight_layout()

os.makedirs("assets", exist_ok=True)
# word用なので、svgではなくpng
plt.savefig("assets/ofdm-result-spectrum.png")
os.chdir(start_dir)
