import serial

# シリアルポートの設定
# port = (
#     "COM3"  # 使用するポート名 (Windowsの場合: COM3, Linux/Macの場合: /dev/ttyUSB0など)
# )
port = "/dev/ttyUSB1"
baudrate = 115200  # ボーレート
timeout = 1  # タイムアウト時間 (秒)

# シリアルポートを開く
ser = serial.Serial(port, baudrate, timeout=timeout)

try:
    # データを送信
    # message = "H e l l o , U A R T ! \n"
    message = "abcdefghijklmn"
    ser.write(message.encode())  # 文字列をバイト列に変換して送信
    print(f"Sent: {message.strip()}")

    # データを受信
    # response = ser.readline()  # 1行分のデータを読み取る (タイムアウトで終了)
    while 1:
        data = ser.read()
        print(data)
        if data == bytes(0):
            continue
finally:
    # シリアルポートを閉じる
    ser.close()
    print("Serial port closed.")
