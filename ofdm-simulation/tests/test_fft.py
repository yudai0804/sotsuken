import pytest
import fft
import numpy as np
import numpy.testing as npt
import random

def test_fft():
    N = 256
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = np.fft.fft(x)
    result = fft.fft(x)
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)

def test_ifft():
    N = 256
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = np.fft.ifft(x)
    result = fft.ifft(x)
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)

def test_fft_and_ifft():
    # 時間領域->周波数領域->時間領域ができているか確認
    # (FFTしたものをIFFTする)
    N = 256
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = x
    result = fft.ifft(fft.fft(x))
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)

def test_dft_pow2():
    N = 256
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = np.fft.fft(x)
    result = fft.dft(x)
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)

def test_dft_not_pow2():
    N = random.randint(100,300)
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = np.fft.fft(x)
    result = fft.dft(x)
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)

def test_fft_recursion():
    N = 256
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = random.random() + 1j * random.random()
    expected = np.fft.fft(x)
    result = fft.fft_recursion(x)
    assert len(expected) == len(result)
    npt.assert_almost_equal(expected, result)