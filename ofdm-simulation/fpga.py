import numpy as np
from numpy.typing import NDArray
from util_binary import bit_reverse, float_to_fixed_q15


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
        # print(f"{res[i]:04x}, {x[i]:.6f}")

    s: str = ""
    for i in range(64):
        s += f"defparam prom_inst_0.INIT_RAM_{i:02x} = 256'h"
        for j in range(16):
            if 16 * i + 15 - j >= N4:
                s += f"0000"
            else:
                s += f"{res[16 * i + 15 - j]:04x}"
        s += ";\n"
    print(s)


def output_fft_sram(N, _re: NDArray[np.float64], _im: NDArray[np.float64]) -> None:
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


def output_fft1024() -> None:
    N: int = 1024
    output_fft_sram(
        N, np.array([1 / N] * N, dtype=np.float64), np.array([0] * N, dtype=np.float64)
    )
