import numpy as np
from scipy import interpolate
from scipy import signal
import matplotlib.pyplot as plt
import random
import cmath

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
        X = A * np.exp(1j * phase)
        return X

    def __ifft(self, X: np.ndarray) -> np.ndarray:
        """
        返り値はt,x
        ただし、tは実際の時間ではなくて0~N-1なので注意。
        """
        # TODO: 返り値の時刻データが美しくないので後で直す。あと、復調のプログラムとの対象性がない
        x = np.fft.ifft(X, N)
        return np.arange(N), x

    def __multiply_by_carrier(self, x: np.ndarray):
        """
        返り値はt,x
        """
        fc = CARRIER_FREQUENCY
        t = np.linspace(0, 0.02, int(fs), endpoint=False)
        # IFFTした点の数と1/(2fc)の数が合わないので、線形補間する
        fitted = interpolate.interp1d(np.linspace(0, t[-1], N), x)
        fitted_x = fitted(t)
        # 複素平面上の極座標系から実際の波に変換
        # そのとき、ωcで変調もする
        omega_c = 2 * np.pi * fc
        _x = fitted_x.real * np.cos(omega_c * t) + fitted_x.imag * np.sin(omega_c * t)
        return t, _x, fitted_x

    def calc(self, X: np.ndarray):
        """
        X:入力したいデータ
        返り値:
        t, x, ifft_tとifft_x
        tとxはOFDMした最終結果、
        ifft_tとifft_xはifftを行った結果(搬送波との掛け合わせは行っていない)
        """
        # Xがサブキャリア数と等しいか確認
        assert len(X) * 8 == SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, "OFDM Input Error."
        # TODO: S/Pの関数はいらないので後で消す
        sp = self.__serial_to_parallel(X)
        bpsk_data = self.__bpsk(sp.astype(np.float64))
        spe = self.__create_spectrum_array(bpsk_data)
        ifft_t, ifft_x = self.__ifft(spe)
        t, x, no_carrier_signal = self.__multiply_by_carrier(ifft_x)
        return t, x, ifft_t, ifft_x, no_carrier_signal


class OFDM_Demodulation:
    def __lpf(self, x, cutoff, fs, order=5):
        # カットオフ周波数はナイキスト周波数で正規化したものをbutter関数に渡す
        _cutoff = cutoff / (0.5 * fs)
        b, a = signal.butter(order, _cutoff, btype="low")
        y = signal.filtfilt(b, a, x)
        return y

    def __synchronous_detection(self, t: np.ndarray, x: np.ndarray):
        """
        同期検波
        """
        omega_c = 2 * np.pi * CARRIER_FREQUENCY
        Re = np.cos(omega_c * t) * x
        Im = np.sin(omega_c * t) * x
        Re_filter = self.__lpf(Re, cutoff, fs)
        Im_filter = self.__lpf(Im, cutoff, fs)
        x_complex = Re_filter + 1j * Im_filter
        # ローパスフィルタを通すと振幅が半分になってしまうので、2倍してもとにもどす
        # cos(ωs t)cos^2(ωc t)
        # を計算すると1/2が出てくるため(同期検波)
        x_complex *= 2
        return t, x_complex

    def __fft(self, x_complex):
        X = np.fft.fft(x_complex, N)
        f = np.fft.fftfreq(N, d=1 / SAMPLING_FREQUENCY)
        return f, X

    def __linear_interpolation(self, t, x):
        fitted_t = np.linspace(0.0, t[-1], int(N))
        fitted = interpolate.interp1d(t, x)
        fitted_x = fitted(fitted_t)
        return fitted_t, fitted_x

    def calc(self, t: np.ndarray, x: np.ndarray):
        t, x_complex = self.__synchronous_detection(t, x)
        _t, _x = self.__linear_interpolation(t, x_complex)
        f, X = self.__fft(_x)
        return f, X, _t, _x

    def calc_no_carrier(self, t: np.ndarray, x_complex: np.ndarray):
        _t, _x = self.__linear_interpolation(t, x_complex)
        f, X = self.__fft(_x)
        return f, X, _t, _x


if __name__ == "__main__":
    original_data = np.array([], dtype=np.int64)
    for i in range(12):
        original_data = np.append(original_data, random.randint(0, 255))
        print(f"0b{original_data[i]:08b}")
    ofdm_mod = OFDM_Modulation()
    t, x, ifft_t, ifft_x, no_carrier_signal = ofdm_mod.calc(original_data)
    fig = plt.figure()

    plt.plot(ifft_t, ifft_x)
    plt.figure()
    plt.plot(t, x)
    plt.figure()

    ofdm_demod = OFDM_Demodulation()
    f, X, _t, _x = ofdm_demod.calc(t, x)
    # f, X, _t, _x = ofdm_demod.calc_no_carrier(t, no_carrier_signal)
    plt.plot(_t, _x.real)
    plt.figure()
    for i in range(len(f)):
        val = 0
        if X[i].real > 0:
            val = 1
        print(f"f={f[i]}, X={X[i].real:.3f}, arg={cmath.phase(X[i]):.3f}, val={val}")
    plt.plot(f, X.real)
    plt.show()
