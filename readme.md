OFDMする

# 環境
- Linux
- Python3.11
  - numpy
  - scipy
  - matplotlib
  - matplotlib-fontja

# メモ

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