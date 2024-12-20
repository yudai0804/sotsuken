import numpy as np

# フォーマットはQ1.15に対応(符号1bit、小数部15ビット)
N: int = 4096
N4 = N // 4

# 実際の要素数は1024ではなく、1025なので、別途いい感じにして上げる


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


t = np.arange(N4 + 1, dtype=np.int32)
x = np.sin(np.pi / 2 / N4 * t)
res = np.zeros(len(t), dtype=np.int32)
for i in range(len(x)):
    res[i] = float_to_fixed_q15(x[i])
    # print(f"{res[i]:04x}, {x[i]:.6f}")

s: str = ""
index: int = -1
for i in range(64):
    s += f"defparam prom_inst_0.INIT_RAM_{i:02x} = 256'h"
    for j in range(16):
        index += 1
        if index >= N4:
            s += f"0000"
        else:
            s += f"{res[index]:04x}"
    s += ";\n"
print(s)
