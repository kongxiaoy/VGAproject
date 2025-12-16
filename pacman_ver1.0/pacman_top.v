// 吃豆人 - 顶层模块
// xc7a100t, 100MHz, VGA 800x600@72Hz

module pacman_top (
    input           clk,        // 100MHz
    input           rstn,       // 低有效复位
    
    // UART
    input           uart_rx,
    
    // VGA
    output          hs,
    output          vs,
    output [3:0]    red,
    output [3:0]    green,
    output [3:0]    blue,
    
    // LED (可选调试)
    output [7:0]    led
);

    // ========================================
    // 时钟生成 (100MHz -> 50MHz)
    // ========================================
    wire pclk;
    wire locked;
    
    clk_wiz_0 clk_gen (
        .clk_in1    (clk),
        .reset      (~rstn),
        .clk_out1   (pclk),
        .locked     (locked)
    );
    
    wire sys_rstn = rstn & locked;
    
    // ========================================
    // UART 接收
    // ========================================
    wire [7:0] rx_data;
    wire rx_valid;
    
    uart_rx uart_inst (
        .clk    (clk),
        .rstn   (sys_rstn),
        .rx     (uart_rx),
        .data   (rx_data),
        .valid  (rx_valid)
    );
    
    // ========================================
    // 按键解码
    // ========================================
    wire key_up, key_down, key_left, key_right, key_reset;
    
    pacman_input input_inst (
        .clk        (clk),
        .rstn       (sys_rstn),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .key_up     (key_up),
        .key_down   (key_down),
        .key_left   (key_left),
        .key_right  (key_right),
        .key_reset  (key_reset)
    );
    
    // ========================================
    // VGA 时序生成
    // ========================================
    wire hen, ven;
    
    DST dst_inst (
        .rstn   (sys_rstn),
        .pclk   (pclk),
        .hen    (hen),
        .ven    (ven),
        .hs     (hs),
        .vs     (vs)
    );
    
    // ========================================
    // 像素坐标
    // ========================================
    wire [7:0] pixel_x;
    wire [8:0] pixel_y;
    wire in_display;
    
    game_ddp ddp_inst (
        .hen        (hen),
        .ven        (ven),
        .rstn       (sys_rstn),
        .pclk       (pclk),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y[7:0]),
        .in_display (in_display)
    );
    
    // ========================================
    // 游戏主模块
    // ========================================
    wire [11:0] game_rgb;
    
    pacman_game game_inst (
        .clk        (clk),
        .rstn       (sys_rstn),
        .pclk       (pclk),
        .key_up     (key_up),
        .key_down   (key_down),
        .key_left   (key_left),
        .key_right  (key_right),
        .key_reset  (key_reset),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y[7:0]),
        .in_display (in_display),
        .rgb        (game_rgb)
    );
    
    // ========================================
    // VGA 输出
    // ========================================
    assign red   = (hen & ven) ? game_rgb[11:8] : 4'h0;
    assign green = (hen & ven) ? game_rgb[7:4]  : 4'h0;
    assign blue  = (hen & ven) ? game_rgb[3:0]  : 4'h0;
    
    // ========================================
    // LED 调试
    // ========================================
    assign led[0] = key_up;
    assign led[1] = key_down;
    assign led[2] = key_left;
    assign led[3] = key_right;
    assign led[4] = key_reset;
    assign led[7:5] = 3'b0;

endmodule
