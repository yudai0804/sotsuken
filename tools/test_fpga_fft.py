from typing import Any

import matplotlib.pyplot as plt
import numpy as np
from numpy.typing import NDArray


def float_to_fixed_q15(x: float) -> int:
    sign: int = 0
    if x < 0:
        sign = 1
    _x = abs(x)
    scale = 2**15
    res: int = int(round(scale * _x))
    if sign:
        if res > 2**15:
            res = 2**15
        return (~res + 1) & 0xFFFF
    else:
        if res > 2**15 - 1:
            res = 2**15 - 1
        return res


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


def bit_reverse(x: Any) -> Any:
    x = x.copy()
    N = len(x)
    assert check_is_pow2(N) == True

    bit: int = log2_int(N)
    for i in range(N):
        k: int = 0
        for j in range(bit):
            k |= ((i & (0x01 << j)) >> j) << (bit - 1 - j)
        if i < k:
            # swap
            x[i], x[k] = x[k], x[i]
    return x


def write(N, _re: NDArray[np.float64], _im: NDArray[np.float64]) -> None:
    N2: int = N // 2
    N4: int = N // 4
    t = np.arange(N, dtype=np.int32)
    t = np.fft.fftshift(t)
    # reverse
    re = bit_reverse(_re)
    im = bit_reverse(_im)
    # output
    for cnt in range(4):
        s: str = ""
        for i in range(64):
            s += f"defparam sp_inst_{cnt:1d}.INIT_RAM_{(i):02x} = 256'h"
            for j in range(32):
                index = 32 * i + 31 - j
                if index >= N:
                    s += f"00"
                else:
                    if cnt == 0:
                        s += f"{float_to_fixed_q15(im[index]) & 0xff:02x}"
                    elif cnt == 1:
                        s += f"{float_to_fixed_q15(im[index]) >> 8:02x}"
                    elif cnt == 2:
                        s += f"{float_to_fixed_q15(re[index]) & 0xff:02x}"
                    else:
                        s += f"{float_to_fixed_q15(re[index]) >> 8:02x}"
            s += ";\n"
        print(s)


N: int = 1024
write(N, np.array([1 / N] * N, dtype=np.float64), [0] * N)

# N: int = 16
# x = np.arange(N, dtype=np.int32)
# y = bit_reverse(x)
# for i in range(N):
# print(x[i], y[i])
# print(f"{x[i]:02d}({x[i]:04b}), {y[i]:02d}({y[i]:04b})")


# X = np.fft.fft(x)
# plt.figure()
# plt.plot(np.arange(N, dtype=np.int32), np.fft.fftshift(X.real))
# plt.show()
