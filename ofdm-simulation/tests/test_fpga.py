import os
import subprocess
import sys
from io import StringIO

import numpy as np
import numpy.testing as npt
import pytest
from fpga import *
from numpy.typing import NDArray
from util_binary import bit_reverse, fixed_q15_to_float, float_to_fixed_q15


def run_verilog_fft(N: int, _x: NDArray[np.complex128]) -> NDArray[np.complex128]:
    # bit reverse
    x: NDArray[np.complex128] = bit_reverse(_x.copy())
    # 出力する文字列を作成
    s0, s1 = output_fft_sram(N, x)
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
        "iverilog -o testbench tb/tb_fft1024.v src/fft1024.v src/gowin/gowin_prom_w.v src/gowin/gowin_sp_fft0.v src/gowin/gowin_sp_fft1.v src/gowin/prim_sim.v -I tmp -DSIMULATOR",
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
    for i in range(N // 2):
        x[2 * i] = 1 / (2 * N)
    # x[0] = 0.5
    # low: float = -0.01
    # high: float = 0.01
    # x = np.random.uniform(low, high, N) + 1j * np.random.uniform(low, high, N)
    # x = 0.1 * np.sin(np.arange(N) / (2 * N) * np.pi)
    expected: NDArray[np.complex128] = np.fft.fft(x)
    result: NDArray[np.complex128] = run_verilog_fft(N, x)
    for i in range(N):
        print(expected[i], result[i])
    npt.assert_almost_equal(expected, result, decimal=4)
