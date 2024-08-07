import numpy as np
import cmath
import math
import fft_test

N = 256


def ifft1(X: np.ndarray):
    return np.fft.ifft(X, N)


def ifft2(X: np.ndarray):
    for i in range(N):
        X[i] = X[i].conj()
    ans = np.fft.fft(X, N)
    for i in range(N):
        ans[i] /= N
        ans[i] = ans[i].conj()
    return ans


def fft_recursion(x):
    N = len(x)
    if N == 1:
        return x
    even = np.zeros(N // 2, dtype=np.complex128)
    odd = np.zeros(N // 2, dtype=np.complex128)
    for i in range(N // 2):
        even[i] = x[i * 2]
        odd[i] = x[i * 2 + 1]
    even = fft_recursion(even)
    odd = fft_recursion(odd)
    w = 1.0  # expの指数にマイナスは多分必要

    for i in range(N // 2):
        x[i] = even[i] + w * odd[i]
        x[i + N // 2] = even[i] - w * odd[i]
        w *= np.exp(-2j * np.pi / N)
    return x


def dft(x):
    X = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        for j in range(N):
            X[i] += x[j] * np.exp(-2j * np.pi * i * j / N)
    return X


import random

a = np.zeros(N, dtype=np.complex128)
for i in range(N):
    a[i] = random.random() + 1j * random.random()

# a = np.sin(np.arange(N))

b = np.fft.fft(a, N)
# b = np.fft.fftshift(b)
# b = change_numpy_fft_array(b)
c = fft_recursion(np.array(a, dtype=np.complex128))
d = fft_test.fft(a, N)
# c = np.fft.fftshift(c)
e = dft(a)
for i in range(N):
    print(f"i = {i}, b = {b[i]:.3f}, c = {c[i]:.3f}, d = {d[i]:.3f}, e = {e[i]:.3f}")
# assert abs(b[i] - c[i]) <= 1e-10
