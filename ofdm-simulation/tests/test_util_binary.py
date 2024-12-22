import random
from typing import Any, List, Tuple

import numpy as np
import numpy.testing as npt
import pytest
from numpy.typing import NDArray
from util_binary import *


def test_fixed_q15_random() -> None:
    N: int = 256
    expected = np.random.uniform(low=-1, high=1 - 2**-15, size=N)
    result = np.zeros(N, dtype=np.float64)
    for i in range(N):
        result[i] = fixed_q15_to_float(float_to_fixed_q15(expected[i]))
    # 一度固定小数点に変換している都合上、10**-5程度の誤差が発生してしまう
    npt.assert_almost_equal(expected, result, decimal=4)


def test_float_to_fixed_q15() -> None:
    N: int = 5
    x = np.array([1 - 2**-15, 2**-15, 0, -(2**-15), -1], dtype=np.float64)
    expected = np.array([0x7FFF, 0x0001, 0x0000, 0xFFFF, 0x8000], dtype=np.int32)
    result = np.zeros(N, dtype=np.int32)
    for i in range(N):
        result[i] = float_to_fixed_q15(x[i])
    npt.assert_equal(expected, result)


def test_fixed_q15_to_float() -> None:
    N: int = 5
    x = np.array([0x7FFF, 0x0001, 0x0000, 0xFFFF, 0x8000], dtype=np.int32)
    expected = np.array([1 - 2**-15, 2**-15, 0, -(2**-15), -1], dtype=np.float64)
    result = np.zeros(N, dtype=np.float64)
    for i in range(N):
        result[i] = fixed_q15_to_float(x[i])
    npt.assert_almost_equal(expected, result, decimal=10)


def test_check_is_pow2() -> None:
    N: int = 10
    x = np.array([-1, 0, 1, 2, 3, 4, 5, 6, 7, 8], dtype=np.int32)
    expected = np.array([0, 0, 1, 1, 0, 1, 0, 0, 0, 1], dtype=np.int32)
    result = np.zeros(N, dtype=np.int32)
    for i in range(N):
        result[i] = check_is_pow2(x[i])
    npt.assert_equal(expected, result)


def test_log2_int() -> None:
    N: int = 4
    x = np.array([1, 2, 4, 8], dtype=np.int32)
    expected = np.array([0, 1, 2, 3], dtype=np.int32)
    result = np.zeros(N, dtype=np.int32)
    for i in range(N):
        result[i] = log2_int(x[i])
    npt.assert_equal(expected, result)


def test_bit_reverse() -> None:
    N: int = 8
    x = np.array([0, 1, 2, 3, 4, 5, 6, 7], dtype=np.int32)
    expected = np.array([0, 4, 2, 6, 1, 5, 3, 7], dtype=np.int32)
    result: NDArray[np.int32] = bit_reverse(x)
    npt.assert_equal(expected, result)
