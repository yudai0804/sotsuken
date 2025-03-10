import os
import subprocess
import sys
from io import StringIO
from typing import Any, List, Tuple

import numpy as np
import numpy.testing as npt
from numpy.typing import NDArray
from util_binary import *


def run_fft1024(_x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    N: int = 1024
    # 出力する文字列を作成
    # ビット反転はoutput_fft_sramの中で行う
    s0, s1 = output_fft_sram(N, _x.copy())
    # ofdm-fpgaディレクトリに移動
    start_dir = os.getcwd()
    # 一度このファイルがあるディレクトリまで移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # ofdm-fpgaのあるディレクトリまで移動
    os.chdir("../ofdm-fpga")
    # ファイルに書き出す
    os.makedirs("tmp", exist_ok=True)
    with open("tmp/gowin_sp_fft0_defparam.v", "w") as file:
        print(s0, file=file)
    with open("tmp/gowin_sp_fft1_defparam.v", "w") as file:
        print(s1, file=file)
    # 実行
    # 本当は良くないけど、mypyがうまく動かないので、Any型でごまかす
    result: Any = subprocess.run(
        "iverilog -o testbench tb/tb_fft1024.v src/fft1024.v src/butterfly.v src/gowin/gowin_prom_w.v src/gowin/gowin_sp_fft0.v src/gowin/gowin_sp_fft1.v src/gowin/prim_sim.v -I tmp -DSIMULATOR",
        shell=True,
    )
    assert result.returncode == 0, "[Verilog] Bulid failed"
    result = subprocess.run("vvp testbench", shell=True, capture_output=True, text=True)
    assert result.returncode == 0, "[Verilog] error"
    # Assertで落ちていないかチェック
    assert ("ASSERTION FAILED" in result.stdout) == 0, "[Verilog] Assertion error"

    # 入力を切換
    mock_input = StringIO(result.stdout)
    sys.stdin = mock_input
    # 入力を処理
    X = read_fft(N)
    # 入力をもとに戻す
    sys.stdin = sys.__stdin__
    # 作業ディレクトリをもとの場所に移動
    os.chdir(start_dir)
    return X


def run_ofdm(_x: NDArray[np.complex128]) -> NDArray[np.int32]:
    N: int = 1024
    # 出力する文字列を作成
    # ビット反転はoutput_fft_sramの中で行う
    s0, s1 = output_fft_sram(N, _x.copy())
    # ofdm-fpgaディレクトリに移動
    start_dir = os.getcwd()
    # 一度このファイルがあるディレクトリまで移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # ofdm-fpgaのあるディレクトリまで移動
    os.chdir("../ofdm-fpga")
    # ファイルに書き出す
    os.makedirs("tmp", exist_ok=True)
    with open("tmp/gowin_sp_fft0_defparam.v", "w") as file:
        print(s0, file=file)
    with open("tmp/gowin_sp_fft1_defparam.v", "w") as file:
        print(s1, file=file)
    # 実行
    # 本当は良くないけど、mypyがうまく動かないので、Any型でごまかす
    result: Any = subprocess.run(
        "iverilog -o testbench tb/tb_ofdm.v src/ofdm.v src/fft1024.v src/butterfly.v src/gowin/gowin_prom_w.v src/gowin/gowin_sp_fft0.v src/gowin/gowin_sp_fft1.v src/gowin/prim_sim.v -I tmp -DSIMULATOR",
        shell=True,
    )
    assert result.returncode == 0, "[Verilog] Bulid failed"
    result = subprocess.run("vvp testbench", shell=True, capture_output=True, text=True)
    assert result.returncode == 0, "[Verilog] error"
    # Assertで落ちていないかチェック
    assert ("ASSERTION FAILED" in result.stdout) == 0, "[Verilog] Assertion error"

    # 入力を切換
    mock_input = StringIO(result.stdout)
    sys.stdin = mock_input
    ofdm_res = np.zeros(12, dtype=np.int32)
    # 入力を処理
    # 最初はゴミなので無視。内容は以下の通り。
    # VCD info: dumpfile testbench.vcd opened for output.
    _ = input()
    for i in range(12):
        x_str = input().replace(" ", "")
        assert x_str.isdigit() == True
        ofdm_res[i] = int(x_str)

    # 入力をもとに戻す
    sys.stdin = sys.__stdin__
    # 作業ディレクトリをもとの場所に移動
    os.chdir(start_dir)
    return ofdm_res


def run_demodulation(
    x: NDArray[np.float64], expected_X: NDArray[np.int32], res_len: int, delay: int
) -> NDArray[np.int32]:
    # 出力する文字列を作成
    s = (
        "`timescale 1ns / 1ps\n"
        "\n"
        f"// expected result: [0x{expected_X[0]:02X}, 0x{expected_X[1]:02X}, 0x{expected_X[2]:02X}, 0x{expected_X[3]:02X}, 0x{expected_X[4]:02X}, 0x{expected_X[5]:02X}, 0x{expected_X[6]:02X}, 0x{expected_X[7]:02X}, 0x{expected_X[8]:02X}, 0x{expected_X[9]:02X}, 0x{expected_X[10]:02X}, 0x{expected_X[11]:02X}]\n"
        "\n"
        "module testbench_adc_dout(\n"
        "    input adc_cs,\n"
        "    input adc_clk,\n"
        "    input rst_n,\n"
        "    output reg adc_dout\n"
        ");\n"
        "\n"
        "reg [31:0] i;\n"
        "reg [7:0] j;\n"
        "reg [3:0] cnt;\n"
        f"wire [{16 * len(x) - 1}:0] data;\n"
        "\n"
        "// adc_doutの処理\n"
        "always @(negedge adc_cs or negedge adc_clk or negedge rst_n) begin\n"
        "    if (!rst_n) begin\n"
        "        adc_dout <= 1'd0;\n"
        "        i <= 32'd0;\n"
        "        j <= 8'd0;\n"
        "        // 最初にカウントが進んでしまうので、それ対策\n"
        "        cnt <= 4'd0;\n"
        "    end\n"
        "    else begin\n"
        "        if (adc_cs == 1'd0 && j != 8'd9) begin\n"
        "            cnt <= cnt + 1'd1;\n"
        "            case (cnt)\n"
        "                4'd0, 4'd1, 4'd2, 4'd3, 4'd4: adc_dout <= 1'd0;\n"
        "                4'd5: adc_dout <= data[16 * i + 9];\n"
        "                4'd6: adc_dout <= data[16 * i + 8];\n"
        "                4'd7: adc_dout <= data[16 * i + 7];\n"
        "                4'd8: adc_dout <= data[16 * i + 6];\n"
        "                4'd9: adc_dout <= data[16 * i + 5];\n"
        "                4'd10: adc_dout <= data[16 * i + 4];\n"
        "                4'd11: adc_dout <= data[16 * i + 3];\n"
        "                4'd12: adc_dout <= data[16 * i + 2];\n"
        "                4'd13: adc_dout <= data[16 * i + 1];\n"
        "                4'd14: begin\n"
        "                    adc_dout <= data[16 * i + 0];\n"
        f"                    if (i != {len(x)} - 1) begin\n"
        "                        i <= i + 1'd1;\n"
        "                    end\n"
        "                    else begin\n"
        f"                        i <= 32'd{delay};\n"
        "                        j <= j + 1'd1;\n"
        "                    end\n"
        "                end\n"
        "            endcase\n"
        "        end\n"
        "        else begin\n"
        "            cnt <= 4'd0;\n"
        "        end\n"
        "    end\n"
        "end\n"
        "\n"
        "// デバッグ情報\n"
    )

    data = np.zeros(len(x), dtype=np.int32)
    for i in range(len(x)):
        _xq = float_to_fixed_q15(x[i])
        xq: int = 0
        if _xq & 0x200:
            xq = 512 - ((~_xq + 1) & 0x1FF)
        else:
            xq = (_xq & 0x1FF) + 512
        s += f"// i = {i}(0x{i:04X}), x / 4 = {x[i]}(fixed point: 0x{float_to_fixed_q15(x[i]):04X}), xq = {xq}(0x{xq:04X})\n"
        data[i] = xq

    s += f"assign data = {len(x) * 16}'h"
    for i in range(len(x) - 1, -1, -1):
        s += f"{data[i]:04X}"

    s += ";\n"
    s += "endmodule\n"

    # ofdm-fpgaディレクトリに移動
    start_dir = os.getcwd()
    # 一度このファイルがあるディレクトリまで移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # ofdm-fpgaのあるディレクトリまで移動
    os.chdir("../ofdm-fpga")
    # ファイルに書き出す
    os.makedirs("tmp", exist_ok=True)
    with open("tmp/testbench_adc_dout.v", "w") as file:
        print(s, file=file)

    command: str = (
        "iverilog -o testbench tb/tb_top.v"
        " src/top.v"
        " src/gowin/gowin_prom_w.v"
        " src/gowin/gowin_rpll.v"
        " src/gowin/gowin_sp_adc.v"
        " src/gowin/gowin_sp_fft0.v"
        " src/gowin/gowin_sp_fft1.v"
        " src/gowin/prim_sim.v"
        " src/butterfly.v"
        " src/demodulation.v"
        " src/fft1024.v"
        " src/led.v"
        " src/mcp3002.v"
        " src/ofdm.v"
        " src/uart_rx.v"
        " src/uart_tx.v"
        " tmp/testbench_adc_dout.v"
        " -DFAST_SIMULATION"
        " -DDEMOD_SIMULATION"
    )
    if res_len == 12:
        command += " -DSINGLE_SIMULATION"

    result: Any = subprocess.run(
        command,
        shell=True,
    )
    assert result.returncode == 0, "[Verilog] Bulid failed"
    result = subprocess.run("vvp testbench", shell=True, capture_output=True, text=True)
    assert result.returncode == 0, "[Verilog] error"
    print("finish")
    # Assertで落ちていないかチェック
    assert ("ASSERTION FAILED" in result.stdout) == 0, "[Verilog] Assertion error"
    # print(result.stdout)
    list_data = result.stdout.split("\n")
    # VCD info: dumpfile testbench.vcd opened for output.
    # と最後に改行があるので、全部でres_len + 2
    assert len(list_data) == res_len + 2, "Failed"
    ofdm_res = np.zeros(res_len, dtype=np.int32)
    for i in range(res_len):
        assert list_data[i + 1].replace(" ", "").isdigit() == True
        ofdm_res[i] = int(list_data[i + 1].replace(" ", ""))
    # 作業ディレクトリをもとの場所に移動
    os.chdir(start_dir)

    return ofdm_res


def output_butterfly_table() -> None:
    s = (
        "// x0 = x0 + x1 * w = (x0re + j * x0im) + ((x1re * wre - x1im * wim) + j(x1im * wre + x1re * wim)))\n"
        "// x1 = x0 - x1 * w = (x0re + j * x0im) - ((x1re * wre - x1im * wim) - j(x1im * wre + x1re * wim)))\n"
        "// x0re = x0re + x1re * wre - x1im * wim = x0re + A | x1re * wre | - B | x1im * wim | = x0re + A0 | x1re * wre | + B0 | x1im * wim |\n"
        "// x0im = x0im + x1im * wre + x1re * wim = x0im + C | x1im * wre | + D | x1re * wim | = x0im + C0 | x1im * wre | + D0 | x1re * wim |\n"
        "// x1re = x0re - x1re * wre + x1im * wim = x0re - A | x1re * wre | + B | x1im * wim | = x0re + A1 | x1re * wre | + B1 | x1im * wim |\n"
        "// x1im = x0im - x1im * wre - x1re * wim = x0im - C | x1im * wre | - D | x1re * wim | = x0im + C1 | x1im * wre | + D1 | x1re * wim |\n"
        "// A~Dは掛け算をしたときの符号(xorで求めることができる)\n"
        "// 符号は1のときはマイナス、0のときはプラス"
        "// A = sign(x1re * wre) = x1re ^ wre\n"
        "// B = sign(x1im * wim) = x1im ^ wim\n"
        "// C = sign(x1im * wre) = x1im ^ wre\n"
        "// D = sign(x1re * wim) = x1re ^ wim\n"
        "// A0~D0、A1~D1はA~Dとバタフライ演算のときに出てくる符号をかけ合わせたもの\n"
        "// A0 = A\n"
        "// B0 = ~B\n"
        "// C0 = C\n"
        "// D0 = D\n"
        "// A1 = ~A\n"
        "// B1 = B\n"
        "// C1 = ~C\n"
        "// D1 = ~D\n"
        "// |=======input=======|                                   |=========output========|\n"
        "// |x1re| wre|x1im| wim|x1re*wre|x1im*wim|x1im*wre|x1re*wim| x0re| x0im| x1re| x1im|\n"
        "// |    |    |    |    |    A   |    B   |    C   |    D   |A0|B0|C0|D0|A1|B1|C1|D1|\n"
        "// |-------------------------------------------------------------------------------|\n"
    )
    for i in range(16):
        x1re = 0
        wre = 0
        x1im = 0
        wim = 0
        if i & 0x08:
            x1re = 1
        if i & 0x04:
            wre = 1
        if i & 0x02:
            x1im = 1
        if i & 0x01:
            wim = 1
        A = x1re ^ wre
        B = x1im ^ wim
        C = x1im ^ wre
        D = x1re ^ wim
        A0 = A
        B0 = ~B & 0x01
        C0 = C
        D0 = D
        A1 = ~A & 0x01
        B1 = B
        C1 = ~C & 0x01
        D1 = ~D & 0x01
        s += f"// |  {x1re} |  {wre} |  {x1im} |  {wim} |    {A}   |    {B}   |    {C}   |    {D}   | {A0}| {B0}| {C0}| {D0}| {A1}| {B1}| {C1}| {D1}|\n"
        s += "// |-------------------------------------------------------------------------------|\n"
    print(s)


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
    """
    この関数の中でビット反転を行うので、事前に行う必要は不要
    """
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
    # 最初はゴミなので無視。内容は以下の通り。
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


def output_ofdm_spectrum() -> None:
    """
    OFDM実験用にFFTした結果を格納したデータを作る
    """
    # fpga.pyではシミュレーション(ofdm.py)と疎結合にするために、ofdm.pyをimportしないようにいているが
    # この関数の中では例外的にofdm.pyをimportする
    N: int = 1024
    from ofdm import SUBCARRIER_FREQUENCY_MAX_INDEX, single_symbol

    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    # output
    s = ""
    s += f"// fft0 output-ofdm-spectrum\n"
    s += f"// expected: [{original_data[0]}, {original_data[1]}, {original_data[2]}, {original_data[3]}, {original_data[4]}, {original_data[5]}, {original_data[6]}, {original_data[7]}, {original_data[8]}, {original_data[9]}, {original_data[10]}, {original_data[11]}]\n"
    for sp_cnt in range(4):
        for i in range(64):
            s += f"defparam sp_inst_{sp_cnt:1d}.INIT_RAM_{(i):02X} = 256'h"
            for j in range(32):
                index = 32 * i + 31 - j
                if index <= SUBCARRIER_FREQUENCY_MAX_INDEX:
                    if sp_cnt == 0:
                        s += "00"
                    elif sp_cnt == 1:
                        s += "00"
                    elif sp_cnt == 2:
                        s += f"{float_to_fixed_q15(demod_res.X[index]) & 0xff:02X}"
                    else:
                        s += f"{float_to_fixed_q15(demod_res.X[index]) >> 8:02X}"
                else:
                    s += "00"
            s += ";\n"
    print(s)
