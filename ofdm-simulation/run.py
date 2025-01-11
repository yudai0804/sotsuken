import numpy as np
import numpy.testing as npt
from fpga import run_demodulation, run_ofdm
from ofdm import single_symbol
from util_binary import fixed_q15_quantization

########## simulator ##########


def simulator_single_symbol() -> None:
    N: int = 1024
    original_data = np.concatenate(
        ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(N, dtype=np.complex128)
    # このままFFTすると値が1を超えてうまく行かないので、4で割る
    for i in range(N):
        x[i] = fixed_q15_quantization(mod_res.ifft_x[i] / 4)
    fpga_res = run_ofdm(x)
    npt.assert_equal(original_data, fpga_res)


def simulator_demodulation() -> None:
    N: int = 1024
    BUFF_SIZE = 8192
    original_data = np.concatenate(
        ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    delay: int = 10
    # このままFFTすると値が1を超えてうまく行かないので、4で割る
    for i in range(N):
        x[i + delay] = fixed_q15_quantization(mod_res.ifft_x[i] / 4)
    run_demodulation(x)
