// 题目3-2: 让世界热闹起来！
// 顶层模块 - 显示图片
module vga_image_top (
    input           clk,        // 100MHz 系统时钟
    input           rstn,       // 复位信号（低电平有效）
    
    output          hs,         // 行同步信号
    output          vs,         // 场同步信号
    output [3:0]    red,
    output [3:0]    green,
    output [3:0]    blue
);

    wire pclk;              // 50MHz 像素时钟
    wire hen;               // 水平显示有效
    wire ven;               // 垂直显示有效
    wire [14:0] raddr;      // VRAM读地址
    wire [11:0] rdata;      // VRAM读数据
    wire [11:0] rgb;        // RGB输出
    
    // 时钟生成模块：Clocking Wizard IP核
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),
        .clk_out1   (pclk)
    );
    
    // 显示扫描定时模块
    DST dst_inst (
        .rstn       (rstn),
        .pclk       (pclk),
        .hen        (hen),
        .ven        (ven),
        .hs         (hs),
        .vs         (vs)
    );
    
    // 显示数据处理模块
    DDP #(
        .DW     (15),
        .H_LEN  (200),
        .V_LEN  (150)
    ) ddp_inst (
        .hen        (hen),
        .ven        (ven),
        .rstn       (rstn),
        .pclk       (pclk),
        .rdata      (rdata),
        .rgb        (rgb),
        .raddr      (raddr)
    );
    
    // VRAM - Block Memory Generator IP核
    // 配置：Single Port ROM, 12bit x 32768, 加载coe文件
    blk_mem_gen_0 vram_inst (
        .clka       (pclk),         // 时钟
        .addra      (raddr),        // 地址 [14:0]
        .douta      (rdata)         // 数据输出 [11:0]
    );
    
    // RGB输出
    assign red   = rgb[11:8];
    assign green = rgb[7:4];
    assign blue  = rgb[3:0];

endmodule
