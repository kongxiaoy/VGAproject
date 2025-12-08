# VGAproject

目前只有一个demo
VGA_Display为PART1的内容，结构如下：
VGA_Dispaly/
├── src/                         # 设计文件
│   ├── VGA_Video_Top.v          # 顶层模块
│   ├── DST.v                    # 显示扫描定时
│   ├── DDP.v                    # 显示数据处理
│   └── PS.v                     # 边沿检测
├── constraints/                  # 约束文件
│   └── vga_video.xdc            # 引脚约束和时序约束
├── scripts/                      # Python 脚本
│   ├── extract_frames.py        # 提取视频帧
│   └── batch_coe.py             # 批量生成 COE
├── coe_files/                    # COE 文件目录
│   ├── frame_0.coe
│   ├── frame_1.coe
│   └── ...
└── ip/                           # IP 核配置
    └── (Vivado 自动生成)
