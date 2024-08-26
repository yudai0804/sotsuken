import numpy as np
import numpy.testing as npt
import scipy.signal
import scipy.interpolate
import matplotlib.pyplot as plt
import cmath
import bisect
import math
import sys
import random

# japanize-matplotlibの代替(Python3.12以降はjapanize-matplotlibは動かないらしいので)
import matplotlib_fontja

# IFFT/FFTの回転因子の数
N = 256
# OFDMの周波数帯域は1~6kHz
# OFDMの下限[Hz]
SUBCARRIER_FREQUENCY_MIN = 1000
# OFDMの上限[Hz]
SUBCARRIER_FREQUENCY_MAX = 6000
# サブキャリア数
SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL = 96
# サブキャリア間隔[Hz]
# 変調に用いる情報であって、復調時はサンプリング周波数とNでサブキャリア間隔が決まるので注意
SUBCARRIER_INTERVAL = 50

# パイロット信号の周波数[Hz]
PILOT_SIGNAL_FREQUENCY = [1000, 1050, 2700, 4350, 6000]
# パイロット信号の数[Hz]
PILOT_SIGNAL_NUMBER = len(PILOT_SIGNAL_FREQUENCY)
# パイロット信号の振幅
PILOT_SIGNAL_AMPLITUDE = 2
# パイロット信号の位相[rad]
PILOT_SIGNAL_PHASE = 0

SAMPLING_FREQUENCY = 12800


#####################
# お気持ちパラメーター
# 本来は搬送波はアナログフィルタで処理してしまうが、シミュレーションのためディジタルフィルタで処理する用
# そもそもfsが44.1kHz超えてる時点でおかしい

# キャリア周波数[Hz]
# 値は仮
CARRIER_FREQUENCY = 2e6
fs = 1e7
cutoff = 1e4
#####################


class OFDM_Modulation:
    def __serial_to_parallel(self, x: np.ndarray, bit=8) -> np.ndarray:
        """
        S/P変換
        データはMSBファーストにする
        配列の要素1つ分は1シンボルに該当する
        """
        y = np.array([])
        for i in x:
            for j in reversed(range(bit)):
                if i & (0x01 << j):
                    y = np.append(y, 1)
                else:
                    y = np.append(y, 0)
        return y

    def __bpsk(self, x: np.ndarray, bit=8) -> np.ndarray:
        """
        bpsk
        今回は1シンボル1ビット
        ビットが1のところは位相0[rad]に、ビットが0のところは位相π[rad]にする。
        """
        y = np.array([])
        for i in x:
            if i == 1:
                y = np.append(y, 0)
            else:
                y = np.append(y, np.pi)
        return y

    def __create_spectrum_array(self, bpsk_phase: np.ndarray) -> np.ndarray:
        all_subcarrier_number = SUBCARRIER_FREQUENCY_MAX // SUBCARRIER_INTERVAL + 1
        # all_subcarrier_number < N/2よりサブキャリアの周波数はすべて正であることが保証される。
        # 参考:https://numpy.org/doc/stable/reference/generated/numpy.fft.ifft.html
        assert all_subcarrier_number < N / 2
        phase = np.zeros(N, dtype=np.complex128)
        A = np.zeros(N, dtype=np.complex128)
        f = np.linspace(0, SUBCARRIER_FREQUENCY_MAX, all_subcarrier_number)
        j = 0
        for i in range(
            SUBCARRIER_FREQUENCY_MIN // SUBCARRIER_INTERVAL, all_subcarrier_number
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
        X = A * np.exp(1j * phase)
        # 負の周波数に正の周波数のスペクトルをコピー
        for i in range(N // 2):
            X[i + N // 2] = X[N // 2 - i - 1]
        return X

    def __ifft(self, X: np.ndarray) -> np.ndarray:
        """
        返り値はt,x
        ただし、tは実際の時間ではなくて0~N-1なので注意。
        """
        x = np.fft.ifft(X, N)
        return np.arange(N), x

    def __multiply_by_carrier(self, x: np.ndarray):
        """
        返り値はt,x
        """
        fc = CARRIER_FREQUENCY
        t = np.linspace(0, 0.02, int(fs), endpoint=False)
        # IFFTした点の数と1/(2fc)の数が合わないので、線形補間する
        fitted = scipy.interpolate.interp1d(np.linspace(0, t[-1], N), x)
        fitted_x = fitted(t)
        # 複素平面上の極座標系から実際の波に変換
        # そのとき、ωcで変調もする
        omega_c = 2 * np.pi * fc
        _x = fitted_x.real * np.cos(omega_c * t) + fitted_x.imag * np.sin(omega_c * t)
        return t, _x, fitted_x

    def calculate(self, X: np.ndarray, is_no_carrier=False):
        """
        X:入力したいデータ
        返り値:
        t, x, ifft_tとifft_x
        tとxはOFDMした最終結果、
        ifft_tとifft_xはifftを行った結果(搬送波との掛け合わせは行っていない)
        ifft_xは複素数だが、xは実数なので注意
        """
        # Xがサブキャリア数と等しいか確認
        assert len(X) * 8 == SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, "OFDM Input Error."
        sp = self.__serial_to_parallel(X)
        bpsk_data = self.__bpsk(sp.astype(np.float64))
        spe = self.__create_spectrum_array(bpsk_data)
        ifft_t, ifft_x = self.__ifft(spe)
        t = np.array([])
        x = np.array([])
        if is_no_carrier == False:
            t, x, _dummy = self.__multiply_by_carrier(ifft_x)
        return t, x, ifft_t, ifft_x

    def calculate_no_carrier(self, X: np.ndarray):
        """
        搬送波との掛け合わせを行っていない結果(ifftを行った結果)を返す
        tとxは空の配列なので、ifft_tとifft_xのみ返す
        """
        t, x, ifft_t, ifft_x = self.calculate(X, is_no_carrier=True)
        return ifft_t, ifft_x


class OFDM_Demodulation:
    def __lpf(self, x, cutoff, fs, order=5):
        # カットオフ周波数はナイキスト周波数で正規化したものをbutter関数に渡す
        _cutoff = cutoff / (0.5 * fs)
        b, a = scipy.signal.butter(order, _cutoff, btype="low")
        y = scipy.signal.filtfilt(b, a, x)
        return y

    def __synchronous_detection(self, t: np.ndarray, x: np.ndarray):
        """
        同期検波
        """
        omega_c = 2 * np.pi * CARRIER_FREQUENCY
        Re = np.cos(omega_c * t) * x
        Im = np.sin(omega_c * t) * x
        Re_filter = self.__lpf(Re, cutoff, fs, order=5)
        Im_filter = self.__lpf(Im, cutoff, fs, order=5)
        x_complex = Re_filter + 1j * Im_filter
        # ローパスフィルタを通すと振幅が半分になってしまうので、2倍してもとにもどす
        # cos(ωs t)cos^2(ωc t)
        # を計算すると1/2が出てくるため(同期検波)
        x_complex *= 2
        return t, x_complex

    def __quantization(self, x, bit, low, high):
        """
        量子化
        """
        # 二分探索を用いて量子化
        y = np.zeros(len(x), dtype="complex128")
        q = np.linspace(low, high, int(2**bit))
        for i in range(len(x)):
            # real
            j = bisect.bisect(q, x[i].real)
            if j == len(q):
                j = len(q) - 1
            y[i] += q[j]
            # imag
            j = bisect.bisect(q, x[i].imag)
            if j == len(q):
                j = len(q) - 1
            y[i] += 1j * q[j]

        return y

    def __fft(self, x_complex: np.ndarray):
        X = np.fft.fft(x_complex, N)
        f = np.fft.fftfreq(N, d=1 / SAMPLING_FREQUENCY)
        return f, X

    def __linear_interpolation(self, t: np.ndarray, x: np.ndarray):
        fitted_t = np.linspace(0.0, t[-1], int(N))
        fitted = scipy.interpolate.interp1d(t, x)
        fitted_x = fitted(fitted_t)
        return fitted_t, fitted_x

    def __pilot(self, f: np.ndarray, X: np.ndarray):
        """
        FFTした結果は次のように格納されるので、1000~6000Hzの部分のみを切り抜く
        パイロット信号も除く
        f = [0, 1, ...,   n/2-1,     -n/2, ..., -1] / (d*n)   if n is even
        f = [0, 1, ..., (n-1)/2, -(n-1)/2, ..., -1] / (d*n)   if n is odd
        参考:https://numpy.org/doc/stable/reference/generated/numpy.fft.fftfreq.html#numpy.fft.fftfreq
        """
        ans_f = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL)
        ans_X = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, dtype=np.complex128)

        i = SUBCARRIER_FREQUENCY_MIN // SUBCARRIER_INTERVAL
        j = 0
        pilot_diff = 0
        while i <= SUBCARRIER_FREQUENCY_MAX // SUBCARRIER_INTERVAL:
            is_pilot = False
            for fp in PILOT_SIGNAL_FREQUENCY:
                if f[i] == fp:
                    is_pilot = True
                    pilot_diff = X[i] - (2 + 0j)

            if is_pilot:
                i += 1
                continue

            ans_f[j] = f[i]
            ans_X[j] = X[i] - pilot_diff
            i += 1
            j += 1

        return ans_f, ans_X

    def __bpsk(self, X):
        ans = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, dtype=int)
        for i in range(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL):
            if X[i].real > 0:
                ans[i] = 1
            else:
                ans[i] = 0
        return ans

    def __parallel_to_serial(self, x):
        ans = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL // 8, dtype=int)
        for i in range(len(ans)):
            for j in range(8):
                if x[8 * i + j] == 1:
                    ans[i] += 1 << (7 - j)
        return ans

    def calculate(self, t: np.ndarray, x: np.ndarray, is_no_carrier=False):
        x_complex = np.array([])
        if is_no_carrier:
            x_complex = x
        else:
            t, x_complex = self.__synchronous_detection(t, x)
        _t, _x = self.__linear_interpolation(t, x_complex)
        # 量子化をするとDCバイアスが少しのる。
        # 量子化を細かくすればDCバイアスは小さくなる
        __x = self.__quantization(_x, 10, -0.5, 0.5)
        f, X = self.__fft(__x)
        # f, X = self.__fft(_x)
        _f, _X = self.__pilot(f, X)
        para = self.__bpsk(_X)
        data = self.__parallel_to_serial(para)
        return data, f, X, _t, _x, __x

    def calculate_no_carrier(self, t: np.ndarray, x_complex: np.ndarray):
        """
        x_complexは搬送波を含んでいない信号である必要がある
        """
        return self.calculate(t, x_complex, is_no_carrier=True)


class Synchronization:
    def __init__(self):
        self.MINIMUM_VOLTAGE = 0.001
        self.EDGE_THRESHOLD = 0.05
        self.BUFFER_LENGTH = 16 * N
        self.CORRELATE_THRESHOLD = 0.5
        self.ONE_CYCLE_BUFFER_LENGTH = N

        self.__is_detect_signal = False

    def calculate(self, x: np.ndarray):
        assert len(x) == self.BUFFER_LENGTH, "length error"

        sum = 0
        offset: int = -1
        # 積分をして信号の立ち上がりを探す
        for i in range(len(x)):
            # 電圧が小さい場合は無信号時のノイズなのでcontinue
            if abs(x[i]) < self.MINIMUM_VOLTAGE:
                continue
            sum += abs(x[i])
            if sum >= self.EDGE_THRESHOLD:
                offset = i
                break

        # 積分した結果、信号を見つけられなかった場合
        if offset == -1:
            self.__is_detect_signal = False
            return np.array([]), np.array([]), np.array([])

        # 正確な立ち上がり時間を求めるために前の時間を探索
        cnt = 0
        while offset > 0 and cnt < 10:
            sum -= abs(x[offset])
            if sum < self.MINIMUM_VOLTAGE:
                break
            offset -= 1
            cnt += 1

        # 相互相関関数を求めるために、1周期だけを切り取る
        # 積分だけでは正確な立ち上がりは検出できないため、少し多めに読む
        x_one_cycle = np.zeros(self.ONE_CYCLE_BUFFER_LENGTH, dtype=np.complex128)
        for i in range(self.ONE_CYCLE_BUFFER_LENGTH):
            x_one_cycle[i] = x[i + offset]

        # 相関を求める
        R = scipy.signal.correlate(x, x_one_cycle)
        index = np.arange(len(R)) - self.ONE_CYCLE_BUFFER_LENGTH + 1

        signal_index = np.array([], int)
        last_detect = -1
        for i in range(len(R)):
            if R[i].real > self.CORRELATE_THRESHOLD:
                # オフセット分ずらす
                signal_index = np.append(signal_index, index[i])
                last_detect = i
            # 1周期ちょっと離れても、信号が見つからない場合は終了
            if last_detect != -1 and i - last_detect > 300:
                break

        self.__is_detect_signal = len(signal_index) > 0

        return signal_index, R, index

    def is_detect_signal(self) -> bool:
        return self.__is_detect_signal


def compare_np_array(a, b):
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def single_signal():
    original_data = np.random.randint(0, 255, size=12)
    print(original_data)
    ofdm_mod = OFDM_Modulation()
    t, x, ifft_t, ifft_x = ofdm_mod.calculate(original_data)
    plt.figure()
    plt.plot(ifft_t, ifft_x)
    plt.title("入力信号をIFFTした結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plt.figure()
    plt.plot(t, x)
    plt.title("IFFTした結果に搬送波をかけ合わせた結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    ofdm_demod = OFDM_Demodulation()
    # ans_data, f, X, _t, _x, __x = ofdm_demod.calculate(t, x)
    # 雑音を加える
    # gain = 0.0001
    # ifft_x += gain * (np.random.rand(N) + 1j * np.random.rand(N))
    ans_data, f, X, _t, _x, __x = ofdm_demod.calculate_no_carrier(ifft_t, ifft_x)

    assert len(original_data) == len(ans_data)
    for i in range(len(original_data)):
        assert (
            original_data[i] == ans_data[i]
        ), f"original = {original_data[i]}, answer = {ans_data[i]}"
        print(f"original = {original_data[i]}, answer = {ans_data[i]}")
    for i in range(len(X)):
        print(f"f = {f[i]}, X = {X[i]:.3f}")

    plt.figure()
    plt.plot(_t, _x.real)
    plt.title("受信信号に同期検波を行った結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plot_f = np.fft.fftshift(f)
    plot_X = np.fft.fftshift(X.real)

    plt.figure()
    plt.plot(plot_f, plot_X)
    plt.title("受信信号をFFTした結果")
    plt.xlabel("周波数[Hz]")
    plt.ylabel("振幅")

    plt.show()


def multi_signal():
    original_data = np.random.randint(0, 255, size=12)
    print(original_data)
    ofdm_mod = OFDM_Modulation()
    ifft_t, ifft_x = ofdm_mod.calculate_no_carrier(original_data)
    # 雑音を加える
    gain = 0.0001
    ifft_x += gain * (np.random.rand(N) + 1j * np.random.rand(N))
    t16 = np.zeros(len(ifft_t) * 16)
    x16 = np.zeros(len(ifft_x) * 16, dtype=np.complex128)
    dt = 1 / SAMPLING_FREQUENCY
    for i in range(len(t16)):
        t16[i] = i * dt
        x16[i] = ifft_x[i % N]
    for i in range(N):
        x16[9 * N + i] = 0
    tmp = np.zeros(len(x16), dtype=np.complex128)
    shift = random.randint(0, 3000)
    # shift
    shift = random.randint(0, 3000)
    print("shift = ", shift)
    x16 = np.pad(x16, (shift, 0))[0 : len(x16)]
    sync = Synchronization()
    signal_index, R, index = sync.calculate(x16)
    if sync.is_detect_signal() == False:
        print("no signal")
        return
    print("signal index = ", signal_index)
    # 復調
    demod = OFDM_Demodulation()
    shift_cnt = 0
    for i in range(len(signal_index)):
        demod_t = np.arange(N) * dt
        demod_x = np.zeros(N, dtype=np.complex128)
        if signal_index[i] + N - 1 >= sync.BUFFER_LENGTH:
            break
        for j in range(N):
            demod_x[j] = x16[signal_index[i] + j - shift_cnt]
        ans_data, f, X, _t, _x, __x = demod.calculate_no_carrier(demod_t, demod_x)

        # 信号がない場合はオフセットがずれている可能性があるので、少しシフトしてもう一度復調する
        while (
            compare_np_array(original_data, ans_data) == False
            and shift_cnt < 5
            and signal_index[i - shift_cnt] > 0
        ):
            shift_cnt += 1
            for j in range(N):
                demod_x[j] = x16[signal_index[i] + j - shift_cnt]
            ans_data, f, X, _t, _x, __x = demod.calculate_no_carrier(demod_t, demod_x)
        print("ans", ans_data)
        npt.assert_equal(original_data, ans_data)
    """
    plt.figure()
    # plt.plot(t16, x16)
    plt.plot(np.arange(len(t16)), x16)
    plt.figure()
    # plt.plot(index, R.real)
    plt.plot(np.arange(len(R)), R.real)
    plt.show()
    """


if __name__ == "__main__":
    # matplotlibを使ったときにctrl cで停止できるようにする
    # 参考:https://stackoverflow.com/questions/67977761/how-to-make-plt-show-responsive-to-ctrl-c
    import signal

    signal.signal(signal.SIGINT, signal.SIG_DFL)

    for i in range(256):
        print("cnt=", i)
        multi_signal()
