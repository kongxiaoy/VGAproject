#!/usr/bin/env python3
"""
吃豆人 - 键盘控制程序

控制方式:
  W/S/A/D = 上/下/左/右
  R = 重新开始
  ESC = 退出程序
"""

import serial
import serial.tools.list_ports
import sys
import os

try:
    from pynput import keyboard
except ImportError:
    print("请先安装 pynput: pip install pynput")
    sys.exit(1)

# 按键映射
KEY_MAP = {
    'w': ('w', 'W'),  # 按下, 松开
    's': ('s', 'S'),
    'a': ('a', 'A'),
    'd': ('d', 'D'),
    'r': ('r', 'R'),
}

pressed_keys = set()

def list_ports():
    ports = serial.tools.list_ports.comports()
    print("\n可用的串口:")
    for i, port in enumerate(ports):
        print(f"  {i}: {port.device} - {port.description}")
    return ports

def select_port():
    ports = list_ports()
    if not ports:
        print("未找到串口！")
        sys.exit(1)
    
    if len(ports) == 1:
        print(f"\n自动选择: {ports[0].device}")
        return ports[0].device
    
    while True:
        try:
            idx = int(input("\n请输入串口编号: "))
            if 0 <= idx < len(ports):
                return ports[idx].device
        except ValueError:
            pass
        print("无效输入")

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_help():
    clear_screen()
    print("=" * 50)
    print("         吃豆人 - 键盘控制程序")
    print("=" * 50)
    print()
    print("【游戏控制】")
    print("  W = 上")
    print("  S = 下")
    print("  A = 左")
    print("  D = 右")
    print()
    print("【其他按键】")
    print("  R = 重新开始")
    print("  ESC = 退出程序")
    print()
    print("-" * 50)
    print("提示: 按方向键开始游戏")
    print("      吃完所有豆子获胜，碰到幽灵失败")
    print("-" * 50)

def main():
    print_help()
    
    port = select_port()
    
    try:
        ser = serial.Serial(port, 115200, timeout=0.1)
        print(f"\n已连接到 {port}")
        print("按 W/S/A/D 开始游戏...\n")
    except Exception as e:
        print(f"无法打开串口: {e}")
        sys.exit(1)
    
    def on_press(key):
        try:
            k = key.char.lower()
            if k in KEY_MAP and k not in pressed_keys:
                pressed_keys.add(k)
                cmd = KEY_MAP[k][0]
                ser.write(cmd.encode())
                print(f"按下: {k.upper()}")
        except AttributeError:
            pass
    
    def on_release(key):
        if key == keyboard.Key.esc:
            return False
        
        try:
            k = key.char.lower()
            if k in KEY_MAP and k in pressed_keys:
                pressed_keys.discard(k)
                cmd = KEY_MAP[k][1]
                ser.write(cmd.encode())
                print(f"松开: {k.upper()}")
        except AttributeError:
            pass
    
    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()
    
    ser.close()
    print("\n程序退出")

if __name__ == "__main__":
    main()
