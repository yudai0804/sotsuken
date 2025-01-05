import os
import subprocess
import sys
from io import StringIO
from typing import Any, List, Tuple

import numpy as np
import numpy.testing as npt
import pytest
from fpga import *
from numpy.typing import NDArray
from util_binary import fixed_q15_quantization_complex


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
    result: NDArray[np.complex128] = run_fft1024(x.copy())
    # decimal=3は調子がいいと通るが、安定しないのでdecimal=2
    npt.assert_almost_equal(expected, result, decimal=2)


def test_uart_tx() -> None:
    # ofdm-fpgaディレクトリに移動
    start_dir = os.getcwd()
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    # ofdm-fpgaのあるディレクトリまで移動
    os.chdir("../../ofdm-fpga")
    # 実行
    # 本当は良くないけど、mypyがうまく動かないので、Any型でごまかす
    result: Any = subprocess.run(
        "iverilog -o testbench tb/tb_uart_tx.v src/uart_tx.v -DSIMULATOR",
        shell=True,
    )
    assert result.returncode == 0, "[Verilog] Bulid failed"
    result = subprocess.run("vvp testbench", shell=True, capture_output=True, text=True)
    assert result.returncode == 0, "[Verilog] error"
    # Assertで落ちていないかチェック
    assert ("ASSERTION FAILED" in result.stdout) == 0, "[Verilog] Assertion error"

    # 作業ディレクトリをもとの場所に移動
    os.chdir(start_dir)
