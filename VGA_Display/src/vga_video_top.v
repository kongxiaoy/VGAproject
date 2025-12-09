// 题目3-3: 比bilibili何如�?
// 视频播放模块 - 8帧版�?

module vga_video_top (
    input           clk,
    input           rstn,
    
    output          hs,
    output          vs,
    output [3:0]    red,
    output [3:0]    green,
    output [3:0]    blue
);

    //=========================================================
    // 参数定义
    //=========================================================
    parameter FRAME_COUNT = 5;              // 8�?
    parameter FRAME_SIZE  = 30000;          // 200 * 150
    parameter FRAMES_PER_IMAGE = 4;         // 72/9 = 8fps
    
    //=========================================================
    // 信号定义
    //=========================================================
    wire pclk;
    wire hen, ven;
    wire [14:0] frame_addr;         // DDP输出 0~29999
    wire [11:0] rdata;
    wire [11:0] rgb;
    
    reg [3:0]  frame_idx;           // 0~7
    reg [6:0]  vsync_cnt;
    reg        vs_d;
    wire       vs_falling;
    
    // 关键：帧基地�?，用18�?
    reg [17:0] frame_base_addr;
    
    // 完整地址�?18�?
    wire [17:0] vram_addr;
    
    //=========================================================
    // 时钟
    //=========================================================
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),
        .clk_out1   (pclk)
    );
    
    //=========================================================
    // DST
    //=========================================================
    DST dst_inst (
        .rstn       (rstn),
        .pclk       (pclk),
        .hen        (hen),
        .ven        (ven),
        .hs         (hs),
        .vs         (vs)
    );
    
    //=========================================================
    // DDP
    //=========================================================
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
        .raddr      (frame_addr)
    );
    
    //=========================================================
    // VS下降沿检�?
    //=========================================================
    always @(posedge pclk) begin
        if (!rstn)
            vs_d <= 1'b0;
        else
            vs_d <= vs;
    end
    assign vs_falling = vs_d & (~vs);
    
    //=========================================================
    // 帧切�? + 基地�?累加
    //=========================================================
    always @(posedge pclk) begin
        if (!rstn) begin
            frame_idx <= 4'd0;
            vsync_cnt <= 7'd0;
            frame_base_addr <= 18'd0;
        end
        else if (vs_falling) begin
            if (vsync_cnt >= FRAMES_PER_IMAGE - 1) begin
                vsync_cnt <= 7'd0;
                
                if (frame_idx >= FRAME_COUNT - 1) begin
                    // 回到第一�?
                    frame_idx <= 4'd0;
                    frame_base_addr <= 18'd0;
                end
                else begin
                    // 下一�?
                    frame_idx <= frame_idx + 4'd1;
                    frame_base_addr <= frame_base_addr + 18'd30000;
                end
            end
            else begin
                vsync_cnt <= vsync_cnt + 7'd1;
            end
        end
    end
    
    //=========================================================
    // 地址计算
    //=========================================================
    assign vram_addr = frame_base_addr + {3'b000, frame_addr};
    
    //=========================================================
    // BRAM - 确保IP核地�?�?18�?
    //=========================================================
    blk_mem_gen_4 vram_inst (
        .clka       (pclk),
        .addra      (vram_addr),    // 18位地�?
        .douta      (rdata)
    );
    
    //=========================================================
    // RGB输出
    //=========================================================
    assign red   = rgb[11:8];
    assign green = rgb[7:4];
    assign blue  = rgb[3:0];

endmodule