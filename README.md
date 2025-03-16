# sotsuken
卒研用リポジトリです。  

本リポジトリには
- OFDMの変復調のシミュレーションプログラム(Python)
- FPGA(Gowin社のGW1NR-9)を用いて製作したOFDM復調器のプログラム(Verilog HDL)
- その他卒論などのデータ

などが入っています。

- PC上でOFDMの信号を生成し、復調器に入力。復調器ではFFTを行って復調し、その結果をUARTで送信という流れで動作します。  
- PythonやVerilog HDLのコードはコミットをすると、GitHub Actionsが走って、自動でテストが実行されます。  
- Pythonのテストフレームワークにはpytestを使用しています。  
- また、Verilog HDLのテストもフレームワークにはpytestを使用していて、Pythonからsubprocessを介して、Icarus Verilog上でVerilog HDLを実行、結果をprintし、正しいかをPython側で確認という流れで開発しています。  

# ディレクトリ説明(抜粋)
- data
  - 実験データを保存する場所
- docs
  - assetsと最終的な成果物の内容が異なっている部分が多いので注意
  - final-slide
    - [卒研審査会用スライド](https://github.com/yudai0804/sotsuken/blob/master/docs/final-slide/20250304%E5%B1%B1%E5%8F%A3%E9%9B%84%E5%A4%A7%E7%99%BA%E8%A1%A8_%E6%9C%AC%E7%95%AA%E7%94%A8.pdf)
  - midterm
    - 中間発表用スライド
  - paper
    - [論文](https://github.com/yudai0804/sotsuken/blob/master/docs/paper/%E5%8D%92%E8%AB%96.pdf)
  - prepaper
    - [予稿](https://github.com/yudai0804/sotsuken/blob/master/docs/prepaper/prepaper.pdf)
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
    - Pythonのシミュレーションプログラムのテストプログラム、testフレームワークにはpytestを使用。
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
Pythonのシミュレーションプログラム。  
シミュレーションプログラムと言いながらも、FPGAの開発の補助スクリプト的な役割もあります。  

## Requirements
- Python version: 3.11
- OS: Linux(Debian 12)

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
パッケージ管理にはPoetryを使用しています。  
もしPoetryを使用したくない場合は、使用しているライブラリのバージョンを合わせてpipでインストールすれば動くと思います。  

Install poetry
```
curl -sSL https://install.python-poetry.org | python3 -
```
Install dependencies
```
poetry install
```

# Run Python
仮想環境を有効にする
```
poetry shell
```
仮想環境を常に有効にしたくない場合は、各コマンドの前に`poetry run`と入力してください。  

実行  
```
python3 ofdm-simulation/main.py {args1} {args2}
```

args1とargs2は必須で、それぞれインデントの浅い方がargs1、深い方がargs2の内容となっています。  
- fpga
  - FPGAに関するスクリプトを実行可能。すべてのスクリプトは開発用。
  - butterfly-table
    - butterfly.vのコメントに使用している真理値表を生成
  - twindle-factor
    - gowin_prom_w.vに使用している正弦波テーブルを生成
  - output-fft1024
    - 任意のスペクトルをBSRAMに書き込む。
  - output-ofdm-spectrum
    - ofdmモジュールを実験するときのスペクトルを生成
  - read-fft1024
    - Icarus Verilog上でシミュレーションした結果の値を読む
- run
  - PCでOFDM信号を生成し、製作した復調器に信号を入力するときのモード
    - spe
      - FPGAで計算したフーリエ係数を表示
    - wav-single
      - OFDMシンボル1回分を復調器に入力
    - OFDMシンボルを連続して復調器に入力
  - sim
    - OFDMの変復調のシミュレーション。`--plot`オプションをつけるとプロットも行う
    - single
      - OFDMシンボルが1つのときの変復調
    - multi
      - OFDMシンボルが連続するときの変復調


実機での動作確認のでは、事前に生成したwavファイルを再生し、シリアル通信をするソフト(TeraTerm)や適当に書いたpyserialのプログラムとかでシリアル通信の結果を眺めて、動作確認を行いました。  
そのため、動作確認のときはmain.pyを使う機会は少なかったです。

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
FPGAのプログラム。  
Icarus Verilogでシミュレーションを行っているため、シミュレーションのできない暗号化されているIPなどは使用していません。

- FPGA: GW1NR-9(Tang Nano 9K)
- IDE: Gowin EDA 1.9.9.03 Education Version
- FPGA write: openFPGALoader
- Simulator: Icarus Verilog

OSはLinux(Debian 12)です。  
IDEを立ち上げて、`ofdm-fpga`のディレクトリを開けばビルドできるはずです...

## Icarus Verilog
Icarus Verilog(iverilog)はVerilog HDLのシミュレータです。  
Icarus Verillogの使い方は`ofdm-simulation/fpga.py`や`ofdm-simulation/tests/test_fpga.py`あたりのソースコードを見るとわかりやすいです。  

## openFPGALoader
Linux環境ではGowin EDAの書き込みが安定しなかったため、openFPGALoaderを使用しました。  

書き込みコマンド例  
```
cd ofdm-fpga/src
openFPGALoader -f ../impl/pnr/ofdm-fpga.fs
```

# Docker
GitHub Actions用のDockerコンテナです。pytestの実行を行います。  

Build
```
docker build -t sotsuken .
```
Run
```
docker run -v .:/app sotsuken:latest bash -c "poetry install --no-root && poetry run your-command"
```

# License
MIT License
