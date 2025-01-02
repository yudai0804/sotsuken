import os
import subprocess
import sys
from io import StringIO

import numpy as np
import numpy.testing as npt
import pytest
from fft import fft_fpga
from fpga import *
from numpy.typing import NDArray
from util_binary import (
    bit_reverse,
    fixed_q15_quantization_complex,
    fixed_q15_to_float,
    float_to_fixed_q15,
)


def run_verilog_fft(N: int, _x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    # 出力する文字列を作成
    # ビット反転はoutput_fft_sramの中で行う
    s0, s1 = output_fft_sram(N, _x.copy())
    # ofdm-fpgaディレクトリに移動
    start_dir = os.getcwd()
    # 一度test_fpga.pyがあるディレクトリまで移動
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # ofdm-fpgaのあるディレクトリまで移動
    os.chdir("../../ofdm-fpga")
    # ファイルに書き出す
    os.makedirs("tmp", exist_ok=True)
    with open("tmp/gowin_sp_fft0_defparam.v", "w") as file:
        print(s0, file=file)
    with open("tmp/gowin_sp_fft1_defparam.v", "w") as file:
        print(s1, file=file)
    # 実行
    result = subprocess.run(
        "iverilog -o testbench tb/tb_fft1024.v src/fft1024.v src/butterfly.v src/gowin/gowin_prom_w.v src/gowin/gowin_sp_fft0.v src/gowin/gowin_sp_fft1.v src/gowin/prim_sim.v -I tmp -DSIMULATOR",
        shell=True,
    )
    assert result.returncode == 0
    result = subprocess.run("vvp testbench", shell=True, capture_output=True, text=True)
    assert result.returncode == 0

    # 入力を切換
    mock_input = StringIO(result.stdout)
    sys.stdin = mock_input
    X = read_fft(N)
    # 入力をもとに戻す
    sys.stdin = sys.__stdin__
    # 作業ディレクトリをもとの場所に移動
    os.chdir(start_dir)
    return X


def test_fft1024() -> None:
    N: int = 1024
    x = np.zeros(N, dtype=np.complex128)
    low: float = -0.01
    high: float = 0.01
    x = np.random.uniform(low, high, N) + 1j * np.random.uniform(low, high, N)
    # 乱数をそのまま与えると、64bit浮動小数点数と16bitの固定小数点数の有効数字に差が出てしまうため、
    # 乱数を一度固定小数点数に変換し、再度浮動小数点数に変換する
    for i in range(N):
        x[i] = fixed_q15_quantization_complex(x[i])

    expected: NDArray[np.complex128] = np.fft.fft(x)
    result: NDArray[np.complex128] = run_verilog_fft(N, x.copy())
    # decimal=3は調子がいいと通るが、安定しないのでdecimal=2
    npt.assert_almost_equal(expected, result, decimal=2)
