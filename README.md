# sotsuken
卒研用リポジトリです。  
FPGAを用いたOFDM復調器の作成、Pythonでのシミュレーションを行っています。  

# ofdm-simulation
## Requirements
Python version: 3.11

Using Python library
  - matplotlib
  - matplotlib-fontja
  - numpy
  - pydantic
  - scipy
  - pyserial

Using library for development

  - black(formatter)
  - isort(formatter)
  - pytest(test)
  - mypy(type check)

Other

octave(for xcorr)
  - using signal package
  - for pytest

# ofdm-fpga
- FPGA: GW1NR-9(Tang Nano 9K)
- IDE: Gowin 1.9.9.03 IDE Education
- FPGA write: openFPGALoader
- Simulator: Icarus Verilog

## iverilog
```
iverilog -o testbench verilog/file/name.v -DSIMULATOR && vvp testbench && gtkwave testbench.vcd
```

## openFPGALoader
```
cd ofdm-fpga/src
openFPGALoader -f ../impl/pnr/ofdm-fpga.fs
```

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
```
poetry run python3 path/to/python-file.py
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
# Docker
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
グラフのプロット、または入力をキーボード(ファイル)から与えるなどのインタラクティブな動作を伴うときはmain.pyに  
入力と出力を一致しているかを確かめたいときはpytest  
としています。  
当然ですが、main.pyで実行可能なものは、testが書かれているものに関してはpytestからも実行が可能です。(するかは別として)