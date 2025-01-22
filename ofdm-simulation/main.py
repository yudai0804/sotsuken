# main.pyでは入力されたコマンドをparseするだけ。
# 計算等の処理は別ファイルに記述されている。

# 他のmoduleのimportはargparseの応答速度を上げるため、後からimportする
import argparse


# おまじない
class RawFormatter(argparse.RawTextHelpFormatter):
    pass


parser = argparse.ArgumentParser(formatter_class=RawFormatter)
subparsers = parser.add_subparsers(dest="command", required=True, help="Main commands")

fpga_parser = subparsers.add_parser("fpga", formatter_class=RawFormatter)
fpga_parser.add_argument(
    "fpga_mode",
    choices=[
        "butterfly-table",
        "twinddle-factor",
        "output-fft1024",
        "output-ofdm-spectrum",
        "read-fft1024",
    ],
)

run_parser = subparsers.add_parser("run", formatter_class=RawFormatter)
run_parser.add_argument(
    "run_mode", choices=["spe", "spe-plot", "wav-single", "wav-multi"]
)

sim_parser = subparsers.add_parser("sim", formatter_class=RawFormatter)
sim_parser.add_argument("sim_mode", choices=["single", "multi"])
sim_parser.add_argument("value", nargs="?", type=int)
sim_parser.add_argument(
    "--plot",
    action="store_true",
    help="Plot a graph for the 'single' and 'multi' modes (optional)",
)

args = parser.parse_args()

import signal

# matplotlibが正常に終了するのに必要
signal.signal(signal.SIGINT, signal.SIG_DFL)

if args.command == "sim":
    from ofdm import *

    if args.sim_mode == "single":
        assert args.value is None, "valueは不要です\n" + sim_parser.format_help()
        res_mod, res_demod, original_data = single_symbol()
        print(original_data)
        if args.plot:
            plot_single_symbol(res_mod, res_demod)
    elif args.sim_mode == "multi":
        assert args.value is None, "valueは不要です\n" + sim_parser.format_help()
        res_mod, res_demod, res_sync = multi_symbol(SYMBOL_NUMBER=10)
        if args.plot:
            plot_multi_symbol(res_sync)
elif args.command == "fpga":
    from fpga import *

    if args.fpga_mode == "butterfly-table":
        output_butterfly_table()
    elif args.fpga_mode == "twinddle-factor":
        output_twinddle_factor()
    elif args.fpga_mode == "output-fft1024":
        output_fft1024()
    elif args.fpga_mode == "output-ofdm-spectrum":
        output_ofdm_spectrum()
    elif args.fpga_mode == "read-fft1024":
        read_fft1024()
elif args.command == "run":
    from run import *

    if args.run_mode == "spe":
        run_spe()
    elif args.run_mode == "spe-plot":
        run_spe_plot()
    elif args.run_mode == "wav-single":
        run_wav_single()
    elif args.run_mode == "wav-multi":
        run_wav_multi()
