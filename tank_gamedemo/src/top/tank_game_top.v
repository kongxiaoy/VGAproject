// 双人坦克大战 - 顶层模块 (串口键盘版)
// 通过USB-UART接收电脑键盘输入

module tank_game_top (
    input           clk,            // 100MHz
    input           rstn,           // 复位
    
    // UART (通过USB连接电脑)
    input           uart_rx,        // 接收
    
    // VGA
    output          hs,
    output          vs,
    output [3:0]    red,
    output [3:0]    green,
    output [3:0]    blue,
    
    // LED (显示按键状态)
    output [7:0]    led
);

    // 时钟
    wire pclk;
    
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),
        .clk_out1   (pclk)
    );
    
    // UART 接收
    wire [7:0] rx_data;
    wire rx_valid;
    
    uart_rx uart_inst (
        .clk        (clk),
        .rstn       (rstn),
        .rx         (uart_rx),
        .data       (rx_data),
        .valid      (rx_valid)
    );
    
    // 按键解码
    wire p1_up, p1_down, p1_left, p1_right, p1_fire;
    wire p2_up, p2_down, p2_left, p2_right, p2_fire;
    
    uart_key_decoder key_dec (
        .clk        (clk),
        .rstn       (rstn),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .p1_up      (p1_up),
        .p1_down    (p1_down),
        .p1_left    (p1_left),
        .p1_right   (p1_right),
        .p1_fire    (p1_fire),
        .p2_up      (p2_up),
        .p2_down    (p2_down),
        .p2_left    (p2_left),
        .p2_right   (p2_right),
        .p2_fire    (p2_fire)
    );
    
    // VGA 时序
    wire hen, ven;
    
    DST dst_inst (
        .rstn       (rstn),
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
        .rstn       (rstn),
        .pclk       (pclk),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .in_display (in_display)
    );
    
    // 游戏控制器
    wire [11:0] game_rgb;
    wire game_over, p1_win;
    
    game_ctrl game_inst (
        .clk        (clk),
        .pclk       (pclk),
        .rstn       (rstn),
        .p1_up      (p1_up),
        .p1_down    (p1_down),
        .p1_left    (p1_left),
        .p1_right   (p1_right),
        .p1_fire    (p1_fire),
        .p2_up      (p2_up),
        .p2_down    (p2_down),
        .p2_left    (p2_left),
        .p2_right   (p2_right),
        .p2_fire    (p2_fire),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .in_display (in_display),
        .rgb        (game_rgb),
        .game_over  (game_over),
        .p1_win     (p1_win)
    );
    
    // VGA输出
    assign red   = (hen & ven) ? game_rgb[11:8] : 4'h0;
    assign green = (hen & ven) ? game_rgb[7:4]  : 4'h0;
    assign blue  = (hen & ven) ? game_rgb[3:0]  : 4'h0;
    
    // LED
    assign led[0] = p1_up;
    assign led[1] = p1_down;
    assign led[2] = p1_left;
    assign led[3] = p1_right;
    assign led[4] = p2_up;
    assign led[5] = p2_down;
    assign led[6] = p2_left;
    assign led[7] = p2_right;

endmodule