# VGA 显示项目 - Nexys4 DDR

## 项目结构

```
vga_project/
├── DST.v                   # 显示扫描定时模块
├── DDP.v                   # 显示数据处理模块
├── PS.v                    # 边沿检测模块
├── vga_white_top.v         # 题目3-1: 白屏显示
├── vga_image_top.v         # 题目3-2: 图片显示
├── vga_video_top.v         # 题目3-3: 视频播放
├── vga_drawpad_top.v       # 题目3-A: 绘图板
├── Nexys4DDR_VGA.xdc       # 约束文件
├── TransToCoe.py           # 图片转COE脚本
└── README.md               # 本文档
```

## 时序参数 (800x600@72Hz)

| 参数 | 值 | 说明 |
|------|-----|------|
| pclk | 50 MHz | 像素时钟 |
| HSW | 120 | 行同步宽度 |
| HBP | 64 | 行后沿 |
| HEN | 800 | 水平有效区 |
| HFP | 56 | 行前沿 |
| VSW | 6 | 场同步宽度 |
| VBP | 23 | 场后沿 |
| VEN | 600 | 垂直有效区 |
| VFP | 37 | 场前沿 |

## 题目3-1: 白屏显示

### 使用方法
1. 在Vivado中创建新项目，选择器件 `xc7a100tcsg324-1`
2. 添加设计文件: `DST.v`, `vga_white_top.v`
3. 添加约束文件: `Nexys4DDR_VGA.xdc`
4. **重要**: 使用 Clocking Wizard IP核生成50MHz时钟
   - IP核配置: Input: 100MHz, Output: 50MHz
   - 替换代码中的 `clk_div` 模块
5. 综合、实现、生成bitstream
6. 烧写到开发板

### 关键点
- 消隐区RGB必须为0（黑色）
- 复位信号低电平有效

## 题目3-2: 图片显示

### 使用方法
1. 准备一张图片（推荐200×150或其整数倍分辨率）
2. 运行转换脚本:
   ```bash
   python TransToCoe.py your_image.jpg result.coe
   ```
3. 在Vivado中创建Block Memory Generator IP核:
   - Memory Type: Single Port ROM
   - Port A Width: 12
   - Port A Depth: 32768
   - Load Init File: 选择生成的 `result.coe`
4. 添加设计文件并替换 `vram_rom` 模块
5. 编译烧写

## 题目3-3: 视频播放

### 使用方法
1. 准备多张图片作为视频帧
2. 运行转换脚本:
   ```bash
   python TransToCoe.py --video frame1.jpg frame2.jpg frame3.jpg frame4.jpg --output video_frames.coe
   ```
3. 创建更大的Block Memory Generator IP核:
   - Port A Depth: 根据帧数调整（每帧30000像素）
4. 调整 `FRAME_COUNT` 和 `FRAME_RATE_DIV` 参数

### 容量计算
- 单帧: 200×150×12bit = 360Kbit
- XC7A100T 有 4,860Kbit BRAM
- 理论最多可存储约13帧

## 题目3-A: 绘图板

### 功能列表
| 功能 | 实现状态 | 操作 |
|------|---------|------|
| 3-A-1: 选择颜色 | ✓ | sw[11:0] |
| 3-A-1: 绘制控制 | ✓ | sw[15] |
| 3-A-1: 方向移动 | ✓ | btnu/btnd/btnl/btnr |
| 3-A-2: 清除画布 | ✓ | rstn |
| 3-A-3: 连续移动 | ✓ | 长按方向键 |
| 3-A-4: 斜向移动 | ✓ | 同时按两个方向键 |
| 3-A-5: 十字光标 | ✓ | 自动显示 |
| 3-A-7: 撤回 | ✓ | btnc |

### IP核需求
- Clocking Wizard: 100MHz → 50MHz
- True Dual Port RAM: 32K×12bit

## IP核配置指南

### Clocking Wizard
1. IP Catalog → FPGA Features → Clocking → Clocking Wizard
2. Input Clock: 100 MHz
3. Output Clock: 50 MHz
4. 取消勾选 "reset" 和 "locked" (可选)

### Block Memory Generator (ROM)
1. IP Catalog → Memories → Block Memory Generator
2. Memory Type: Single Port ROM
3. Port A Options:
   - Width: 12
   - Depth: 32768 (或根据需要)
4. Other Options:
   - Load Init File: 选择.coe文件

### Block Memory Generator (RAM - 绘图板用)
1. Memory Type: True Dual Port RAM
2. Port A: 读取端口 (12bit, 32K depth)
3. Port B: 写入端口 (12bit, 32K depth)

## 常见问题

### Q: 屏幕没有显示？
- 检查pclk是否为50MHz
- 检查同步信号极性（此配置为正极性）
- 检查约束文件端口映射

### Q: 图像显示不正确？
- 确认coe文件格式正确
- 检查DDP模块的放大倍数参数

### Q: 图像偏移或闪烁？
- 检查时序参数是否正确
- 确保消隐区RGB为0

## 参考资料
- VGA时序标准: VESA DMT 1.0
- Xilinx Block Memory Generator User Guide (UG473)
