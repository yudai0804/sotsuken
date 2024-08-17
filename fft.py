import numpy as np
import cmath
import math

N = 256


def dft(x):
    X = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        for j in range(N):
            X[i] += x[j] * np.exp(-2j * np.pi * i * j / N)
    return X


def fft_recursion(x):
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
    w = 1.0
    # for文の中でw = np.exp(-2j * np.pi * i / N)を計算する方法でも可。
    # i回足し合わせるので結果は同じ
    for i in range(N // 2):
        # w = np.exp(-2j * np.pi * i / N)
        x[i] = even[i] + w * odd[i]
        x[i + N // 2] = even[i] - w * odd[i]
        w *= np.exp(-2j * np.pi / N)
    return x


def my_bit_reverse(x):
    y = [0] * len(x)
    msb = 0
    for i in range(len(x)):
        for j in range(32):
            if x[i] & (0x01 << j):
                msb = max(msb, j)
    msb += 1
    """
    for i in range(len(x)):
        for j in range(msb):
            if x[i] & (0x01 << j):
                y[i] |= 1 << (msb - 1 - j)
    """
    # """
    for i in range(len(x)):
        for j in range(msb):
            y[i] |= ((x[i] & (0x01 << j)) >> j) << (msb - 1 - j)
    # """
    return y


def my_fft(_x):
    # TODO: 要素数が2^N出なかった場合でも動くようにする
    # logを使う実装だと、FPGAに移植するときに都合が悪いので他のアルゴリズムにする。
    """
    非再帰FFT
    """
    # 参照渡しになってしまうと扱いにくいのでコピー
    x = _x.copy()
    # reverse
    bit: int = int(math.log2(len(x)))
    for i in range(len(x)):
        k = 0
        for j in range(bit):
            k |= ((i & (0x01 << j)) >> j) << (bit - 1 - j)
        if i < k:
            # swap
            x[i], x[k] = x[k], x[i]

    # fft
    step = 1
    while step < N:
        half_step = step
        step = step * 2
        w_step = cmath.exp(-2j * math.pi / step)
        for k in range(0, N, step):
            w = 1
            for j in range(half_step):
                t = w * x[k + j + half_step]
                u = x[k + j]
                x[k + j] = u + t
                x[k + j + half_step] = u - t
                w *= w_step

    return x


def my_ifft(_X: np.ndarray):
    # TODO: 要素数が2^N出なかった場合でも動くようにする
    X = _X.copy()
    for i in range(N):
        X[i] = X[i].conj()
    ans = my_fft(X)
    for i in range(N):
        ans[i] /= N
        ans[i] = ans[i].conj()
    return ans


if __name__ == "__main__":

    import random

    a = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        a[i] = random.random() + 1j * random.random()

    b = np.fft.fft(a, N)
    c = my_fft(np.array(a, dtype=np.complex128))
    print("fft")
    for i in range(N):
        print(f"i = {i}, numpy_fft = {b[i]:.3f}, my_fft = {c[i]:.3f}")
        assert abs(b[i] - c[i]) <= 1e-10

    d = np.fft.ifft(a, N)
    e = my_ifft(np.array(a, dtype=np.complex128))
    print("ifft")
    for i in range(N):
        print(f"i = {i}, numpy_ifft = {d[i]:.3f}, my_ifft = {e[i]:.3f}")
        assert abs(d[i] - e[i]) <= 1e-10
