module VGA_Image_Top(
    input           clk,
    input           rstn,
    output          hs,
    output          vs,
    output  [3:0]   red,
    output  [3:0]   green,
    output  [3:0]   blue
);

    wire pclk, locked;
    
    // 1. 时钟 (100M -> 50M)
    clk_wiz_0 clk_gen (
        .clk_out1(pclk),
        .resetn(rstn),
        .locked(locked),
        .clk_in1(clk)
    );

    wire hen, ven;
    wire [11:0] rgb_out;
    wire [11:0] vram_data;
    wire [14:0] vram_addr; // 32K 深度需要 15 位地址

    // 2. DST 模块
    DST dst_inst (
        .rstn(locked),
        .pclk(pclk),
        .hen(hen),
        .ven(ven),
        .hs(hs),
        .vs(vs)
    );

    // 3. VRAM (Block Memory Generator)
    // 实例化你生成的 IP 核名称，例如 blk_mem_gen_0
    blk_mem_gen_0 vram_inst (
        .clka(pclk),    
        .addra(vram_addr), 
        .douta(vram_data) 
    );

    // 4. DDP 模块 (题目代码需要包含 PS 模块)
    DDP #(
        .DW(15), 
        .H_LEN(200), 
        .V_LEN(150)
    ) ddp_inst (
        .hen(hen),
        .ven(ven),
        .rstn(locked),
        .pclk(pclk),
        .rdata(vram_data),
        .rgb(rgb_out),
        .raddr(vram_addr)
    );

    assign red   = rgb_out[11:8];
    assign green = rgb_out[7:4];
    assign blue  = rgb_out[3:0];

endmodule