import argparse

parser = argparse.ArgumentParser()
group_mode = parser.add_mutually_exclusive_group(required=True)
group_mode.add_argument("--single", action="store_true")
group_mode.add_argument("--multi", action="store_true")
group_mode.add_argument("--multi_endurance", type=int)

parser.add_argument("--plot", action="store_true")

args = parser.parse_args()

# argparseの動作を優先するため遅延import
from ofdm import *
import signal

# matplotlibが正常に終了するのに必要
signal.signal(signal.SIGINT, signal.SIG_DFL)

if args.single:
    res_mod, res_demod = single_signal()
    if args.plot:
        plot_single_signal(res_mod, res_demod)
elif args.multi:
    res_mod, res_demod, res_sync = multi_signal(SYMBOL_NUMBER=10)
    if args.plot:
        plot_multi_signal(res_sync)
elif args.multi_endurance is not None:
    assert args.plot == False, "plotオプションは不要です"
    multi_signal(SYMBOL_NUMBER=args.multi_endurance)
