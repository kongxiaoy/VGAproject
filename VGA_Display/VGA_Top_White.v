module VGA_Top_White(
    input           clk,      // 100MHz 系统时钟
    input           rstn,
    output          hs,
    output          vs,
    output  [3:0]   red,
    output  [3:0]   green,
    output  [3:0]   blue
);
    wire pclk; // 50MHz
    wire locked;

    // 1. Clocking Wizard IP: 输入100MHz, 输出50MHz
    clk_wiz_0 clk_gen (
        .clk_out1(pclk),
        .resetn(rstn),
        .locked(locked),
        .clk_in1(clk)
    );
    
    wire hen, ven;
    
    // 2. 实例化 DST
    DST dst_inst (
        .rstn(locked), // 等时钟稳定后再复位
        .pclk(pclk),
        .hen(hen),
        .ven(ven),
        .hs(hs),
        .vs(vs)
    );

    // 3. 输出逻辑：有效区域为白色 (FFF)，否则黑色
    assign red   = (hen && ven) ? 4'hF : 4'h0;
    assign green = (hen && ven) ? 4'hF : 4'h0;
    assign blue  = (hen && ven) ? 4'hF : 4'h0;

endmodule