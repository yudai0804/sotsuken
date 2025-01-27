import numpy as np
import numpy.testing as npt
import scipy
import serial
from fpga import run_demodulation, run_ofdm
from numpy.typing import NDArray
from ofdm import single_symbol
from util_binary import *

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


def simulator_demodulation_single() -> None:
    N: int = 1024
    BUFF_SIZE = 2000
    delay: int = 10
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    res_len: int = 12
    for i in range(N):
        x[i + delay] = fixed_q15_quantization(mod_res.ifft_x[i])
    fpga_res = run_demodulation(x, original_data, res_len, delay)
    npt.assert_equal(original_data, fpga_res)


def simulator_demodulation_multi() -> None:
    N: int = 1024
    delay: int = 10
    BUFF_SIZE = N + delay
    symbol_number = 2
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    res_len: int = 12 * symbol_number
    for i in range(N):
        x[i + delay] = fixed_q15_quantization(mod_res.ifft_x[i])
    fpga_res = run_demodulation(x, original_data, res_len, delay)
    expected = np.zeros(res_len, dtype=np.int32)
    for i in range(res_len):
        expected[i] = original_data[i % 12]
    npt.assert_equal(expected, fpga_res)


def run_wav_single() -> None:
    N: int = 1024
    BUFF_SIZE = N
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    for i in range(N):
        x[i] = fixed_q15_quantization(mod_res.ifft_x[i])
        x[i] /= 0.015625

    scipy.io.wavfile.write("test-single.wav", 48000, x)


def run_wav_multi(SYMBOL_NUMBER: int = 10) -> None:
    N: int = 1024
    BUFF_SIZE = N * 10
    original_data = np.array(
        [0x55, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x55],
        dtype=np.int32,
    )
    mod_res, demod_res, _ = single_symbol(
        original_data=original_data, is_no_carrier=True
    )
    x = np.zeros(BUFF_SIZE, dtype=np.float64)
    for i in range(9 * N):
        x[i] = fixed_q15_quantization(mod_res.ifft_x[i % N])
        x[i] /= 0.015625

    scipy.io.wavfile.write("test-multi.wav", 48000, x)


def run_spe() -> NDArray[np.float64]:
    N: int = 1024
    N2: int = N // 2

    port = "/dev/ttyUSB2"
    baudrate = 9600
    timeout = 1
    ser = serial.Serial(port, baudrate, timeout=timeout)

    raw_data = np.zeros(N2, dtype=np.int32)
    X = np.zeros(N2, dtype=np.float64)
    tmp: bytes
    i: int = 0
    j: int = 0
    try:
        # 受信バッファをクリア
        ser.reset_input_buffer()
        # 送信バッファをクリア
        ser.reset_output_buffer()
        while 1:
            data = ser.read()
            if data:
                if j == 0:
                    tmp = data
                    j += 1
                else:
                    raw_data[i] = (int.from_bytes(data) << 8) + int.from_bytes(tmp)
                    j = 0
                    if i == N2 - 1:
                        break
                    else:
                        i = i + 1
        for j in range(N2):
            X[j] = fixed_q15_to_float(raw_data[j])
            print(f"{j}, {raw_data[j]}, {X[j]}")
    finally:
        # シリアルポートを閉じる
        ser.close()
        # print("Serial port closed.")

    return X


def run_spe_plot() -> None:
    N: int = 1024
    N2: int = N // 2

    pass
