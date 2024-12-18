import cmath
import math
from typing import Any, List, Tuple

import numpy as np
from numpy.typing import NDArray


def dft(x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    N = len(x)
    X = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        for j in range(N):
            X[i] += x[j] * np.exp(-2j * np.pi * i * j / N)
    return X


def check_is_pow2(x: int) -> bool:
    i: int = 1
    while i < x:
        i *= 2
    return i == x


def log2_int(x: int) -> int:
    assert check_is_pow2(x) == True
    ans: int = 0
    while x // 2 != 0:
        x = x // 2
        ans += 1
    return ans


def fft_recursion(x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    """
    FFT再帰
    """
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
    w: complex = 1.0
    # for文の中でw = np.exp(-2j * np.pi * i / N)を計算する方法でも可。
    # i回足し合わせるので結果は同じ
    for i in range(N // 2):
        # w = np.exp(-2j * np.pi * i / N)
        x[i] = even[i] + w * odd[i]
        x[i + N // 2] = even[i] - w * odd[i]
        w *= np.exp(-2j * np.pi / N)
    return x


def fft(_x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    """
    非再帰FFT(時間間引き)
    """
    # 参照渡しになってしまうと扱いにくいのでコピー
    x = _x.copy()
    N = len(x)
    assert check_is_pow2(N) == True

    # reverse
    bit: int = log2_int(N)
    for i in range(N):
        k: int = 0
        for j in range(bit):
            k |= ((i & (0x01 << j)) >> j) << (bit - 1 - j)
        if i < k:
            # swap
            x[i], x[k] = x[k], x[i]

    # fft
    step: int = 1
    while step < N:
        half_step: int = step
        step = step * 2
        w_step: complex = cmath.exp(-2j * math.pi / step)
        for k in range(0, N, step):
            w: complex = 1
            for j in range(half_step):
                u: complex = x[k + j]
                t: complex = w * x[k + j + half_step]
                x[k + j] = u + t
                x[k + j + half_step] = u - t
                w *= w_step

    return x


def fft_fpga(_x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    """
    非再帰FFT(時間間引き)
    FPGAの実装練習用
    アルゴリズムをFPGA向けにしている。
    回転因子は長さ N / 4 + 1のsinテーブルから計算可能
    """
    # 参照渡しになってしまうと扱いにくいのでコピー
    x = _x.copy()
    N = len(x)
    assert check_is_pow2(N) == True

    # reverse
    bit: int = log2_int(N)
    for i in range(N):
        k: int = 0
        for j in range(bit):
            k |= ((i & (0x01 << j)) >> j) << (bit - 1 - j)
        if i < k:
            # swap
            x[i], x[k] = x[k], x[i]

    # fft
    step: int = 1
    index: int = N
    sin_table = np.sin(2 * np.pi / N * np.arange(N // 4 + 1))
    N4 = N // 4

    while step < N:
        half_step: int = step
        step = step * 2
        index = index // 2
        for k in range(0, N, step):
            i: int = 0
            for j in range(half_step):
                # sin tableから回転因子を計算
                w: complex
                if 0 <= i <= N4:
                    # 第4象限
                    w = sin_table[N4 - i] - 1j * sin_table[i]
                elif N4 < i <= 2 * N4:
                    # 第3象限
                    w = -sin_table[i - N4] - 1j * sin_table[2 * N4 - i]
                elif 2 * N4 < i <= 3 * N4:
                    # 第2象限
                    w = -sin_table[3 * N4 - i] + 1j * sin_table[i - 2 * N4]
                elif 3 * N4 < i < N:
                    # 第1象限
                    w = sin_table[i - 3 * N4] + 1j * sin_table[4 * N4 - i]

                # バタフライ演算
                u: complex = x[k + j]
                t: complex = w * x[k + j + half_step]
                x[k + j] = u + t
                x[k + j + half_step] = u - t
                i += index
                i %= N

    return x


def ifft(_X: NDArray[np.complex128]) -> NDArray[np.complex128]:
    X = _X.copy()
    N = len(X)
    assert check_is_pow2(N) == True
    for i in range(N):
        X[i] = X[i].conj()
    ans = fft(X)
    for i in range(N):
        ans[i] /= N
        ans[i] = ans[i].conj()
    return ans
