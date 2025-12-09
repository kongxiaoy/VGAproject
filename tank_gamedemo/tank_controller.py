#!/usr/bin/env python3
"""
坦克大战 - 键盘控制程序
运行此程序，用笔记本键盘控制FPGA上的坦克游戏

控制方式:
  P1 (绿色坦克): W=上, S=下, A=左, D=右, J=开火
  P2 (蓝色坦克): I=上, K=下, H=左, L=右, N=开火
  
  ESC = 退出程序

使用方法:
  1. 安装依赖: pip install pyserial pynput
  2. 连接FPGA开发板
  3. 运行: python tank_controller.py
  4. 选择正确的COM端口
"""

import serial
import serial.tools.list_ports
import sys
import time

try:
    from pynput import keyboard
except ImportError:
    print("请先安装 pynput: pip install pynput")
    sys.exit(1)

# 按键映射
KEY_MAP = {
    # P1 控制
    'w': ('w', 'W'),  # (按下发送, 松开发送)
    's': ('s', 'S'),
    'a': ('a', 'A'),
    'd': ('d', 'D'),
    'j': ('j', 'J'),
    
    # P2 控制
    'i': ('i', 'I'),
    'k': ('k', 'K'),
    'h': ('h', 'H'),
    'l': ('l', 'L'),
    'n': ('n', 'N'),
}

# 当前按下的键
pressed_keys = set()

def list_ports():
    """列出所有可用的串口"""
    ports = serial.tools.list_ports.comports()
    print("\n可用的串口:")
    for i, port in enumerate(ports):
        print(f"  {i}: {port.device} - {port.description}")
    return ports

def select_port():
    """选择串口"""
    ports = list_ports()
    if not ports:
        print("未找到串口！请检查开发板连接。")
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
        print("无效输入，请重试")

def main():
    print("=" * 50)
    print("   坦克大战 - 键盘控制程序")
    print("=" * 50)
    print("\n控制方式:")
    print("  P1 (绿色): W/S/A/D 移动, J 开火")
    print("  P2 (蓝色): I/K/H/L 移动, N 开火")
    print("  ESC 退出")
    
    # 选择串口
    port = select_port()
    
    # 打开串口
    try:
        ser = serial.Serial(port, 115200, timeout=0.1)
        print(f"\n已连接到 {port}")
        print("开始游戏！按 ESC 退出\n")
    except Exception as e:
        print(f"无法打开串口: {e}")
        sys.exit(1)
    
    # 键盘事件处理
    def on_press(key):
        try:
            k = key.char.lower()
            if k in KEY_MAP and k not in pressed_keys:
                pressed_keys.add(k)
                cmd = KEY_MAP[k][0]  # 按下命令
                ser.write(cmd.encode())
                print(f"按下: {k}")
        except AttributeError:
            pass
    
    def on_release(key):
        # ESC 退出
        if key == keyboard.Key.esc:
            return False
        
        try:
            k = key.char.lower()
            if k in KEY_MAP and k in pressed_keys:
                pressed_keys.discard(k)
                cmd = KEY_MAP[k][1]  # 松开命令
                ser.write(cmd.encode())
                print(f"松开: {k}")
        except AttributeError:
            pass
    
    # 启动键盘监听
    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()
    
    # 清理
    ser.close()
    print("\n程序退出")

if __name__ == "__main__":
    main()
