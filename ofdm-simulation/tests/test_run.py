import numpy as np
import numpy.testing as npt
import pytest
from numpy.typing import NDArray
from run import *


def test_simulator_single_symbol() -> None:
    simulator_single_symbol()


def test_simulator_demodulation_signle() -> None:
    simulator_demodulation_single()


def test_simulator_demodulation_multi() -> None:
    simulator_demodulation_multi()
