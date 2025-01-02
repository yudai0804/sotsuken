from typing import Any


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


def fixed_q15_to_float(x: int) -> float:
    res: float = 0
    sign: int = 0
    if x & 0x8000:
        sign = 1
        x = (~x + 1) & 0xFFFF
    for i in range(16):
        if x & (1 << 15 - i):
            res += 2**-i
    if sign:
        res *= -1
    return res


def fixed_q15_quantization(x: float) -> float:
    return fixed_q15_to_float(float_to_fixed_q15(x))


def fixed_q15_quantization_complex(x: complex) -> complex:
    return fixed_q15_quantization(x.real) + 1j * fixed_q15_quantization(x.imag)


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
