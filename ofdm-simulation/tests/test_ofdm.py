import pytest
from ofdm import *
import numpy as np
import numpy.testing as npt
from numpy.typing import NDArray
from typing import Any, List, Tuple
from pydantic import BaseModel, ConfigDict
import random


@pytest.mark.parametrize(
    ("is_no_carrier"),
    [(False), (True)],
)
def test_single_signal(is_no_carrier: bool) -> None:
    original_data = np.concatenate(
        ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
        dtype=np.int32,
    )

    mod = Modulation()
    res_mod = mod.calculate(original_data)
    t = res_mod.t
    x = res_mod.x
    ifft_t = res_mod.ifft_t
    ifft_x = res_mod.ifft_x
    demod = Demodulation()
    ans_data = np.array([], dtype=np.int32)

    if is_no_carrier:
        res_demod = demod.calculate_no_carrier(ifft_t, ifft_x)
        ans_data = res_demod.data
    else:
        res_demod = demod.calculate(t, x)
        ans_data = res_demod.data

    assert res_demod.is_success == True
    npt.assert_equal(original_data, ans_data)


def test_multi_signal() -> None:
    original_data = np.concatenate(
        ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
        dtype=np.int32,
    )

    print(original_data)
    mod = Modulation()
    res_mod = mod.calculate_no_carrier(original_data)
    ifft_t = res_mod.ifft_t
    ifft_x = res_mod.ifft_x
    t16 = np.zeros(len(ifft_t) * 16)
    x16 = np.zeros(len(ifft_x) * 16, dtype=np.float64)
    dt = 1 / SAMPLING_FREQUENCY
    for i in range(len(t16)):
        t16[i] = i * dt
        x16[i] = ifft_x[i % N]
    for i in range(N):
        x16[9 * N + i] = 0
    tmp = np.zeros(len(x16), dtype=np.float64)
    # shift
    shift = random.randint(0, 10 * N)
    print("shift = ", shift)
    x16 = np.pad(x16, (shift, 0))[0 : len(x16)]
    sync = Synchronization()
    res_sync = sync.calculate(x16)
    signal_index = res_sync.signal_index

    assert sync.is_detect_signal() == True, "no signal"
    print("signal index = ", signal_index)
    # 復調
    demod = Demodulation()
    SHIFT: int = 10
    shift_cnt: int = 0
    demod_t = np.arange(N) * dt
    demod_x = np.zeros(N, dtype=np.float64)
    for i in range(len(signal_index)):
        # 信号が見当たらない場合はオフセットがずれている可能性があるので、少しシフトしてもう一度復調する。
        if signal_index[i] - (SHIFT - 1) + N - 1 >= sync.BUFFER_LENGTH:
            break
        for shift_cnt in range(SHIFT):
            if signal_index[i] - shift_cnt + N - 1 >= sync.BUFFER_LENGTH:
                break
            for j in range(N):
                demod_x[j] = x16[signal_index[i] + j - shift_cnt]
            res_demod = demod.calculate_no_carrier(demod_t, demod_x)
            if res_demod.is_success:
                break
        print("ans", res_demod.data)
        npt.assert_equal(original_data, res_demod.data)


def test_multi_signal_endurance() -> None:
    for i in range(1000):
        print("cnt = ", i)
        test_multi_signal()
