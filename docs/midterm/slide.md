---
theme: academic
# _class: lead
paginate: true
backgroundColor: #ffffff
marp: true
math: katex
---

# **FPGAを用いたOFDM復調器の作成**
2024/10/09
T536 山口雄大

---
# 目次
1. 理論
1. 流星バースト通信のプロトコル
1. シミュレーション結果
1. FPGA
1. 今後の予定
---
# OFDM採用の背景
- 流星バースト通信の受信電力$E$は時間$t$の経過で指数関数的に減少。
    - $E(t)=\exp(-t/\tau)$
    - 短い時間で情報を伝送する必要がある。
- 複数の搬送波を用いて並列伝送を行う**OFDM**を採用。
---
# OFDM(直交周波数分割多重方式)
- 変調時は**逆離散フーリエ変換**(IDFT)を行い、
  復調時は**逆フーリエ変換**(DFT)を行う。
- 周波数利用効率が優れている。
  - 三角関数の直交性
$
\int_0^T \cos{mx}\cos{nx}dx = \left\{
\begin{array}{ll}
0 & (n\neq m)\\
1/2 & (n= m)
\end{array}
\right.
$

---
# FDMとOFDMの比較
- 三角関数の直交性を利用→OFDMの方が周波数利用効率がいい
![w:700 center](./assets/fdm-ofdm.svg)

---
# OFDMでDFTを行う理由
- 複数の搬送波を掛け合わせる回路は規模大
- DFTを使うと回路規模が小さくなる。
![w:700 center](./assets/ofdm-multiple-carrier.drawio.svg)
---
# DFTからFFTへ
- DFTは計算量が$\Omicron(N^2)$
- FFTを使用すると、Nが2の冪乗のとき、$\Omicron(N\log{N})$で計算可能。
---
# フーリエ変換復習
フーリエ変換　　　　　　　$X(\omega)=\int_{-\infty}^{\infty}x(t) e^{-j \omega t}dt$

フーリエ逆変換　　　　　　$x(t)=\frac{1}{2\pi}\int_{-\infty}^{\infty}X(\omega) e^{j \omega t}dt$

離散フーリエ変換(DFT)　　 $X[k]=\sum_{n=0}^{N-1}x[n] e^{-j\frac{2\pi k n}{N}}$

離散フーリエ逆変換(IDFT)　$x[n]=\frac{1}{N}\sum_{k=0}^{N-1}X[k] e^{j\frac{2\pi k n}{N}}$

---
# FFT
- 計算量:$\Omicron(N\log{N})$
- ポイント:添字の偶奇を分けて考える。
  - 分割統治法
---
DFT:$F_k=\sum_{n=0}^{N-1}f_n e^{-j\frac{2\pi n k}{N}},f_n^e\equiv f_{2n}, f_n^o\equiv f_{2n+1}, W_N\equiv e^{-j\frac{2\pi n k}{N}}$
偶奇で分ける
$$F_k=\sum_{n=0}^{N-1}f_n W_N^{kn} = \sum_{n=0}^{N/2-1}f_e W_{N/2}^{kn} + W_N^k \sum_{n=0}^{N/2-1}f_o W_{N/2}^{kn}$$
$F_k$の$k$に$k+N/2$を代入
$$F_k=\sum_{n=0}^{N-1}f_n W_N^{n(k+N/2)} = \sum_{n=0}^{N/2-1}f_e W_{N/2}^{n(k+N/2)} + W_N^{k+(N/2)}\sum_{n=0}^{N/2-1}f_o W_{N/2}^{n(k+N/2)}$$
---

$$\left\{
\begin{array}{ll}
W_{N/2}^{k+N/2}=e^{-j\frac{2\pi(k+N/2)}{N/2}}=e^{-j\frac{2\pi k}{N/2}} e^{-j2\pi}=e^{-j\frac{2\pi k}{N/2}}=W_{N/2}{k}\\
W_{N}^{k+N/2}=e^{-j\frac{2\pi (k + N/2)}{N}}=e^{-j\frac{2\pi k}{N}} e^{-j\pi}=-e^{-j\frac{2\pi k}{N}}=W_N^k\\
\end{array}
\right.$$
を用いると
$$F_k=\sum_{n=0}^{N-1}f_n W_N^{n(k+N/2)} = \sum_{n=0}^{N/2-1}f_e W_{N/2}^{n(k+N/2)} + W_N^{k+(N/2)}\sum_{n=0}^{N/2-1}f_o W_{N/2}^{n(k+N/2)}$$
$$=\sum_{n=0}^{N/2-1}f_e W_{N/2}^{kn} - W_N^k\sum_{n=0}^{N/2-1}f_o W_{N/2}^{kn}$$
計算量が$\Omicron(N^2)$から$\Omicron(N\log{N})$になった！

---
# IDFT
FFTとIFFTの実装を共通化できると嬉しいので、IDFTをDFTを使って表現
$$x[n]=\frac{1}{N}\sum_{k=0}^{N-1}X[k] e^{j\frac{2\pi k n}{N}}=\frac{1}{N}\overline{\sum_{k=0}^{N-1}\overline{X[k]}e^{-j\frac{2 \pi k x}{N}}}$$
- $X[k]$の複素共役をとる。
- $\overline{X[k]}$をDFTする。
- その結果を複素共役し、最後に$1/N$すればOK

---
# FFTの実装(再帰)
動的確保のできる配列を使うといい感じに実装できる。
```
C++かPythonで実装する
```

---

# bit-reverse
---

# 再帰プログラム(cooley turkey)

---

# FFTプログラム(非再帰)

---

# 相関

---

# OFDM変調器の構成
<!-- TODO:実部のみの波に変換するところ詳しく -->
![w:1200 center](./assets/odfm-modulation-diagram.drawio.svg)

---

# OFDM復調器の構成