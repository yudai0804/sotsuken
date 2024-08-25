import pytest
import correlate
import numpy as np
import numpy.testing as npt
import scipy.signal
import random
import subprocess

##### correlate #####


def test_correlate1():
    # 最もシンプルなテスト、手計算も可能
    x = np.array([1, 2, 3, 4], dtype=np.complex128)
    y = np.array([3, 4, 5, 6], dtype=np.complex128)
    assert len(x) == len(y)
    expected = scipy.signal.correlate(x, y)
    result = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate2():
    # len(x) == len(y)のテスト
    N = random.randint(4, 1024)
    x = np.zeros(N, dtype=np.complex128)
    y = np.zeros(N, dtype=np.complex128)
    assert len(x) == len(y)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
        y[i] = random.random() + 1j * random.random()
    expected = scipy.signal.correlate(x, y)
    result = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate3():
    # len(x) < len(y)のテスト
    Nx = random.randint(4, 100)
    Ny = random.randint(200, 300)
    x = np.zeros(Nx, dtype=np.complex128)
    y = np.zeros(Ny, dtype=np.complex128)
    assert len(x) < len(y)
    for i in range(Nx):
        x[i] = random.random() + 1j * random.random()
    for i in range(Ny):
        y[i] = random.random() + 1j * random.random()
    expected = scipy.signal.correlate(x, y)
    result = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


def test_correlate4():
    # len(x) > len(y)のテスト
    Nx = random.randint(200, 300)
    Ny = random.randint(4, 100)
    x = np.zeros(Nx, dtype=np.complex128)
    y = np.zeros(Ny, dtype=np.complex128)
    assert len(x) > len(y)
    for i in range(Nx):
        x[i] = random.random() + 1j * random.random()
    for i in range(Ny):
        y[i] = random.random() + 1j * random.random()
    expected = scipy.signal.correlate(x, y)
    result = correlate.correlate(x, y)
    npt.assert_almost_equal(expected, result)


##### xcorr #####


def test_check_available_octave():
    result = subprocess.run("octave", capture_output=True, text=True, input="1 + 1")
    expected = "ans = 2\n"
    assert result.stdout == expected


def octave_xcorr(x: np.ndarray, y: np.ndarray):
    input = "clear\n"
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


def test_xcorr1():
    x = np.array([1, 2, 3, 4], dtype=np.complex128)
    y = np.array([3, 4, 5, 6], dtype=np.complex128)
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr2():
    # len(x) == len(y)のテスト
    N = random.randint(4, 1024)
    x = np.zeros(N, dtype=np.complex128)
    y = np.zeros(N, dtype=np.complex128)
    assert len(x) == len(y)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
        y[i] = random.random() + 1j * random.random()
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr3():
    # len(x) < len(y)のテスト
    Nx = random.randint(4, 100)
    Ny = random.randint(200, 300)
    x = np.zeros(Nx, dtype=np.complex128)
    y = np.zeros(Ny, dtype=np.complex128)
    assert len(x) < len(y)
    for i in range(Nx):
        x[i] = random.random() + 1j * random.random()
    for i in range(Ny):
        y[i] = random.random() + 1j * random.random()
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)


def test_xcorr4():
    # len(x) > len(y)のテスト
    Nx = random.randint(200, 300)
    Ny = random.randint(4, 100)
    x = np.zeros(Nx, dtype=np.complex128)
    y = np.zeros(Ny, dtype=np.complex128)
    assert len(x) > len(y)
    for i in range(Nx):
        x[i] = random.random() + 1j * random.random()
    for i in range(Ny):
        y[i] = random.random() + 1j * random.random()
    expected = octave_xcorr(x, y)
    result, _ = correlate.xcorr(x, y)
    npt.assert_almost_equal(expected, result)
