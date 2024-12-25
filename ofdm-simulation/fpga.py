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
        # print(f"{res[i]:04x}, {x[i]:.6f}")

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


def output_fft_sram(N: int, _re: NDArray[np.float64], _im: NDArray[np.float64]) -> None:
    N2: int = N // 2
    N4: int = N // 4
    # reverse
    re = bit_reverse(_re)
    im = bit_reverse(_im)
    # output
    s: str = ""
    for fft_cnt in range(2):
        s += f"// fft{fft_cnt}\n"
        for sp_cnt in range(4):
            for i in range(64):
                s += f"defparam sp_inst_{sp_cnt:1d}.INIT_RAM_{(i):02X} = 256'h"
                for j in range(32):
                    index = 32 * i + 31 - j
                    if fft_cnt == 1:
                        index += N2
                    if fft_cnt == 0 and index >= N2:
                        s += f"00"
                    elif fft_cnt == 1 and index >= N:
                        s += f"00"
                    else:
                        if sp_cnt == 0:
                            s += f"{float_to_fixed_q15(im[index]) & 0xff:02X}"
                        elif sp_cnt == 1:
                            s += f"{float_to_fixed_q15(im[index]) >> 8:02X}"
                        elif sp_cnt == 2:
                            s += f"{float_to_fixed_q15(re[index]) & 0xff:02X}"
                        else:
                            s += f"{float_to_fixed_q15(re[index]) >> 8:02X}"
                s += ";\n"
    print(s)


def output_fft1024() -> None:
    N: int = 1024
    output_fft_sram(
        N,
        np.array([-1 / (2 * N)] * N, dtype=np.float64),
        np.array([0] * N, dtype=np.float64),
    )
    # re = np.zeros(N, dtype=np.float64)
    # im = np.zeros(N, dtype=np.float64)
    # re[0] = -0.5
    # re = np.zeros(N, dtype=np.float64)
    # im = np.zeros(N, dtype=np.float64)
    # re[0] = 1 / 3
    # im[0] = -0.5
    # output_fft_sram(N, re, im)


def read_fft(N: int) -> None:
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

    for i in range(N):
        print(X[i])


def read_fft1024() -> None:
    read_fft(1024)
