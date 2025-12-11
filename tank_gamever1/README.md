# 双人坦克大战 v2.2

## 更新内容

- ✅ 修复P1出生位置（不再卡在墙里）
- ✅ 技能选择界面添加文字（P1/P2标题、数字1234/7890）
- ✅ 添加R键游戏复位功能
- ✅ 获胜界面显示 "P1 WIN" 或 "P2 WIN"
- ✅ 子弹反弹功能（最多3次）
- ✅ 子弹速度为坦克1.5倍

## 控制方式

### 技能选择阶段

| 玩家 | 技能选择 | 确认 |
|------|---------|------|
| P1 | 1=加速, 2=护盾, 3=穿墙弹, 4=散弹 | Q |
| P2 | 小键盘7=加速, 8=护盾, 9=穿墙弹, 0=散弹 | P |

### 游戏阶段

| 玩家 | 移动 | 开火 | 技能 |
|------|------|------|------|
| P1 (绿色) | W/S/A/D | H | J |
| P2 (蓝色) | 方向键 | 小键盘1 | 小键盘2 |

### 其他按键

| 按键 | 功能 |
|------|------|
| R | 游戏复位（重新开始） |
| ESC | 退出控制程序 |

## 技能说明

| 技能 | 颜色条 | 效果 |
|------|--------|------|
| 加速 | 红色 | 速度翻倍10秒 |
| 护盾 | 青色 | 抵挡一次伤害 |
| 穿墙弹 | 黄色 | 3发子弹穿墙 |
| 散弹 | 紫色 | 3次扇形发射 |

## 可修改参数

### tank.v (约55-62行)
```verilog
localparam SPEED_NORMAL = 1;        // 正常速度
localparam SPEED_BOOST = 2;         // 加速后速度
localparam BOOST_DURATION = 300;    // 加速持续10秒
localparam PIERCE_INIT = 3;         // 穿墙弹次数
localparam SPREAD_INIT = 3;         // 散弹次数
localparam FIRE_COOLDOWN = 15;      // 开火冷却 (约0.5秒)
```

### bullet.v (约40行)
```verilog
localparam BULLET_MOVE_PIXELS = 2;  // 子弹速度
localparam MAX_BOUNCES = 3;          // 最大反弹次数
```

## 使用步骤

1. Vivado导入所有.v文件和.xdc约束
2. 创建clk_wiz_0 IP (100MHz → 50MHz)
3. 综合、实现、生成Bitstream
4. 烧写FPGA
5. 运行 `python tank_controller.py`
6. P1按1-4选技能，按Q确认
7. P2按小键盘7-0选技能，按P确认
8. 游戏开始！
9. 游戏结束后按R重新开始

## 文件结构

```
tank_game/
├── README.md
├── constraint/tank_game.xdc
├── software/tank_controller.py
└── src/
    ├── top/tank_game_top.v
    ├── input/
    │   ├── uart_rx.v
    │   └── uart_key_decoder.v (支持R复位)
    ├── vga/
    │   ├── DST.v
    │   ├── game_ddp.v
    │   └── renderer.v (带像素字体)
    └── game/
        ├── game_ctrl.v (支持软件复位)
        ├── tank.v
        ├── bullet.v (反弹逻辑)
        ├── collision.v
        └── map.v
```

祝游戏愉快！🎮