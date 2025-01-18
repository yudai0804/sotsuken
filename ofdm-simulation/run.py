import numpy as np
import numpy.testing as npt
import scipy
from fpga import run_demodulation, run_ofdm
from ofdm import single_symbol
from util_binary import fixed_q15_quantization

########## simulator ##########


def simulator_single_symbol() -> None:
    N: int = 1024
    # original_data = np.concatenate(
    #     ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
    #     dtype=np.int32,
    # )
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    # TODO: デバッグ終わったらもとに戻す
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(N, dtype=np.complex128)
    for i in range(N):
        x[i] = fixed_q15_quantization(mod_res.ifft_x[i])
    fpga_res = run_ofdm(x)
    npt.assert_equal(original_data, fpga_res)


def simulator_demodulation() -> None:
    N: int = 1024
    # BUFF_SIZE = 8192
    BUFF_SIZE = 1100
    # original_data = np.concatenate(
    # ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
    # dtype=np.int32,
    # )
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    delay: int = 10
    for i in range(N):
        x[i + delay] = fixed_q15_quantization(mod_res.ifft_x[i])
    fpga_res = run_demodulation(x, original_data)
    npt.assert_equal(original_data, fpga_res)


def run() -> None:
    N: int = 1024
    BUFF_SIZE = 1100
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    delay: int = 10
    for i in range(N):
        x[i + delay] = fixed_q15_quantization(mod_res.ifft_x[i])
        # x[i + delay] /= 0.015625

    scipy.io.wavfile.write("test.wav", 48000, x)
