import numpy as np
import numpy.testing as npt
import pytest
from fpga import *
from numpy.typing import NDArray
from util_binary import fixed_q15_quantization_complex


def test_fft1024() -> None:
    N: int = 1024
    x = np.zeros(N, dtype=np.complex128)
    low: float = -0.01
    high: float = 0.01
    x = np.random.uniform(low, high, N) + 1j * np.random.uniform(low, high, N)
    # 乱数をそのまま与えると、64bit浮動小数点数と16bitの固定小数点数の有効数字に差が出てしまうため、
    # 乱数を一度固定小数点数に変換し、再度浮動小数点数に変換する
    for i in range(N):
        x[i] = fixed_q15_quantization_complex(x[i])

    expected: NDArray[np.complex128] = np.fft.fft(x)
    result: NDArray[np.complex128] = run_fft1024(x.copy())
    # decimal=3は調子がいいと通るが、安定しないのでdecimal=2
    npt.assert_almost_equal(expected, result, decimal=2)
