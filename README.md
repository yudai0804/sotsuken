# sotsuken
卒研用リポジトリです。  
FPGAを用いたOFDM復調器の作成、及びPythonでのシミュレーションを行っています。  

# ofdm-simulation
## Requirements
Python version: 3.11

Using Python library
  - matplotlib
  - matplotlib-fontja
  - numpy
  - pydantic
  - scipy

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

# Setup
If you don't have Python 3.11, I recommend installing it using pyenv.

Install poetry
```
curl -sSL https://install.python-poetry.org | python3 -
```
Install dependencies
```
poetry install
```

# Run
run
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

# Docker
Build
```
docker build -t sotsuken .
```
Run
```
docker run -v .:/app sotsuken:latest bash -c "poetry install --no-root && poetry run your-command"
```
