// 题目3-1: 如果我不曾见过光明
// 顶层模块 - 显示白色屏幕
module vga_white_top (
    input           clk,        // 100MHz 系统时钟
    input           rstn,       // 复位信号（低电平有效）
    
    output          hs,         // 行同步信号
    output          vs,         // 场同步信号
    output [3:0]    red,        // 红色分量
    output [3:0]    green,      // 绿色分量
    output [3:0]    blue        // 蓝色分量
);

    wire pclk;      // 50MHz 像素时钟
    wire hen;       // 水平显示有效
    wire ven;       // 垂直显示有效
    
    // 时钟生成模块：将100MHz转换为50MHz
    // 使用Clocking Wizard IP核，这里用简单的分频器示意
    // 实际使用时应该用IP核生成
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),    // rstn是低有效，reset是高有效，取反
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
    
    // 在有效显示区域显示白色，消隐区显示黑色
    assign red   = (hen & ven) ? 4'hF : 4'h0;
    assign green = (hen & ven) ? 4'hF : 4'h0;
    assign blue  = (hen & ven) ? 4'hF : 4'h0;

endmodule

