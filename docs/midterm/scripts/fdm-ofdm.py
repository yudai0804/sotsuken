import matplotlib.pyplot as plt
import numpy as np
import signal

signal.signal(signal.SIGINT, signal.SIG_DFL)

xs = 0
xe = 8 * np.pi
x = np.linspace(xs, xe, 1000)
y_fig1 = np.sin(x)
for i in range(len(y_fig1)):
    if y_fig1[i] < 0:
        y_fig1[i] = 0
y_fig2_sin = np.abs(np.sin(x))
y_fig2_cos = np.abs(np.cos(x))

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 6))
ax1.plot(x, y_fig1, color="red")
ax1.set_title("FDM", fontsize=20)
# ax1.set_xlabel("Frequencty", fontsize=20)
ax1.set_ylabel("Spectrum", fontsize=15)
xticks = []
for i in range(4):
    xticks.append((0.5 + 2 * i) * np.pi)
ax1.set_xticks([])
ax1.vlines(
    xticks,
    ymin=0,
    ymax=1,
    color="black",
    linestyle=":",
)
ax1.grid(False)
ax1.annotate(
    "Guard interval",
    xy=(1.5 * np.pi, 0),
    xytext=(np.pi, 0.25),
    arrowprops=dict(arrowstyle="->"),
    bbox=dict(boxstyle="round", fc="w"),
    fontsize=20,
)
ax1.legend()

ax2.plot(x, y_fig2_sin, color="red")
ax2.plot(x, y_fig2_cos, color="blue")
ax2.set_title("OFDM", fontsize=20)
ax2.set_xlabel("Frequencty", fontsize=15)
ax2.set_ylabel("Spectrum", fontsize=15)
ax2.grid(False)

xticks = []
for i in range(15):
    xticks.append((0.5 + 0.5 * i) * np.pi)
ax2.vlines(
    xticks,
    ymin=0,
    ymax=1,
    color="black",
    linestyle=":",
)
ax2.set_xticks([])

ax2.legend()

plt.tight_layout()
# plt.show()
plt.savefig("../assets/fdm-ofdm.svg")
