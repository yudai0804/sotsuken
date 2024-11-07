import numpy as np
import numpy.testing as npt
from numpy.typing import NDArray
from pydantic import BaseModel, ConfigDict
from typing import Any, List, Tuple
import scipy.signal
import scipy.interpolate
import matplotlib.pyplot as plt
import bisect
import random
import math

# japanize-matplotlibの代替(Python3.12以降はjapanize-matplotlibは動かないらしいので)
import matplotlib_fontja

# IFFT/FFTの回転因子の数
N: int = 1024
# OFDMの周波数帯域は1~6kHz
# OFDMの下限[Hz]
SUBCARRIER_FREQUENCY_MIN: int = 1000
# OFDMの上限[Hz]
SUBCARRIER_FREQUENCY_MAX: int = 6000
# サブキャリア数
SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL: int = 96
# サブキャリア間隔[Hz]
# 変調に用いる情報であって、復調時はサンプリング周波数とNでサブキャリア間隔が決まるので注意
SUBCARRIER_INTERVAL: int = 50

# パイロット信号の周波数[Hz]
PILOT_SIGNAL_FREQUENCY: List[int] = [1000, 1050, 2700, 4350, 6000]
# パイロット信号の数[Hz]
PILOT_SIGNAL_NUMBER: int = len(PILOT_SIGNAL_FREQUENCY)
# パイロット信号の振幅
PILOT_SIGNAL_AMPLITUDE: int = 2
# パイロット信号の位相[rad]
PILOT_SIGNAL_PHASE: float = 0

SAMPLING_FREQUENCY: int = 51200

# ローパスフィルタのカットオフ周波数
CUTOFF_FREQUENCY: int = int(1e4)

# 同期検波用パラメーター
SYNC_DETECT_CARRIER_FREQUENCY: int = int(2e6)
SYNC_DETECT_SAMPLING_FREQUENCY: int = int(4e6)
SYNC_DETECT_CUTOFF_FREQUENCY: int = int(1e4)


class Modulation:
    def __bpsk(self, x: NDArray[np.int32]) -> NDArray[np.int32]:
        """
        bpsk
        1シンボル1ビット
        ビットが1のところを1に、ビットが0のところを-1にする
        """
        bit: int = 8
        y = np.zeros(len(x) * bit, dtype=np.int32)
        for i in range(len(x)):
            for j in reversed(range(bit)):
                if x[i] & (0x01 << j):
                    y[bit * i + 7 - j] = 1
                else:
                    y[bit * i + 7 - j] = -1
        return y

    def __create_spectrum_array(
        self, bpsk_phase: NDArray[np.int32]
    ) -> NDArray[np.float64]:
        X = np.zeros(N, dtype=np.float64)
        f: NDArray[np.int32] = np.arange(
            0, SUBCARRIER_FREQUENCY_MAX + 1, step=SUBCARRIER_INTERVAL, dtype=np.int32
        )
        j: int = 0
        for i in range(SUBCARRIER_FREQUENCY_MIN // SUBCARRIER_INTERVAL, len(f)):
            is_pilot_signal: bool = False
            for f_ps in PILOT_SIGNAL_FREQUENCY:
                if f[i] == f_ps:
                    is_pilot_signal = True
            if is_pilot_signal:
                X[i] = PILOT_SIGNAL_AMPLITUDE
            else:
                X[i] = bpsk_phase[j]
                j += 1
        # 負の周波数に正の周波数のスペクトルをコピー
        for i in range(1, N // 2):
            X[N - i] = X[i]
        return X

    def __ifft(
        self, X: NDArray[np.float64]
    ) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
        """
        返り値はt,x
        ただし、tは実際の時間ではなくて0~N-1なので注意。
        """
        _x = np.fft.ifft(X, N)
        x = np.zeros(N, dtype=np.float64)
        for i in range(N):
            x[i] = _x[i].real
        return np.arange(N, dtype=np.float64), x

    def __multiply_by_carrier(
        self, x: NDArray[np.float64]
    ) -> Tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
        """
        返り値はt,x
        """
        t: NDArray[np.float64] = np.linspace(
            0,
            1 / SUBCARRIER_INTERVAL,
            SYNC_DETECT_SAMPLING_FREQUENCY,
            endpoint=False,
        )
        # IFFTした点の数と1/(2fc)の数が合わないので、線形補間する
        fitted = scipy.interpolate.interp1d(np.linspace(0, t[-1], N), x)
        fitted_x = fitted(t)
        # 複素平面上の極座標系から実際の波に変換
        # そのとき、ωcで変調もする
        omega_c: float = 2 * np.pi * SYNC_DETECT_CARRIER_FREQUENCY
        _x: NDArray[np.float64] = fitted_x * np.cos(omega_c * t)
        return t, _x, fitted_x

    class Result(BaseModel):
        model_config = ConfigDict(arbitrary_types_allowed=True)

        t: NDArray[np.float64]
        x: NDArray[np.float64]
        ifft_t: NDArray[np.float64]
        ifft_x: NDArray[np.float64]

    def calculate(self, X: NDArray[np.int32], is_no_carrier: bool = False) -> Result:
        """
        X:入力したいデータ
        返り値:
        t, x, ifft_tとifft_x
        tとxはOFDMした最終結果、
        ifft_tとifft_xはifftを行った結果(搬送波との掛け合わせは行っていない)
        """
        # Xがサブキャリア数と等しいか確認
        assert len(X) * 8 == SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, "OFDM Input Error."
        bpsk_data = self.__bpsk(X)
        spe = self.__create_spectrum_array(bpsk_data)
        ifft_t, ifft_x = self.__ifft(spe)
        t = np.array([], dtype=np.float64)
        x = np.array([], dtype=np.float64)
        if is_no_carrier == False:
            t, x, _dummy = self.__multiply_by_carrier(ifft_x)
        return self.Result(t=t, x=x, ifft_t=ifft_t, ifft_x=ifft_x)

    def calculate_no_carrier(self, X: NDArray[np.int32]) -> Result:
        """
        搬送波との掛け合わせを行っていない結果(ifftを行った結果)を返す
        Resultのtとxは空
        """
        return self.calculate(X, True)


class Demodulation:
    def __init__(self) -> None:
        self.__is_success: bool = False

    def __lpf(
        self, x: NDArray[np.float64], cutoff: float, fs: float, order: int
    ) -> NDArray[np.float64]:
        """
        LPFを行うscipyのwrapper関数
        """
        # カットオフ周波数はナイキスト周波数で正規化したものをbutter関数に渡す
        _cutoff = cutoff / (0.5 * fs)
        b, a = scipy.signal.butter(order, _cutoff, btype="low")
        y: NDArray[np.float64] = scipy.signal.filtfilt(b, a, x)
        return y

    def __synchronous_detection(
        self, t: NDArray[np.float64], x: NDArray[np.float64]
    ) -> NDArray[np.float64]:
        """
        同期検波
        """
        omega_c: float = 2 * np.pi * SYNC_DETECT_CARRIER_FREQUENCY
        # x_lpfはorder=5じゃないとシミュレーション上で搬送波を除去しきれない
        # 現実ではorder=1はありえないので注意。搬送波の周波数がシミュレーションの都合上、実際より低いのが原因
        x_lpf = self.__lpf(
            np.cos(omega_c * t) * x,
            SYNC_DETECT_CUTOFF_FREQUENCY,
            SYNC_DETECT_SAMPLING_FREQUENCY,
            order=5,
        )
        # ローパスフィルタを通して同期検波を行うと振幅が半分になってしまうので、2倍してもとにもどす。
        # 振幅が半分になるのはcos(ωs t)cos^2(ωc t)を計算すると1/2が出てくるため。
        x_lpf *= 2
        return x_lpf

    def __lowpass(self, x: NDArray[np.float64]) -> NDArray[np.float64]:
        """
        ノイズ除去用ローパスフィルタ
        """
        return self.__lpf(x, CUTOFF_FREQUENCY, SAMPLING_FREQUENCY, order=1)

    def __quantization(
        self, x: NDArray[np.float64], bit: int, low: float, high: float
    ) -> NDArray[np.float64]:
        """
        量子化
        """
        # 二分探索を用いて量子化
        y = np.zeros(len(x), dtype=np.float64)
        q: NDArray[np.float64] = np.linspace(low, high, int(2**bit))
        for i in range(len(x)):
            j = bisect.bisect(q, x[i])
            if j == len(q):
                j = len(q) - 1
            y[i] += q[j]
        return y

    def __fft(
        self, x: NDArray[np.float64]
    ) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
        _X = np.fft.fft(x, N)
        X = np.zeros(N, np.float64)
        for i in range(N):
            X[i] = _X[i].real
        f: NDArray[np.float64] = np.fft.fftfreq(N, d=1 / SAMPLING_FREQUENCY)
        return f, X

    def __linear_interpolation(
        self, t: NDArray[np.float64], x: NDArray[np.float64]
    ) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
        """
        線形補間を行うscipyのwrapper関数
        """
        fitted_t: NDArray[np.float64] = np.linspace(0.0, t[-1], int(N))
        fitted = scipy.interpolate.interp1d(t, x)
        fitted_x: NDArray[np.float64] = fitted(fitted_t)
        return fitted_t, fitted_x

    def __pilot(
        self, f: NDArray[np.float64], X: NDArray[np.float64]
    ) -> NDArray[np.float64]:
        """
        FFTした結果は次のように格納されるので、1000~6000Hzの部分のみを切り抜く
        パイロット信号も除く
        f = [0, 1, ...,   n/2-1,     -n/2, ..., -1] / (d*n)   if n is even
        f = [0, 1, ..., (n-1)/2, -(n-1)/2, ..., -1] / (d*n)   if n is odd
        参考: https://numpy.org/doc/stable/reference/generated/numpy.fft.fftfreq.html#numpy.fft.fftfreq
        """
        ans_f = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, dtype=np.float64)
        ans_X = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL, dtype=np.float64)

        i: int = SUBCARRIER_FREQUENCY_MIN // SUBCARRIER_INTERVAL
        j: int = 0
        pilot_diff: float = 0
        PILOT_MIN: float = 1.5
        PILOT_MAX: float = 2.5
        while i <= SUBCARRIER_FREQUENCY_MAX // SUBCARRIER_INTERVAL:
            is_pilot: bool = False
            for fp in PILOT_SIGNAL_FREQUENCY:
                if abs(f[i] - fp) <= 1e-10:
                    is_pilot = True
                    pilot_diff = X[i] - PILOT_SIGNAL_AMPLITUDE
                    if (PILOT_MIN < X[i] < PILOT_MAX) == False:
                        self.__is_success = False

            if is_pilot:
                i += 1
                continue

            ans_f[j] = f[i]
            ans_X[j] = X[i] - pilot_diff
            i += 1
            j += 1

        return ans_X

    def __bpsk(self, X: NDArray[np.float64]) -> NDArray[np.int32]:
        ans = np.zeros(SUBCARRIER_NUMBER_IGNORE_PILOT_SIGNAL // 8, dtype=np.int32)
        for i in range(len(ans)):
            for j in range(8):
                if X[8 * i + j] > 0:
                    ans[i] += 1 << (7 - j)
        return ans

    def __check_data(self, data: NDArray[np.int32]) -> None:
        """
        0バイト目と11バイト目が0x55であれば通信成功
        __pilotのところでパイロット信号が適切に挿入されていなかった場合も失敗という判断を行っている
        """
        self.__is_success = data[0] == 0x55 and data[11] == 0x55

    class Result(BaseModel):
        model_config = ConfigDict(arbitrary_types_allowed=True)

        is_success: bool
        data: NDArray[np.int32]
        f: NDArray[np.float64]
        X: NDArray[np.float64]
        t_len_n: NDArray[np.float64]
        x_len_n: NDArray[np.float64]
        x_lpf: NDArray[np.float64]
        x_quant: NDArray[np.float64]
        x_sync_detect: NDArray[np.float64]

    def calculate(
        self,
        t: NDArray[np.float64],
        x: NDArray[np.float64],
        is_no_carrier: bool = False,
    ) -> Result:
        self.__is_success = True

        x_sync_detect = np.array([], dtype=np.float64)
        if is_no_carrier == False:
            x_sync_detect = self.__synchronous_detection(t, x)
            x = x_sync_detect.copy()
        # ノイズ除去用ローパスフィルタ
        x_lpf = self.__lowpass(x)
        t_len_n, x_len_n = self.__linear_interpolation(t, x_lpf)
        # 量子化をするとDCバイアスが少しのる。
        # 量子化を細かくすればDCバイアスは小さくなる
        # 最大振幅(0.05)の√2倍に設定
        # パラメーターは雰囲気で決めているため、他のパラメーターを変えるとずれることがあるので注意
        MAX_AMPLITUDE: float = 0.05**0.5
        x_quant = self.__quantization(x_len_n, 8, -MAX_AMPLITUDE, MAX_AMPLITUDE)
        f, X = self.__fft(x_quant)
        _X = self.__pilot(f, X)
        data = self.__bpsk(_X)
        self.__check_data(data)
        return self.Result(
            is_success=self.__is_success,
            data=data,
            f=f,
            X=X,
            t_len_n=t_len_n,
            x_len_n=x_len_n,
            x_lpf=x_lpf,
            x_quant=x_quant,
            x_sync_detect=x_sync_detect,
        )

    def calculate_no_carrier(
        self, t: NDArray[np.float64], x: NDArray[np.float64]
    ) -> Result:
        """
        同期検波は行っていないのでx_sync_detectは空
        """
        return self.calculate(t, x, True)


class Synchronization:
    def __init__(self) -> None:
        # 根拠なきお気持ちパラメーター
        # ここらへんのパラメーターはNなどを変更したら、調整しないと動かないときがあるので注意

        self.MINIMUM_VOLTAGE: float = 0.0005
        self.EDGE_THRESHOLD: float = 0.0025
        # SYMBOL_NUMBERが1だとオフセットがずれていた場合に復調できないことがあるので、3が最小(2と効率が変わらない)
        self.SYMBOL_NUMBER: int = 3
        self.BUFFER_LENGTH: int = self.SYMBOL_NUMBER * N
        self.CORRELATE_THRESHOLD: float = 0.125
        self.ONE_CYCLE_BUFFER_LENGTH: int = N
        self.SYMBOL_RANGE: int = int(0.025 * N)

        self.__is_detect_signal: bool = False
        # 0~2N-1
        # offsetが2Nより大きい値になってしまうと、インデックスが3N-1からはみ出てしまうので最大でも2N-1
        self.__offset: int = 0
        self.__detect_count: int = 0
        self.__symbol = np.array([-1] * 9, dtype=np.int32)
        self.__x_one_cycle = np.zeros(self.ONE_CYCLE_BUFFER_LENGTH, dtype=np.float64)

    def __shift(self) -> None:
        if self.__offset - N >= 0:
            self.__offset -= N
        for i in range(len(self.__symbol)):
            self.__symbol[i] -= N

    def __search_rising(self, x: NDArray[np.float64]) -> None:
        if self.__is_detect_signal == True and 0 < self.__detect_count < 9:
            return
        if self.__is_detect_signal == True and self.__detect_count == 9:
            self.__is_detect_signal = False
            self.__detect_count = 0
            self.__offset = self.__symbol[-1]
            return
        # self.__detect_count == 0のとき

        sum: float = 0
        # 過去のオフセットを使用する場合はは少し戻す
        self.__offset -= 10
        if self.__offset < 0:
            self.__offset = 0
        # 積分をして信号の立ち上がりを探す
        self.__is_detect_signal = False
        for i in range(self.__offset, len(x) - N):
            # 電圧が小さい場合は無信号時のノイズなのでcontinue
            if abs(x[i]) < self.MINIMUM_VOLTAGE:
                continue
            sum += abs(x[i])
            if sum >= self.EDGE_THRESHOLD:
                self.__is_detect_signal = True
                self.__offset = i
                break

        if self.__is_detect_signal == False:
            self.clear_offset()
            return
        # 正確な立ち上がり時間を求めるために前の時間を探索
        cnt: int = 0
        while self.__offset > 0 and cnt < 10:
            sum -= abs(x[self.__offset])
            if sum < self.MINIMUM_VOLTAGE:
                break
            self.__offset -= 1
            cnt += 1

    class Result(BaseModel):
        model_config = ConfigDict(arbitrary_types_allowed=True)

        signal_index: NDArray[np.int32]
        R: NDArray[np.float64]
        index: NDArray[np.int32]

    def __correlate(self, x: NDArray[np.float64]) -> Result:
        # 相互相関関数を求めるために、1周期を切り取る
        if self.__detect_count == 0:
            for i in range(self.ONE_CYCLE_BUFFER_LENGTH):
                self.__x_one_cycle[i] = x[i + self.__offset]

        # 相関を求める
        R = scipy.signal.correlate(x, self.__x_one_cycle)

        index = np.arange(len(R)) - self.ONE_CYCLE_BUFFER_LENGTH + 1
        signal_index = np.array([], dtype=np.int32)
        return self.Result(signal_index=signal_index, R=R, index=index)

    def __is_detected(self, index: int) -> bool:
        if self.__detect_count == 0:
            return False
        for i in range(len(self.__symbol)):
            if index - self.SYMBOL_RANGE < self.__symbol[i] < index + self.SYMBOL_RANGE:
                return self.__detect_count > i
        # 信号のインデックスの合う範囲がなければFalse
        return False

    def __search_data(self, res: Result) -> None:
        last_detect: int = -1
        for i in range(len(res.R)):
            if res.R[i].real > self.CORRELATE_THRESHOLD:
                if last_detect == -1 and self.__is_detected(res.index[i]) == False:
                    res.signal_index = np.append(res.signal_index, res.index[i])
                    last_detect = i
                    self.__symbol[self.__detect_count] = res.index[i]
                    self.__detect_count += 1
                elif self.__is_detected(res.index[i]) and len(res.signal_index) > 0:
                    # signal_indexからindexに変換
                    near: int = res.signal_index[-1] + self.ONE_CYCLE_BUFFER_LENGTH - 1
                    if res.R[i].real > res.R[near].real:
                        res.signal_index[-1] = res.index[i]
                        self.__symbol[self.__detect_count - 1] = res.index[i]
            # データを1つ見つけていれば終了
            # ループを繰り返せばデータがある可能性はあるが、アルゴリズムをシンプルにするため探索は行わない
            if last_detect != -1 and i - last_detect > int(0.2 * N):
                break
        # 最初の発見データだった場合は今後のシンボルのインデックスを予測
        if last_detect != -1 and self.__detect_count == 1:
            for i in range(1, len(self.__symbol)):
                self.__symbol[i] = self.__symbol[0] + i * N

    def calculate(self, x: NDArray[np.float64]) -> Result:
        assert len(x) == self.BUFFER_LENGTH, "length error"
        self.__shift()
        self.__search_rising(x)
        if self.__is_detect_signal == False:
            return self.Result(
                signal_index=np.array([]), R=np.array([]), index=np.array([])
            )
        res = self.__correlate(x)
        self.__search_data(res)

        self.__is_detect_signal = len(res.signal_index) > 0
        return res

    def is_detect_signal(self) -> bool:
        return self.__is_detect_signal

    def set_offset(self, shift: int) -> None:
        for i in range(len(self.__symbol)):
            self.__symbol[i] += shift
        self.__offset += shift

    def set_failed_count(self, failed: int) -> None:
        assert self.__detect_count - failed >= 0
        self.__detect_count -= failed

    def clear_offset(self) -> None:
        for i in range(len(self.__symbol)):
            self.__symbol[i] = -1
        self.__offset = -1
        self.__detect_count = 0


def compare_np_array(a: Any, b: Any) -> bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


def single_symbol(
    original_data: NDArray[np.int32] = np.array([], dtype=np.int32),
) -> Tuple[Modulation.Result, Demodulation.Result]:
    if len(original_data) == 0:
        original_data = np.concatenate(
            ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
            dtype=np.int32,
        )

    print(original_data)
    mod = Modulation()
    res_mod = mod.calculate(original_data)
    demod = Demodulation()
    res_demod = demod.calculate(res_mod.t, res_mod.x)
    ans_data = res_demod.data

    assert (
        res_demod.is_success == True
    ), f"original = {original_data}, answer = {ans_data}"
    assert len(original_data) == len(ans_data)
    for i in range(len(original_data)):
        assert (
            original_data[i] == ans_data[i]
        ), f"original = {original_data[i]}, answer = {ans_data[i]}"
        print(f"original = {original_data[i]}, answer = {ans_data[i]}")

    return res_mod, res_demod


def plot_single_symbol(
    res_mod: Modulation.Result, res_demod: Demodulation.Result
) -> None:
    t = res_mod.t
    plt.figure()
    plt.plot(res_mod.ifft_t, res_mod.ifft_x)
    plt.title("入力信号をIFFTした結果")
    plt.xlabel("時間")
    plt.ylabel("振幅")

    plt.figure()
    plt.plot(t, res_mod.x)
    plt.title("IFFTした結果に搬送波をかけ合わせた結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plt.figure()
    plt.plot(t, res_demod.x_sync_detect)
    plt.title("受信信号に同期検波を行った結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plt.figure()
    plt.plot(t, res_demod.x_lpf)
    plt.title("ノイズ除去用ローパスフィルタをした結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plt.figure()
    plt.plot(res_demod.t_len_n, res_demod.x_quant)
    plt.title("量子化と標本化を行った結果")
    plt.xlabel("時間[s]")
    plt.ylabel("振幅")

    plot_f = np.fft.fftshift(res_demod.f)
    plot_X = np.fft.fftshift(res_demod.X.real)

    plt.figure()
    plt.plot(plot_f, plot_X)
    plt.title("受信信号をFFTした結果")
    plt.xlabel("周波数[Hz]")
    plt.ylabel("振幅")

    plt.show()


def multi_symbol(
    SYMBOL_NUMBER: int,
    shift: NDArray[np.int32] = np.array([], dtype=np.int32),
    original_data: NDArray[np.int32] = np.array([], dtype=np.int32),
) -> Tuple[Modulation.Result, Demodulation.Result, Synchronization.Result]:
    if len(shift) == 0:
        shift = np.random.randint(0, 255, size=SYMBOL_NUMBER // 10, dtype=np.int32)
    if len(original_data) == 0:
        original_data = np.zeros((SYMBOL_NUMBER // 10, 12), dtype=np.int32)
        for i in range(len(original_data)):
            original_data[i] = np.concatenate(
                ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
                dtype=np.int32,
            )
    print("original_data")
    print(original_data)
    print("shift")
    print(shift)

    SHIFT_CNT: int = 5

    mod = Modulation()
    demod = Demodulation()
    sync = Synchronization()
    res_mod: Modulation.Result
    res_demod: Demodulation.Result
    res_sync: Synchronization.Result

    x = np.array([], dtype=np.float64)
    for i in range(len(original_data)):
        res_mod = mod.calculate_no_carrier(original_data[i])
        ifft_x = res_mod.ifft_x
        dt = 1 / SAMPLING_FREQUENCY
        _x = np.zeros(shift[i] + 10 * N, dtype=np.float64)
        for j in range(10 * N):
            if j >= 9 * N:
                _x[j + shift[i]] = 0
            else:
                _x[j + shift[i]] = ifft_x[j % N]
        x = np.concatenate((x, _x))
    # 扱いやすいように長さをNの倍数にする
    x = np.concatenate((x, np.zeros((N - (len(x) % N) % N))))
    # 末尾に0を追加
    x = np.concatenate((x, np.zeros(sync.BUFFER_LENGTH - N)))
    assert len(x) % N == 0
    assert len(x) >= sync.BUFFER_LENGTH

    def demodulete_process(x_split: NDArray[np.float64]) -> bool:
        nonlocal res_demod, res_sync
        res_sync = sync.calculate(x_split)
        signal_index = res_sync.signal_index
        if len(signal_index) == 0:
            return False

        print("signal index = ", signal_index)
        # 復調
        demod_t = np.arange(N) * dt
        demod_x = np.zeros(N, dtype=np.float64)
        for i in range(len(signal_index)):
            for shift_cnt in range(-SHIFT_CNT, SHIFT_CNT):
                print(f"shift_cnt = {shift_cnt}")
                if (
                    signal_index[i] - shift_cnt < 0
                    or signal_index[i] - shift_cnt + N - 1 >= sync.BUFFER_LENGTH
                ):
                    continue
                for j in range(N):
                    demod_x[j] = x_split[signal_index[i] + j - shift_cnt]
                res_demod = demod.calculate_no_carrier(demod_t, demod_x)
                ans_data = res_demod.data
                if res_demod.is_success == True:
                    if shift_cnt != 0:
                        sync.set_offset(shift_cnt)
                    break
        sync.set_failed_count(int(res_demod.is_success == False))
        return res_demod.is_success

    # Nずつシフトして、demodulete_processを実行
    success_cnt: int = 0
    for i in range(0, len(x) - sync.BUFFER_LENGTH, N):
        print(f"cnt = {i // N}, {i}, {sync.BUFFER_LENGTH + i}")
        is_success = demodulete_process(x[i : sync.BUFFER_LENGTH + i])
        print(is_success)
        if is_success and success_cnt // 9 < len(original_data):
            print(res_demod.data)
            npt.assert_equal(res_demod.data, original_data[success_cnt // 9])
        success_cnt += int(is_success)
    print(f"success_cnt = {success_cnt}")
    assert (
        success_cnt == SYMBOL_NUMBER - SYMBOL_NUMBER // 10
    ), f"success_cnt = {success_cnt}, expected_cnt = {SYMBOL_NUMBER - SYMBOL_NUMBER // 10}"
    print("ok")
    return res_mod, res_demod, res_sync


def plot_multi_symbol(res_sync: Synchronization.Result) -> None:
    index = res_sync.index
    R = res_sync.R
    plt.figure()
    plt.plot(index, R)
    plt.show()
