import random
from typing import Any, List, Tuple

import numpy as np
import numpy.testing as npt
import pytest
from numpy.typing import NDArray
from ofdm import *
from pydantic import BaseModel, ConfigDict


@pytest.mark.parametrize(
    ("is_no_carrier"),
    [(False), (True)],
)
def test_single_symbol(is_no_carrier: bool) -> None:
    original_data = np.concatenate(
        ([0x55], np.random.randint(0, 255, size=10, dtype=np.int32), [0x55]),
        dtype=np.int32,
    )

    mod = Modulation()
    res_mod = mod.calculate(original_data)
    t = res_mod.t
    x = res_mod.x
    ifft_t = res_mod.ifft_t
    ifft_x = res_mod.ifft_x
    demod = Demodulation()
    ans_data = np.array([], dtype=np.int32)

    if is_no_carrier:
        res_demod = demod.calculate_no_carrier(ifft_t, ifft_x)
        ans_data = res_demod.data
    else:
        res_demod = demod.calculate(t, x)
        ans_data = res_demod.data

    assert res_demod.is_success == True
    npt.assert_equal(original_data, ans_data)


def test_multi_symbol() -> None:
    multi_symbol(SYMBOL_NUMBER=10)


def test_multi_symbol_endurance() -> None:
    multi_symbol(SYMBOL_NUMBER=1000)
