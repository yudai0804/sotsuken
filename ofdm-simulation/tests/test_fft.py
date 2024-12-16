import random
from typing import Any, List, Tuple

import fft
import numpy as np
import numpy.testing as npt
import pytest
from numpy.typing import NDArray


def test_fft() -> None:
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.fft(x)
    result = fft.fft(x)
    npt.assert_almost_equal(expected, result)


def test_ifft() -> None:
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.ifft(x)
    result = fft.ifft(x)
    npt.assert_almost_equal(expected, result)


def test_fft_and_ifft() -> None:
    # 時間領域->周波数領域->時間領域ができているか確認
    # (FFTしたものをIFFTする)
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = x
    result = fft.ifft(fft.fft(x))
    npt.assert_almost_equal(expected, result)


def test_fft_fpga() -> None:
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.fft(x)
    result = fft.fft_fpga(x)
    npt.assert_almost_equal(expected, result)


def test_dft_pow2() -> None:
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.fft(x)
    result = fft.dft(x)
    npt.assert_almost_equal(expected, result)


def test_dft_not_pow2() -> None:
    N: int = random.randint(100, 300)
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.fft(x)
    result = fft.dft(x)
    npt.assert_almost_equal(expected, result)


def test_fft_recursion() -> None:
    N: int = 256
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    expected = np.fft.fft(x)
    result = fft.fft_recursion(x)
    npt.assert_almost_equal(expected, result)
