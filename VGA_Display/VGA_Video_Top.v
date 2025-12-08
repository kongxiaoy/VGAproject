// VGA 视频播放器顶层模块
// 支持 10 帧循环播放，基于 XC7A100T
module VGA_Video_Top(
    input               clk,        // 100MHz 系统时钟
    input               rstn,       // 复位键（低电平有效）
    
    // VGA 输出
    output              hs,         // 行同步
    output              vs,         // 场同步
    output      [3:0]   red,        // 红色通道
    output      [3:0]   green,      // 绿色通道
    output      [3:0]   blue,       // 蓝色通道
    
    // 调试输出（可选）
    output      [7:0]   led         // 显示当前帧号
);

    // ==================== 参数定义 ====================
    parameter NUM_FRAMES = 10;                      // 总帧数
    parameter FPS = 12;                             // 帧率 (帧/秒)
    parameter FRAME_TIMER = 50_000_000 / FPS;       // 帧切换周期
    
    // ==================== 内部信号 ====================
    wire                pclk;       // 50MHz 像素时钟
    wire                hen, ven;   // 水平/垂直显示有效
    wire    [14:0]      raddr;      // 读地址 (0-29999)
    wire    [11:0]      rgb_out;    // DDP 输出的 RGB
    
    reg     [3:0]       frame_cnt;  // 当前帧号 (0-9)
    reg     [25:0]      timer;      // 帧切换定时器
    reg     [11:0]      rdata;      // 当前帧的像素数据
    
    // ==================== 时钟生成 ====================
    // 使用 Clocking Wizard IP 生成 50MHz 像素时钟
    clk_wiz_0 clk_gen(
        .clk_in1    (clk),
        .clk_out1   (pclk),
        .reset      (!rstn),
        .locked     ()
    );
    
    // ==================== ROM 实例化 ====================
    // 每一帧对应一个独立的 Block RAM
    wire [11:0] frame_data [0:NUM_FRAMES-1];
    
    VRAM_frame0 rom0 (.addra(raddr), .douta(frame_data[0]), .clka(pclk), .ena(1'b1));
    VRAM_frame1 rom1 (.addra(raddr), .douta(frame_data[1]), .clka(pclk), .ena(1'b1));
    VRAM_frame2 rom2 (.addra(raddr), .douta(frame_data[2]), .clka(pclk), .ena(1'b1));
    VRAM_frame3 rom3 (.addra(raddr), .douta(frame_data[3]), .clka(pclk), .ena(1'b1));
    VRAM_frame4 rom4 (.addra(raddr), .douta(frame_data[4]), .clka(pclk), .ena(1'b1));
    VRAM_frame5 rom5 (.addra(raddr), .douta(frame_data[5]), .clka(pclk), .ena(1'b1));
    VRAM_frame6 rom6 (.addra(raddr), .douta(frame_data[6]), .clka(pclk), .ena(1'b1));
    VRAM_frame7 rom7 (.addra(raddr), .douta(frame_data[7]), .clka(pclk), .ena(1'b1));
    VRAM_frame8 rom8 (.addra(raddr), .douta(frame_data[8]), .clka(pclk), .ena(1'b1));
    VRAM_frame9 rom9 (.addra(raddr), .douta(frame_data[9]), .clka(pclk), .ena(1'b1));
    
    // ==================== 帧切换逻辑 ====================
    always @(posedge pclk or negedge rstn) begin
        if (!rstn) begin
            timer <= 26'd0;
            frame_cnt <= 4'd0;
        end
        else begin
            if (timer >= FRAME_TIMER - 1) begin
                timer <= 26'd0;
                // 循环播放
                if (frame_cnt >= NUM_FRAMES - 1)
                    frame_cnt <= 4'd0;
                else
                    frame_cnt <= frame_cnt + 1'b1;
            end
            else begin
                timer <= timer + 1'b1;
            end
        end
    end
    
    // ==================== 数据选择逻辑 ====================
    // 根据当前帧号选择对应的 ROM 数据
    always @(*) begin
        case (frame_cnt)
            4'd0:  rdata = frame_data[0];
            4'd1:  rdata = frame_data[1];
            4'd2:  rdata = frame_data[2];
            4'd3:  rdata = frame_data[3];
            4'd4:  rdata = frame_data[4];
            4'd5:  rdata = frame_data[5];
            4'd6:  rdata = frame_data[6];
            4'd7:  rdata = frame_data[7];
            4'd8:  rdata = frame_data[8];
            4'd9:  rdata = frame_data[9];
            default: rdata = frame_data[0];
        endcase
    end
    
    // ==================== DST 模块（显示扫描定时）====================
    DST dst_inst(
        .rstn   (rstn),
        .pclk   (pclk),
        .hen    (hen),
        .ven    (ven),
        .hs     (hs),
        .vs     (vs)
    );
    
    // ==================== DDP 模块（显示数据处理）====================
    DDP #(
        .DW     (15),
        .H_LEN  (200),
        .V_LEN  (150)
    ) ddp_inst(
        .hen    (hen),
        .ven    (ven),
        .rstn   (rstn),
        .pclk   (pclk),
        .rdata  (rdata),
        .rgb    (rgb_out),
        .raddr  (raddr)
    );
    
    // ==================== 输出分配 ====================
    assign red   = rgb_out[11:8];
    assign green = rgb_out[7:4];
    assign blue  = rgb_out[3:0];
    
    // 调试：LED 显示当前帧号（可选）
    assign led = {4'b0, frame_cnt};

endmodule