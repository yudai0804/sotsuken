from ofdm import *
import signal
import sys
import random
from multiprocessing import Process


def run():
    # signal.signal(signal.SIGINT, signal.SIG_DFL)
    original_data = np.array([], dtype=np.int64)
    for i in range(12):
        original_data = np.append(original_data, random.randint(0, 255))
        # print(f"0b{original_data[i]:08b}")
    ofdm_mod = OFDM_Modulation()
    t, x, ifft_t, ifft_x, no_carrier_signal = ofdm_mod.calculate(original_data)
    ofdm_demod = OFDM_Demodulation()
    ans_data, f, X, _t, _x, __x = ofdm_demod.calculate(t, x)

    corr = Correlation()
    x_2n = np.zeros(2 * N, dtype=np.float64)
    for i in range(N):
        x_2n[i] = __x[i].real * 100
        x_2n[i + N] = __x[i].real * 100
    # for i in range(15):
    # x_2n[i] = 0
    R = corr.calculate(x_2n)
    # for i in range(len(R)):
    # print(f"i={i},R={R[i]:.4f}")
    """
    assert len(original_data) == len(ans_data)
    for i in range(len(original_data)):
        assert (
            original_data[i] == ans_data[i]
        ), f"original = {original_data[i]}, answer = {ans_data[i]}, R = {max(R)}"
        # print(f"original = {original_data[i]}, answer = {ans_data[i]}")
    """
    ok = True
    for i in range(len(original_data)):
        if original_data[i] != ans_data[i]:
            ok = False
    print(f"ok={ok},R={max(R)}")


def run_run():
    for i in range(30):
        run()


def main():
    pn = 10
    p = []
    for i in range(pn):
        p = Process(target=run_run, args=())
        p.start()
    for i in range(pn):
        p.join()


def main2():
    for i in range(30):
        run()


if __name__ == "__main__":
    main()
    # main2()
