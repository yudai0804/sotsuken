import argparse


# 他のmoduleのimportはargparseの応答速度を上げるため、後からimportする
class RawFormatter(argparse.RawTextHelpFormatter):
    pass


parser = argparse.ArgumentParser(formatter_class=RawFormatter)
subparsers = parser.add_subparsers(dest="command", required=True, help="Main commands")

sim_parser = subparsers.add_parser("sim", formatter_class=RawFormatter)
sim_parser.add_argument("sim_mode", choices=["single", "multi", "multi-endurance"])
sim_parser.add_argument(
    "value", nargs="?", type=int, help="Value for 'multi-endurance' mode (optional)"
)
sim_parser.add_argument(
    "--plot",
    action="store_true",
    help="Plot a graph for the 'single' and 'multi' modes (optional)",
)

fpga_parser = subparsers.add_parser("fpga", formatter_class=RawFormatter)
fpga_parser.add_argument(
    "fpga_mode",
    choices=["butterfly-table", "twinddle-factor", "output-fft1024", "read-fft1024"],
)

args = parser.parse_args()

import signal

# matplotlibが正常に終了するのに必要
signal.signal(signal.SIGINT, signal.SIG_DFL)

if args.command == "sim":
    from ofdm import *

    if args.sim_mode == "single":
        assert args.value is None, "valueは不要です\n" + sim_parser.format_help()
        res_mod, res_demod = single_symbol()
        if args.plot:
            plot_single_symbol(res_mod, res_demod)
    elif args.sim_mode == "multi":
        assert args.value is None, "valueは不要です\n" + sim_parser.format_help()
        res_mod, res_demod, res_sync = multi_symbol(SYMBOL_NUMBER=10)
        if args.plot:
            plot_multi_symbol(res_sync)
    elif args.sim_mode == "multi-endurance":
        assert args.plot == False, (
            "plotオプションは不要です\n" + sim_parser.format_help()
        )
        assert args.value is not None, "valueが必要です\n" + sim_parser.format_help()
        multi_symbol(SYMBOL_NUMBER=args.value)
elif args.command == "fpga":
    from fpga import *

    if args.fpga_mode == "butterfly-table":
        output_butterfly_table()
    elif args.fpga_mode == "twinddle-factor":
        output_twinddle_factor()
    elif args.fpga_mode == "output-fft1024":
        output_fft1024()
    elif args.fpga_mode == "read-fft1024":
        read_fft1024()
