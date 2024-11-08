import math
from typing import Any, List, Tuple

import numpy as np
import scipy
from numpy.typing import NDArray


def xcorr(
    x: NDArray[np.complex128], y: NDArray[np.complex128]
) -> Tuple[NDArray[np.complex128], NDArray[np.int32]]:
    """
    循環畳み込み積分を使って相互相関関数を求める
    yの要素数0のときはy=xとなって、自己相関関数を求める

    仕様はmatlabのxcorrと同じ(はず)
    numpy.correlateやscipy.signal.correlateとは仕様が違うので注意
    参考
    xcorrの仕様(matlab):https://jp.mathworks.com/help/matlab/ref/xcorr.html
    xcorrの理論(巡回畳み込み積分)および実装例:https://www.ikko.k.hosei.ac.jp/~matlab/xcorr.pdf

    例

    x = np.array([2, 3, 4, 5], dtype=np.complex128)
    y = np.array([3, 4, 5, 7], dtype=np.complex128)
    ans, index = xcorr(x, y)
    print(ans)
    結果
    [14.+0.j 31.+0.j 51.+0.j 73.+0.j 50.+0.j 32.+0.j 15.+0.j]

    ans[0] = x[0] * y[3] = 2 * 7 = 14(左に3つシフト)
    ans[1] = x[0] * y[2] + x[1] * y[3] = 2 * 5 + 3 * 7 = 31(左に2つシフト)
    ans[2] = x[0] * y[1] + x[1] * y[2] + x[2] * y[3] = 2 * 4 + 3 * 5 + 4 * 7 = 51(左に1つシフト)
    ans[3] = x[0] * y[0] + x[1] * y[1] + x[2] * y[2] + x[3] * y[3] = 2 * 3 + 3 * 4 + 4 * 5 + 5 * 7 = 73(シフトなし)
    ans[4] = x[1] * y[0] + x[2] * y[1] + x[3] * y[2] =  3 * 3 + 4 * 4 + 5 * 5 = 50(右に1つシフト)
    ans[5] = x[2] * y[0] + x[3] * y[1] = 4 * 3 + 5 * 4 = 32(右に2つシフト)
    ans[6] = x[3] * y[0] = 5 * 3 = 15(右に3つシフト)
    """

    # データ長が0の場合はxをコピー
    if len(y) == 0:
        y = x

    # 巡回畳み込み積分を行うためにゼロ埋めした配列を作る
    l_corr = 2 * max((len(x), len(y))) - 1
    xx = np.zeros(l_corr, dtype=np.complex128)
    yy = np.zeros(l_corr, dtype=np.complex128)
    if len(x) == len(y):
        # xx = [0, ... , x]
        # 先頭に0をlen(x)-1個
        for i in range(len(x)):
            xx[len(x) - 1 + i] = x[i]
        # yy = [y, 0, ...]
        # 末尾に0をlen(x)-1個
        for i in range(len(y)):
            yy[i] = y[i]
    elif len(x) > len(y):
        # xx = [0, ... , x]
        # 先頭に0をlen(x)-1個
        for i in range(len(x)):
            xx[len(x) - 1 + i] = x[i]
        # yy = [y, 0, ...]
        # 末尾に0をlen(x)-1 + (len(x)-len(y))個
        for i in range(len(y)):
            yy[i] = y[i]
    elif len(x) < len(y):
        # xx = [0, ... , x, 0, ...]
        # 先頭に0をlen(y)-1個
        # 末尾に0をlen(y)-len(x)個
        for i in range(len(x)):
            xx[len(y) - 1 + i] = x[i]
        # yy = [y, 0, ...]
        # 末尾に0をlen(y)-1個
        for i in range(len(y)):
            yy[i] = y[i]
    XX = np.fft.fft(xx)
    YY = np.fft.fft(yy)
    R = np.fft.ifft(XX * YY.conj())
    return R, np.arange(len(R)) - len(R) // 2


def correlate(
    x: NDArray[np.complex128], y: NDArray[np.complex128]
) -> NDArray[np.complex128]:
    """
    numpy.correlate(mode="full") scipy.signal.correlate()準拠の相関を求める関数
    FFTを用いて計算する。
    len(y) == 0の場合、xの自己相関関数を求めるようにする。
    """

    if len(y) == 0:
        y = x
    l_corr = len(x) + len(y) - 1
    # FFTに入力する用の要素数が2の冪乗の配列を作成
    l_fft: int = 2 ** math.ceil(math.log2(l_corr))
    x1 = np.zeros(l_fft, dtype=np.complex128)
    y1 = np.zeros(l_fft, dtype=np.complex128)
    # 0でpadding
    for i in range(len(x)):
        x1[len(y) - 1 + i] = x[i]
    for i in range(len(y)):
        y1[i] = y[i]

    X1 = np.fft.fft(x1)
    Y1 = np.fft.fft(y1)
    R1 = np.fft.ifft(X1 * Y1.conj())

    # 必要な部分のみを切り取る
    R = np.zeros(l_corr, dtype=np.complex128)
    for i in range(len(R)):
        R[i] = R1[i]

    return R
