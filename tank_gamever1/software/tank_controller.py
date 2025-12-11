#!/usr/bin/env python3
"""
坦克大战 - 键盘控制程序 v2.1
支持方向键和小键盘

控制方式:
  === 技能选择阶段 ===
  P1: 1=加速, 2=护盾, 3=穿墙弹, 4=散弹, Q=确认
  P2: 小键盘7=加速, 8=护盾, 9=穿墙弹, 0=散弹, P=确认
  
  === 游戏阶段 ===
  P1 (绿色): W/S/A/D=移动, H=开火, J=技能
  P2 (蓝色): 方向键=移动, 小键盘1=开火, 小键盘2=技能
  
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

# P1 按键映射 (字母键)
P1_KEYS = {
    'w': ('w', 'W'),
    's': ('s', 'S'),
    'a': ('a', 'A'),
    'd': ('d', 'D'),
    'h': ('h', 'H'),
    'j': ('j', 'J'),
}

# P1 技能选择
P1_SKILL_KEYS = {'1': '1', '2': '2', '3': '3', '4': '4', 'q': 'q'}

# P2 方向键映射 (发送的字符可以自己改)
P2_ARROW_PRESS = {
    keyboard.Key.up: 'i',
    keyboard.Key.down: 'k',
    keyboard.Key.left: 'o',
    keyboard.Key.right: 'l',
}
P2_ARROW_RELEASE = {
    keyboard.Key.up: 'I',
    keyboard.Key.down: 'K',
    keyboard.Key.left: 'O',
    keyboard.Key.right: 'L',
}

# P2 小键盘映射
# 小键盘数字在pynput中可能是 KeyCode 或特殊值
# 这里用 vk (virtual key) 来识别
# 小键盘 0-9 的 vk 码: 96-105
NUMPAD_VK = {
    96: '0',   # 小键盘 0 - P2技能选择
    97: '1',   # 小键盘 1 - P2开火 (按下n, 松开N)
    98: '2',   # 小键盘 2 - P2技能 (按下m, 松开M)
    103: '7',  # 小键盘 7 - P2技能选择
    104: '8',  # 小键盘 8 - P2技能选择
    105: '9',  # 小键盘 9 - P2技能选择
}

# 小键盘动作键 (需要按下/松开)
NUMPAD_ACTION = {
    97: ('n', 'N'),  # 小键盘1 = 开火
    98: ('m', 'M'),  # 小键盘2 = 技能
}

# 小键盘技能选择键 (只发送一次)
NUMPAD_SKILL = {
    96: '0',   # 小键盘0
    103: '7',  # 小键盘7
    104: '8',  # 小键盘8
    105: '9',  # 小键盘9
}

pressed_keys = set()
pressed_vk = set()

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
    print("=" * 60)
    print("           坦克大战 - 键盘控制程序 v2.1")
    print("=" * 60)
    print()
    print("【技能选择阶段】")
    print("  P1: 按 1/2/3/4 选择技能，按 Q 确认")
    print("  P2: 按 小键盘7/8/9/0 选择技能，按 P 确认")
    print()
    print("  技能说明:")
    print("    1/小键盘7 = 加速 (10秒内速度翻倍)")
    print("    2/小键盘8 = 护盾 (抵挡一次伤害)")
    print("    3/小键盘9 = 穿墙弹 (3发子弹穿墙)")
    print("    4/小键盘0 = 散弹 (3次扇形发射)")
    print()
    print("【游戏阶段】")
    print("  P1 (绿色): W/S/A/D 移动, H 开火, J 技能")
    print("  P2 (蓝色): 方向键 移动, 小键盘1 开火, 小键盘2 技能")
    print()
    print("  R = 重新开始游戏")
    print("  ESC = 退出程序")
    print()
    print("-" * 60)

def main():
    print_help()
    
    port = select_port()
    
    try:
        ser = serial.Serial(port, 115200, timeout=0.1)
        print(f"\n已连接到 {port}")
        print("等待技能选择...\n")
    except Exception as e:
        print(f"无法打开串口: {e}")
        sys.exit(1)
    
    def on_press(key):
        # 处理方向键
        if key in P2_ARROW_PRESS:
            if key not in pressed_keys:
                pressed_keys.add(key)
                cmd = P2_ARROW_PRESS[key]
                ser.write(cmd.encode())
                print(f"P2 按下: {key}")
            return
        
        # 处理小键盘 (通过 vk 码)
        try:
            vk = key.vk
            if vk in NUMPAD_ACTION:
                if vk not in pressed_vk:
                    pressed_vk.add(vk)
                    cmd = NUMPAD_ACTION[vk][0]
                    ser.write(cmd.encode())
                    print(f"P2 按下: 小键盘{vk-96}")
                return
            if vk in NUMPAD_SKILL:
                cmd = NUMPAD_SKILL[vk]
                ser.write(cmd.encode())
                print(f"P2 选择: 小键盘{vk-96}")
                return
        except AttributeError:
            pass
        
        # 处理字母键
        try:
            k = key.char.lower()
            
            # P1 技能选择
            if k in P1_SKILL_KEYS:
                ser.write(P1_SKILL_KEYS[k].encode())
                print(f"P1 选择: {k}")
                return
            
            # P2 确认键
            if k == 'p':
                ser.write(b'p')
                print("P2 确认")
                return
            
            # 游戏复位
            if k == 'r':
                ser.write(b'r')
                print("游戏复位!")
                return
            
            # P1 移动/动作键
            if k in P1_KEYS and k not in pressed_keys:
                pressed_keys.add(k)
                cmd = P1_KEYS[k][0]
                ser.write(cmd.encode())
                print(f"P1 按下: {k}")
        except AttributeError:
            pass
    
    def on_release(key):
        if key == keyboard.Key.esc:
            return False
        
        # 处理方向键松开
        if key in P2_ARROW_RELEASE:
            if key in pressed_keys:
                pressed_keys.discard(key)
                cmd = P2_ARROW_RELEASE[key]
                ser.write(cmd.encode())
                print(f"P2 松开: {key}")
            return
        
        # 处理小键盘松开
        try:
            vk = key.vk
            if vk in NUMPAD_ACTION:
                if vk in pressed_vk:
                    pressed_vk.discard(vk)
                    cmd = NUMPAD_ACTION[vk][1]
                    ser.write(cmd.encode())
                    print(f"P2 松开: 小键盘{vk-96}")
                return
        except AttributeError:
            pass
        
        # 处理字母键松开
        try:
            k = key.char.lower()
            if k in P1_KEYS and k in pressed_keys:
                pressed_keys.discard(k)
                cmd = P1_KEYS[k][1]
                ser.write(cmd.encode())
                print(f"P1 松开: {k}")
        except AttributeError:
            pass
    
    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()
    
    ser.close()
    print("\n程序退出")

if __name__ == "__main__":
    main()