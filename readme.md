# requirements
## ofdm-simulation
Python3.11
  - numpy
  - scipy
  - matplotlib
  - matplotlib-fontja
  - pytest(fot test)
  - mypy(for type check)

octave(xcorr用)
  - signal packageを使用
# setup

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

# docker
ビルド
```
cd ofdm-simulation
docker build -t ofdm-simulation .
```
実行
```
docker run -v .:/app/ofdm-simulation ofdm-simulation:latest pytest
```
実行(tty)
```
docker run -itv .:/app/ofdm-simulation ofdm-simulation:latest pytest
```