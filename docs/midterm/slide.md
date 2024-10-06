---
theme: gaia
_class: lead
paginate: true
backgroundColor: #fff
marp: true
style: |
  img[alt~="center"] {
    display: block;
    margin: 0 auto;
  }
    .split {
    display: table;
    width: 100%;
    }
    .split-item {
    display: table-cell;
    padding: 0px;
    width: 50%;
    }
    .split-left {
    position: relative;
    }
    .split-left__inner {
    height: 100%;
    position: fixed;
    width: 50%;
    }
    .split-right {
    position: relative;
    }
    .split-right__inner {
    height: 420px;
    }
    .test {
    display: flex;
    align-items: center;
    }
    .test-left {
    flex: 1;
    }
    .test-right {
    flex: 1;
    left-padding: 20px;
    }
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
<!-- 研究目的書く -->
---
# OFDM採用の背景
- 流星バースト通信の受信電力$E$は時間$t$の経過と共に指数関数的に減少することが知られている。
    - $E(t)=\exp(-t/\tau)$
    - 短い時間で情報を伝送する必要がある。
- 複数の搬送波を用いて並列伝送を行う**OFDM**を採用。
---
# OFDM(直交周波数分割多重方式)

- 変調時に送信信号を**逆離散フーリエ変換**(IDFT)を行い、
  復調時に受信信号を**逆フーリエ変換**(DFT)を行う。
- 周波数利用効率に優れている。
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
三角関数の直交性を利用しているOFDMのほうが周波数効率がよい。
![w:800 center](./assets/fdm-ofdm.svg)

