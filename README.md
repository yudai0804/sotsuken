# sotsuken
卒研用リポジトリです。  
FPGAを用いたOFDM復調器の作成、及びPythonでのシミュレーションを行っています。  
# ofdm-simulation
## Requirements
Python version: 3.11
Using library
  - matplotlib
  - matplotlib-fontja
  - numpy
  - pydantic
  - scipy

Using library for development

  - black(for formatter)
  - isort(fort import formatter)
  - pytest(fot test)
  - mypy(for type check)

Other

octave(for xcorr)
  - using signal package
  - for pytest

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