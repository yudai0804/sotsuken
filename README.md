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

octave(xcorr用)
  - signal packageを使用
  - test用

# Setup

venv環境作成
```
cd ofdm-simulation
python3 -m venv .venv
```

venvをactivate
```
source .venv/bin/activate
```

pipでインストールされてるものを`requirements.txt`に書き出す
```
pip freeze > requirements.txt
```

`requirements.txt`の内容をインストール
```
pip install -r requirements.txt
```

# Docker
ビルド
```
docker build -t sotsuken .
```
実行(pytest)
```
docker run -v .:/app sotsuken:latest pytest
```
実行(mypy)
```
docker run -v .:/app sotsuken:latest mypy --strict ofdm-simulation/
```