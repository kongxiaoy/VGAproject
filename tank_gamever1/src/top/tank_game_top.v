// 双人坦克大战 - 顶层模块

module tank_game_top (
    input           clk,
    input           rstn,
    
    // UART
    input           uart_rx,
    
    // VGA
    output          hs,
    output          vs,
    output [3:0]    red,
    output [3:0]    green,
    output [3:0]    blue,
    
    // LED
    output [15:0]   led
);

    // 时钟
    wire pclk;
    wire locked;
    
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),
        .clk_out1   (pclk),
        .locked     (locked)
    );
    
    wire sys_rstn = rstn & locked;
    
    // UART 接收
    wire [7:0] rx_data;
    wire rx_valid;
    
    uart_rx uart_inst (
        .clk        (clk),
        .rstn       (sys_rstn),
        .rx         (uart_rx),
        .data       (rx_data),
        .valid      (rx_valid)
    );
    
    // 按键解码
    wire p1_up, p1_down, p1_left, p1_right, p1_fire, p1_skill;
    wire p2_up, p2_down, p2_left, p2_right, p2_fire, p2_skill;
    wire [1:0] p1_skill_sel, p2_skill_sel;
    wire p1_ready, p2_ready;
    wire game_reset;
    
    uart_key_decoder key_dec (
        .clk            (clk),
        .rstn           (sys_rstn),
        .rx_data        (rx_data),
        .rx_valid       (rx_valid),
        .p1_up          (p1_up),
        .p1_down        (p1_down),
        .p1_left        (p1_left),
        .p1_right       (p1_right),
        .p1_fire        (p1_fire),
        .p1_skill       (p1_skill),
        .p1_skill_sel   (p1_skill_sel),
        .p1_ready       (p1_ready),
        .p2_up          (p2_up),
        .p2_down        (p2_down),
        .p2_left        (p2_left),
        .p2_right       (p2_right),
        .p2_fire        (p2_fire),
        .p2_skill       (p2_skill),
        .p2_skill_sel   (p2_skill_sel),
        .p2_ready       (p2_ready),
        .game_reset     (game_reset)
    );
    
    // VGA 时序
    wire hen, ven;
    
    DST dst_inst (
        .rstn       (sys_rstn),
        .pclk       (pclk),
        .hen        (hen),
        .ven        (ven),
        .hs         (hs),
        .vs         (vs)
    );
    
    // 像素坐标
    wire [7:0] pixel_x;
    wire [8:0] pixel_y;
    wire in_display;
    
    game_ddp ddp_inst (
        .hen        (hen),
        .ven        (ven),
        .rstn       (sys_rstn),
        .pclk       (pclk),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .in_display (in_display)
    );
    
    // 游戏控制器
    wire [11:0] game_rgb;
    wire game_start, game_over, p1_win;
    
    game_ctrl game_inst (
        .clk            (clk),
        .pclk           (pclk),
        .rstn           (sys_rstn),
        .game_reset     (game_reset),
        .p1_up          (p1_up),
        .p1_down        (p1_down),
        .p1_left        (p1_left),
        .p1_right       (p1_right),
        .p1_fire        (p1_fire),
        .p1_skill       (p1_skill),
        .p2_up          (p2_up),
        .p2_down        (p2_down),
        .p2_left        (p2_left),
        .p2_right       (p2_right),
        .p2_fire        (p2_fire),
        .p2_skill       (p2_skill),
        .p1_skill_sel   (p1_skill_sel),
        .p2_skill_sel   (p2_skill_sel),
        .p1_ready       (p1_ready),
        .p2_ready       (p2_ready),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .in_display     (in_display),
        .rgb            (game_rgb),
        .game_start     (game_start),
        .game_over      (game_over),
        .p1_win         (p1_win)
    );
    
    // VGA输出
    assign red   = (hen & ven) ? game_rgb[11:8] : 4'h0;
    assign green = (hen & ven) ? game_rgb[7:4]  : 4'h0;
    assign blue  = (hen & ven) ? game_rgb[3:0]  : 4'h0;
    
    // LED 显示状态
    assign led[0] = p1_up;
    assign led[1] = p1_down;
    assign led[2] = p1_left;
    assign led[3] = p1_right;
    assign led[4] = p1_fire;
    assign led[5] = p1_skill;
    assign led[6] = p1_ready;
    assign led[7] = game_start;
    assign led[8] = p2_up;
    assign led[9] = p2_down;
    assign led[10] = p2_left;
    assign led[11] = p2_right;
    assign led[12] = p2_fire;
    assign led[13] = p2_skill;
    assign led[14] = p2_ready;
    assign led[15] = game_over;

endmodule