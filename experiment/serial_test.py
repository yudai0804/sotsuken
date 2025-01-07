import time

import serial

# シリアルポートの設定
# port = (
#     "COM3"  # 使用するポート名 (Windowsの場合: COM3, Linux/Macの場合: /dev/ttyUSB0など)
# )
# port = "/dev/ttyUSB1"
port = "/dev/ttyUSB2"
baudrate = 9600  # ボーレート
timeout = 1  # タイムアウト時間 (秒)

# シリアルポートを開く
ser = serial.Serial(port, baudrate, timeout=timeout)
# ser = serial.Serial(port, baudrate, timeout=timeout)

try:
    # time.sleep(2)  # デバイスの安定化を待つ
    ser.reset_input_buffer()  # 受信バッファをクリア
    ser.reset_output_buffer()  # 送信バッファをクリア
    # データを送信
    # message = "H e l l o , U A R T ! \n"
    message = "abcdefghijklmn"
    ser.write(message.encode())  # 文字列をバイト列に変換して送信
    print(f"Sent: {message.strip()}")

    # データを受信
    # response = ser.readline()  # 1行分のデータを読み取る (タイムアウトで終了)
    while 1:
        if ser.in_waiting:
            data = ser.read()
            print(data)
            # print(ser.readline())
        # if data == bytes(0):
        # continue
finally:
    # シリアルポートを閉じる
    ser.close()
    print("Serial port closed.")
