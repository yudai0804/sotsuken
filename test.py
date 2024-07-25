import numpy as np

# TODO: Nの数はあとでちゃんと考える

# IFFT/FFTの回転因子の数
N = 2048
# OFDMの周波数帯域は1~6kHz
# OFDMの下限
SUBCARRIER_FREQUENCY_MIN = 1000
# OFDMの上限
SUBCARRIER_FREQUENCY_MAX = 6000
# サブキャリア数
SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL = 96
# サブキャリア間隔
SUBCARRIER_INTERVAL = 50

# キャリア周波数
# 値は仮
CARRIER_FREQUENCY = 1e6

# パイロット信号の周波数
PILOT_SIGNAL_FREQUENCY = [1000, 1050, 2700, 4350, 6000]
# パイロット信号の数
PILOT_SIGNAL_NUMBER = len(PILOT_SIGNAL_FREQUENCY)
# パイロット信号の振幅
PILOT_SIGNAL_AMPLITUDE = 2
# パイロット信号の位相
PILOT_SIGNAL_PHASE = 0

"""
S/P変換
データはMSBファーストにする
配列の要素1つ分は1シンボルに該当する
"""


def serial_to_parallel(x: np.ndarray, bit=8) -> np.ndarray:
    y = np.array([])
    for i in x:
        for j in reversed(range(bit)):
            if i & (0x01 << j):
                y = np.append(y, 1)
            else:
                y = np.append(y, 0)
    return y


"""
bpsk
今回は1シンボル1ビット
ビットが1のところは位相0[rad]に、ビットが0のところは位相π[rad]にする。
"""


def bpsk(x: np.ndarray, bit=8) -> np.ndarray:
    y = np.array([])
    for i in x:
        if i == 1:
            y = np.append(y, 0)
        else:
            y = np.append(y, np.pi)
    return y


def create_spectrum_array(bpsk_phase: np.ndarray) -> np.ndarray:
    all_subcarrire_number = SUBCARRIER_FREQUENCY_MAX // SUBCARRIER_INTERVAL + 1
    phase = np.zeros(all_subcarrire_number)
    A = np.zeros(all_subcarrire_number)
    f = np.linspace(0, SUBCARRIER_FREQUENCY_MAX, all_subcarrire_number)
    j = 0
    for i in range(
        SUBCARRIER_FREQUENCY_MIN // SUBCARRIER_INTERVAL, all_subcarrire_number
    ):
        is_pilot_signal = False
        for f_ps in PILOT_SIGNAL_FREQUENCY:
            if f[i] == f_ps:
                is_pilot_signal = True
        if is_pilot_signal:
            A[i] = PILOT_SIGNAL_AMPLITUDE
        else:
            A[i] = 1
            phase[i] = bpsk_phase[j]
            j += 1
    X = A * np.exp(1j * (2 * np.pi * f + phase) / N)
    return X


def ifft(X: np.ndarray) -> np.ndarray:
    x = np.fft.ifft(X)
    print(x)
    return x


original_data = np.array([], dtype=np.int64)
for i in range(12):
    original_data = np.append(original_data, ord("A") + i)
print(original_data)
sp = serial_to_parallel(original_data)
bpsk_data = bpsk(sp.astype(np.float64))
spe = create_spectrum_array(bpsk_data)
ans = ifft(spe)
print(ans)
