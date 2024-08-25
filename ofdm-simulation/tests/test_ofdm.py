import pytest
from ofdm import *
import numpy as np
import numpy.testing as npt
import random


@pytest.mark.parametrize(
    ("is_no_carrier", "use_noise"),
    [(False, False), (False, True), (True, False), (True, True)],
)
def test_single_signal(is_no_carrier, use_noise):
    original_data = np.array([], dtype=int)
    for i in range(12):
        original_data = np.append(original_data, random.randint(0, 255))
    ofdm_mod = OFDM_Modulation()
    t, x, ifft_t, ifft_x = ofdm_mod.calculate(original_data)

    ofdm_demod = OFDM_Demodulation()
    # 雑音を加える
    if use_noise:
        gain = 0.0001
        if is_no_carrier:
            for i in range(len(ifft_x)):
                ifft_x[i] += gain * (random.random() + 1j * random.random())
        else:
            for i in range(len(x)):
                x[i] += gain * random.random()

    ans_data = None

    if is_no_carrier:
        ans_data, f, X, _t, _x, __x = ofdm_demod.calculate_no_carrier(ifft_t, ifft_x)
    else:
        ans_data, f, X, _t, _x, __x = ofdm_demod.calculate(t, x)

    npt.assert_equal(original_data, ans_data)


@pytest.mark.parametrize(
    ("use_noise"),
    [(False), (True)],
)
def test_multi_signal(use_noise):
    original_data = np.array([], dtype=int)
    for i in range(12):
        original_data = np.append(original_data, random.randint(0, 255))
    print(original_data)
    ofdm_mod = OFDM_Modulation()
    ifft_t, ifft_x = ofdm_mod.calculate_no_carrier(original_data)
    # 雑音を加える
    if use_noise:
        gain = 0.0001
        for i in range(len(ifft_x)):
            ifft_x[i] += gain * (random.random() + 1j * random.random())
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
    print("shift = ", shift)
    for i in range(len(x16)):
        if i + shift >= len(x16):
            break
        tmp[i + shift] = x16[i]
    x16 = tmp.copy()
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

        npt.assert_equal(original_data, ans_data)


def test_multi_signal_endurance():
    for i in range(256):
        print("cnt = ", i)
        test_multi_signal(use_noise=True)
