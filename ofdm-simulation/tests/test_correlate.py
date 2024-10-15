import pytest
import correlate
import numpy as np
import numpy.testing as npt
import scipy.signal
import random
import subprocess
from numpy.typing import NDArray
from typing import Any, List, Tuple

##### correlate #####


def test_correlate1() -> None:
    # 最もシンプルなテスト、手計算も可能
    x = np.array([1, 2, 3, 4], dtype=np.complex128)
    y = np.array([3, 4, 5, 6], dtype=np.complex128)
    assert len(x) == len(y)
    expected: NDArray[np.complex128] = scipy.signal.correlate(x, y)
    result: NDArray[np.complex128] = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate2() -> None:
    # len(x) == len(y)のテスト
    N = random.randint(4, 256)
    x: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    y: NDArray[np.complex128] = np.random.rand(N) + 1j * np.random.rand(N)
    assert len(x) == len(y)
    expected: NDArray[np.complex128] = scipy.signal.correlate(x, y)
    result: NDArray[np.complex128] = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate3() -> None:
    # len(x) < len(y)のテスト
    Nx = random.randint(4, 100)
    Ny = random.randint(200, 300)
    x: NDArray[np.complex128] = np.random.rand(Nx) + 1j * np.random.rand(Nx)
    y: NDArray[np.complex128] = np.random.rand(Ny) + 1j * np.random.rand(Ny)
    assert len(x) < len(y)
    expected: NDArray[np.complex128] = scipy.signal.correlate(x, y)
    result: NDArray[np.complex128] = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate4() -> None:
    # len(x) > len(y)のテスト
    Nx = random.randint(200, 300)
    Ny = random.randint(4, 100)
    x: NDArray[np.complex128] = np.random.rand(Nx) + 1j * np.random.rand(Nx)
    y: NDArray[np.complex128] = np.random.rand(Ny) + 1j * np.random.rand(Ny)
    assert len(x) > len(y)
    expected: NDArray[np.complex128] = scipy.signal.correlate(x, y)
    result: NDArray[np.complex128] = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


##### xcorr #####


def test_check_available_octave() -> None:
    result = subprocess.run("octave", capture_output=True, text=True, input="1 + 1")
    expected: str = "ans = 2\n"
    assert result.stdout == expected


def octave_xcorr(
    x: NDArray[np.complex128], y: NDArray[np.complex128]
) -> NDArray[np.complex128]:
    input: str = "clear\n"
    input += "pkg load signal\n"
    input += "a=xcorr(["
    for i in range(len(x)):
        input += f"{x[i].real}+{x[i].imag}i"
        if i != len(x) - 1:
            input += ","
    input += "],["
    for i in range(len(y)):
        input += f"{y[i].real}+{y[i].imag}i"
        if i != len(y) - 1:
            input += ","
    input += "]);\n"
    input += "for i=1:length(a)\n"
    input += '\tfprintf("%+.10f%+.10fj\\n",real(a(i)),imag(a(i)))\n'
    input += "end\n"
    result = subprocess.run("octave", capture_output=True, text=True, input=input)
    assert result.returncode == 0
    list_data = result.stdout.split("\n")
    # 末尾のゴミを削除
    list_data.remove("")
    ans = np.array(list_data, dtype=np.complex128)
    return ans


def test_xcorr1() -> None:
    x = np.array([1, 2, 3, 4], dtype=np.complex128)
    y = np.array([3, 4, 5, 6], dtype=np.complex128)
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr2() -> None:
    # len(x) == len(y)のテスト
    N = random.randint(4, 256)
    x = np.random.rand(N) + 1j * np.random.rand(N)
    y = np.random.rand(N) + 1j * np.random.rand(N)
    assert len(x) == len(y)
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr3() -> None:
    # len(x) < len(y)のテスト
    Nx = random.randint(4, 100)
    Ny = random.randint(200, 300)
    x = np.random.rand(Nx) + 1j * np.random.rand(Nx)
    y = np.random.rand(Ny) + 1j * np.random.rand(Ny)
    assert len(x) < len(y)
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr4() -> None:
    # len(x) > len(y)のテスト
    Nx = random.randint(200, 300)
    Ny = random.randint(4, 100)
    x = np.random.rand(Nx) + 1j * np.random.rand(Nx)
    y = np.random.rand(Ny) + 1j * np.random.rand(Ny)
    assert len(x) > len(y)
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)
