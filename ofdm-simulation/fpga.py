from typing import Any, List, Tuple

import numpy as np
from numpy.typing import NDArray
from util_binary import bit_reverse, fixed_q15_to_float, float_to_fixed_q15


def output_twinddle_factor() -> None:
    # フォーマットはQ1.15に対応(符号1bit、小数部15ビット)
    N: int = 4096
    N4 = N // 4

    # 実際の要素数は1024ではなく、1025なので、別途いい感じにして上げる

    t = np.arange(N4 + 1, dtype=np.int32)
    x = np.sin(np.pi / 2 / N4 * t)
    res = np.zeros(len(t), dtype=np.int32)
    for i in range(len(x)):
        res[i] = float_to_fixed_q15(x[i])

    s: str = ""
    for i in range(64):
        s += f"defparam prom_inst_0.INIT_RAM_{i:02X} = 256'h"
        for j in range(16):
            if 16 * i + 15 - j >= N4:
                s += f"0000"
            else:
                s += f"{res[16 * i + 15 - j]:04X}"
        s += ";\n"
    print(s)


def output_fft_sram(N: int, _x: NDArray[np.complex128]) -> Tuple[str, str]:
    N2: int = N // 2
    N4: int = N // 4
    # reverse
    re = bit_reverse(_x.real)
    im = bit_reverse(_x.imag)
    # output
    s = [""] * 2
    for cnt in range(2):
        s[cnt] += f"// fft{cnt}\n"
        for sp_cnt in range(4):
            for i in range(64):
                s[cnt] += f"defparam sp_inst_{sp_cnt:1d}.INIT_RAM_{(i):02X} = 256'h"
                for j in range(32):
                    index = 32 * i + 31 - j
                    if cnt == 1:
                        index += N2
                    if cnt == 0 and index >= N2:
                        s[cnt] += f"00"
                    elif cnt == 1 and index >= N:
                        s[cnt] += f"00"
                    else:
                        if sp_cnt == 0:
                            s[cnt] += f"{float_to_fixed_q15(im[index]) & 0xff:02X}"
                        elif sp_cnt == 1:
                            s[cnt] += f"{float_to_fixed_q15(im[index]) >> 8:02X}"
                        elif sp_cnt == 2:
                            s[cnt] += f"{float_to_fixed_q15(re[index]) & 0xff:02X}"
                        else:
                            s[cnt] += f"{float_to_fixed_q15(re[index]) >> 8:02X}"
                s[cnt] += ";\n"
    return s[0], s[1]


def output_fft1024() -> None:
    N: int = 1024
    x = np.zeros(N, dtype=np.complex128)
    x[0] = 0.5
    s0, s1 = output_fft_sram(N, x)
    print(s0)
    print(s1)


def read_fft(N: int) -> NDArray[np.complex128]:
    Xq_re = np.zeros(N, dtype=np.int32)
    Xq_im = np.zeros(N, dtype=np.int32)
    X = np.zeros(N, dtype=np.complex128)
    # 最初はゴミなので無視
    # ゴミの内容
    # VCD info: dumpfile testbench.vcd opened for output.
    _ = input()
    for i in range(N):
        x_str = input().replace(" ", "")
        assert x_str.isdigit() == True
        x_int = int(x_str)
        Xq_re[i] = x_int >> 16
        Xq_im[i] = x_int & 0xFFFF

    for i in range(N):
        X[i] = fixed_q15_to_float(Xq_re[i]) + 1j * fixed_q15_to_float(Xq_im[i])

    return X


def read_fft1024() -> None:
    X = read_fft(1024)
    for i in range(len(X)):
        print(X[i])
