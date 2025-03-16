# sotsuken
卒研用リポジトリです。  
FPGAを用いたOFDM復調器の製作、Pythonでのシミュレーションを行っています。  

# ディレクトリ説明(抜粋)
- data
  - 実験データを保存する場所
- docs
  - 整理できてなくてぐちゃくちゃ&assetsと最終的な成果物の内容が異なっている部分が多いので注意
  - final-slide
    - 卒研審査会用スライド
  - midterm
    - 中間発表用スライド
  - paper
    - 論文
  - prepaper
    - 予稿
- experiment
  - 実験用プログラム
- ofdm-fpga
  - FPGAのプログラム
  - src
    - FPGAのVerilog HDLのソースコード
    - gowin
      - gowinディレクトリにはGowinのFPGA固有の機能を制御するプログラムが入っている
      - gowin_prom_w.v
        - 回転因子用BSRAMのプログラム
      - gowin_rpll.v
        - PLL用プログラム、27MHzから24MHzに逓倍
      - gowin_sp_adc.v
        - ADC用BSRAMのプログラム
      - gowin_sp_fft0.v
        - FFT用BSRAMのプログラム
      - gowin_sp_fft1.v
        - FFT用BSRAMのプログラム
      - prim_sim.v
        - GowinのハードウェアをIcarus Verilog等のツールで動かすときに使うプログラム
    - butterfly.v
      - バタフライ演算器のプログラム
    - demodulation.v
      - 復調の一連の動作を行うプログラム
    - fft1024.v
      - N=1024のFFTを行うプログラム
    - led.v
      - LEDを光らせるプログラム(デバッグ用)
    - mcp3002.v
      - MCP3002を動かすプログラム
    - ofdm-fpga.cst
      - ピンの割り当て、IDEで使用
    - ofdm-fpga.sdc
      - タイミング制約、IDEで使用
    - ofdm.v
      - OFDM(BPSK)の符号判定処理
    - top.v
      - 全体を統合するtopモジュール
    - uart_rx.v
      - UARTの受信プログラム(未使用)
    - uart_tx.v
      - UARTの送信プログラム
  - tb
    - テストベンチ用のVerilog HDLのプログラム
- ofdm-simulation
  - シミュレーション用プログラム(Python)
  - tests
    - Pythonのシミュレーションプログラムのテストプログラム、testフレームワークにはpytestを使用
  - correlate.py
    - 自作した相関のプログラム
  - fft.py
    - 自作したFFTとその関連プログラム
  - fpga.py
    - fpgaのプログラムを書くときの補助スクリプト
  - main.py
    - シミュレーションのmainプログラム、といってもコマンドライン引数を受け取ってるだけだけど...
  - ofdm.py
    - OFDMの変復調を行うプログラム
    - Modulationクラス、Demodulationクラス、Synchronizationクラスの3つのクラスから構成されている
    - 各種定数を変えることで条件を変更できます
  - run.py
    - 各種実行プログラム、主にmain.pyから呼び出される
  - util_binary.py
    - ビットの処理をいい感じに行うプログラム

# ofdm-simulation
Pythonのシミュレーションプログラム
## Requirements
Python version: 3.11

Library
  - matplotlib
  - matplotlib-fontja
  - numpy
  - pydantic
  - scipy
  - pyserial

Library for development

  - black(formatter)
  - isort(formatter)
  - pytest(test)
  - mypy(type check)

Other

octave(for xcorr)
  - using signal package
  - for pytest

# Setup Python
If you don't have Python 3.11, I recommend installing it using pyenv.

Install poetry
```
curl -sSL https://install.python-poetry.org | python3 -
```
Install dependencies
```
poetry install
```

# Run Python
Enable virtual environment(optional)
```
poetry shell
```
When the virtual environment is activated, you don't need to use `poetry run`.

Run  
コマンドライン引数の渡し方はソースコードを読むか、雰囲気で実行してください...
```
poetry run python3 main.py
```
pytest
```
poetry run pytest
```
mypy(lint)
```
poetry run mypy
```
isort(formatter)
```
poetry run isort .
```
black(formatter)
```
poetry run black .
```
ローカルでCIを走らせる。
GitHub Actionsで動いているCIと同じ内容が実行できる。
```
./scripts/ci.sh
```

# ofdm-fpga
FPGAのプログラム

- FPGA: GW1NR-9(Tang Nano 9K)
- IDE: Gowin 1.9.9.03 IDE Education
- FPGA write: openFPGALoader
- Simulator: Icarus Verilog

IDEを立ち上げて、`ofdm-fpga`のディレクトリを開けばビルドできるはずです...  
FPGA開発にもPythonはゴリゴリに使っています。具体的にはちょっとした開発用スクリプトをPythonで書いたり、Icarus Verilogをsubprocess経由で呼び出して、Pytestで動かしたり...

## Icarus Verilog
Icarus Verilog(iverilog)はVerilog HDLのシミュレータです。  

```
iverilog -o testbench verilog/file/name.v -DSIMULATOR && vvp testbench && gtkwave testbench.vcd
```

## openFPGALoader
```
cd ofdm-fpga/src
openFPGALoader -f ../impl/pnr/ofdm-fpga.fs
```

# Docker
GitHub Actions用のDockerコンテナです。Pytestを動かします。
Build
```
docker build -t sotsuken .
```
Run
```
docker run -v .:/app sotsuken:latest bash -c "poetry install --no-root && poetry run your-command"
```

# Design
## main.pyとpytestの使い分けについて
プログラムの実行方法は、
- main.pyのコマンドライン引数を与えて実行
- pytestで実行
の2種類があります。  
どちらに記述するかの基準は
グラフのプロット、または入力をキーボード(ファイル)から与えるなどのインタラクティブな動作を伴うときはmain.pyもしくはrun.pyに  
入力と出力を一致しているかを確かめたいときはpytest  
としています。

当然ですが、main.pyで実行可能なものは、testが書かれているものに関してはpytestからも実行が可能です。(するかは別として)

# License
MIT License
