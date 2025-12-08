# VGA 视频播放器项目 - 题目 3-3

## 项目简介

本项目实现了一个基于 FPGA 的 VGA 视频播放器，能够循环播放 10 帧视频。

- **开发板**: Nexys 4 DDR (XC7A100T-CSG324)
- **分辨率**: 800x600 @ 72Hz
- **画布大小**: 200x150 (4倍放大)
- **颜色深度**: RGB444 (12-bit)
- **帧率**: 可调节 (默认 12 FPS)

---

## 项目结构

```
VGA_Video_Project/
├── rtl/                          # RTL 设计文件
│   ├── VGA_Video_Top.v          # 顶层模块 ✅
│   ├── DST.v                    # 显示扫描定时 ✅
│   ├── DDP.v                    # 显示数据处理 ✅
│   └── PS.v                     # 边沿检测 ✅
├── constraints/
│   └── vga_video.xdc            # 约束文件 ✅
├── scripts/
│   ├── extract_frames.py        # 提取视频帧 ✅
│   ├── batch_coe.py             # 生成COE文件 ✅
│   └── setup_project.tcl        # Vivado自动化脚本 ✅
├── frames/                       # 提取的帧图片 (生成)
├── coe_files/                    # COE 文件 (生成)
└── vivado_project/               # Vivado 项目 (生成)
```

---

## 实现步骤

### 第一步：准备视频素材

1. **安装 Python 依赖**
   ```bash
   pip install opencv-python pillow
   ```

2. **提取视频帧**
   ```bash
   cd scripts
   python extract_frames.py your_video.mp4 10 ../frames
   ```
   
   参数说明：
   - `your_video.mp4`: 视频文件路径
   - `10`: 提取帧数
   - `../frames`: 输出目录

3. **检查输出**
   - 查看 `frames/` 目录，应该有 `frame_0.jpg` 到 `frame_9.jpg`

---

### 第二步：生成 COE 文件

```bash
cd scripts
python batch_coe.py ../frames ../coe_files 10
```

输出：
- `coe_files/frame_0.coe` 到 `frame_9.coe`
- 每个文件约 400-500 KB

---

### 第三步：创建 Vivado 项目

#### 方法一：使用 TCL 脚本自动创建（推荐）

```bash
# 在 Vivado TCL Console 中执行
cd scripts
source setup_project.tcl
```

该脚本会自动：
- 创建项目
- 添加所有 RTL 文件
- 添加约束文件
- 创建 Clocking Wizard IP
- 创建 10 个 Block RAM IP（自动加载 COE 文件）

#### 方法二：手动创建

1. **创建新项目**
   - File → Project → New
   - 选择 Part: `xc7a100tcsg324-1`

2. **添加设计文件**
   - Add Sources → Add or create design sources
   - 添加 `rtl/` 目录下的所有 `.v` 文件
   - 设置 `VGA_Video_Top` 为顶层模块

3. **添加约束文件**
   - Add Sources → Add or create constraints
   - 添加 `constraints/vga_video.xdc`

4. **创建 Clocking Wizard**
   - IP Catalog → Clocking Wizard
   - 配置：
     - Input: 100 MHz
     - Output: 50 MHz
   - 命名：`clk_wiz_0`

5. **创建 Block RAM (重复 10 次)**
   - IP Catalog → Block Memory Generator
   - 配置：
     - Memory Type: **Single Port ROM**
     - Port A Width: **12**
     - Port A Depth: **32768**
     - 勾选 **Load Init File**
     - 选择对应的 `frame_X.coe`
   - 命名：`VRAM_frame0` 到 `VRAM_frame9`

---

### 第四步：综合与实现

1. **运行综合**
   ```tcl
   launch_runs synth_1 -jobs 4
   wait_on_run synth_1
   ```

2. **运行实现**
   ```tcl
   launch_runs impl_1 -to_step write_bitstream -jobs 4
   wait_on_run impl_1
   ```

3. **检查资源使用**
   - 打开 Synthesis Report
   - 确认 BRAM 使用量约 10 个 (7.4%)

---

### 第五步：下载比特流

1. **连接开发板**
   - 使用 USB 线连接 Nexys 4 DDR
   - 确保开关打开

2. **编程 FPGA**
   - Open Hardware Manager
   - Auto Connect
   - Program Device
   - 选择生成的 `.bit` 文件

3. **观察效果**
   - VGA 屏幕应显示循环播放的视频
   - LED[3:0] 显示当前帧号 (0-9)

---

## 调试技巧

### 常见问题

**Q1: 屏幕无显示**
- 检查时钟是否正确（50MHz）
- 检查 `rstn` 是否连接正确（低电平复位）
- 确认 VGA 线缆连接正确

**Q2: 显示颜色异常**
- 检查 COE 文件格式
- 确认 RGB 通道赋值顺序
- 验证单帧图片能否正常显示（题目 3-2）

**Q3: 视频不流畅**
- 降低帧率到 6-8 FPS
- 检查时钟 `locked` 信号
- 确认 BRAM 配置正确

**Q4: 综合失败**
- 检查所有 IP 核是否正确生成
- 确认 COE 文件路径正确
- 查看 Critical Warnings

### 使用 ILA 调试

如需调试内部信号，添加 ILA IP：

```tcl
create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
connect_debug_port u_ila_0/clk [get_nets pclk]

# 添加探测信号
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets {frame_cnt[*]}]
```

---

## 参数调整

### 修改帧率

在 `VGA_Video_Top.v` 中修改：

```verilog
localparam FPS = 12;  // 修改为期望的帧率
```

可选值：6, 10, 12, 15, 20, 24

### 修改帧数

1. 准备更多/更少的图片
2. 修改 `VGA_Video_Top.v`:
   ```verilog
   localparam NUM_FRAMES = 10;  // 修改帧数
   ```
3. 添加/删除对应的 ROM 实例

---

## 扩展功能

### 添加播放控制

可以添加以下功能：

1. **播放/暂停** (sw[15])
2. **帧率调节** (sw[14:12])
3. **反向播放** (sw[11])
4. **单步播放** (btnu/btnd)

参考代码见顶层模块注释。

---

## 资源消耗

| 资源 | 使用量 | 总量 | 占比 |
|------|--------|------|------|
| LUT | ~500 | 63,400 | <1% |
| FF | ~300 | 126,800 | <1% |
| BRAM (36Kb) | 10 | 135 | 7.4% |
| DSP | 0 | 240 | 0% |

---

## 参考资料

- VGA 时序标准：VESA DMT
- 800x600@72Hz 参数
- Nexys 4 DDR 参考手册
- Vivado Block RAM 用户指南 (UG473)

---

## 作者

题目 3-3 参考实现

## 许可

仅供学习参考使用