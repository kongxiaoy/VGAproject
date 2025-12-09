// 游戏渲染模块 (修复版)

module renderer (
    input           pclk,
    input           rstn,
    
    // 当前像素坐标
    input [7:0]     pixel_x,
    input [8:0]     pixel_y,
    input           in_display,
    
    // P1 坦克
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input [1:0]     p1_dir,
    input [1:0]     p1_hp,
    input           p1_alive,
    
    // P2 坦克
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input [1:0]     p2_dir,
    input [1:0]     p2_hp,
    input           p2_alive,
    
    // 子弹 - 展开的信号
    input [3:0]     bullet_active,
    input [7:0]     bullet_x0, bullet_x1, bullet_x2, bullet_x3,
    input [7:0]     bullet_y0, bullet_y1, bullet_y2, bullet_y3,
    input [3:0]     bullet_owner,
    
    // 地图
    output [4:0]    map_rd_x,
    output [4:0]    map_rd_y,
    input [1:0]     map_tile,
    
    // 分数
    input [7:0]     p1_score,
    input [7:0]     p2_score,
    
    // 游戏状态
    input           game_over,
    input           p1_win,
    
    // 输出
    output reg [11:0] rgb
);

    // 颜色定义
    localparam COLOR_BG        = 12'h000;
    localparam COLOR_P1_TANK   = 12'h0F0;
    localparam COLOR_P2_TANK   = 12'h44F;
    localparam COLOR_P1_BULLET = 12'hFF0;
    localparam COLOR_P2_BULLET = 12'h0FF;
    localparam COLOR_BRICK     = 12'h840;
    localparam COLOR_STEEL     = 12'h888;
    localparam COLOR_HEART     = 12'hF00;
    
    localparam TANK_SIZE = 8;
    localparam BULLET_SIZE = 4;
    localparam STATUS_HEIGHT = 6;
    
    // 内部数组
    wire [7:0] bullet_x [0:3];
    wire [7:0] bullet_y [0:3];
    
    assign bullet_x[0] = bullet_x0; assign bullet_x[1] = bullet_x1;
    assign bullet_x[2] = bullet_x2; assign bullet_x[3] = bullet_x3;
    assign bullet_y[0] = bullet_y0; assign bullet_y[1] = bullet_y1;
    assign bullet_y[2] = bullet_y2; assign bullet_y[3] = bullet_y3;
    
    // 游戏区域Y坐标
    wire [8:0] game_y = pixel_y - STATUS_HEIGHT;
    
    // 地图格子坐标
    assign map_rd_x = pixel_x / 8;
    assign map_rd_y = game_y / 8;
    
    // 区域判断
    wire in_status = (pixel_y < STATUS_HEIGHT);
    wire in_game = (pixel_y >= STATUS_HEIGHT && pixel_y < 150);
    
    // P1坦克
    wire in_p1_tank = p1_alive && in_game &&
                      (pixel_x >= p1_x) && (pixel_x < p1_x + TANK_SIZE) &&
                      (game_y >= p1_y) && (game_y < p1_y + TANK_SIZE);
    
    // P2坦克
    wire in_p2_tank = p2_alive && in_game &&
                      (pixel_x >= p2_x) && (pixel_x < p2_x + TANK_SIZE) &&
                      (game_y >= p2_y) && (game_y < p2_y + TANK_SIZE);
    
    // 子弹检测
    wire in_bullet0 = bullet_active[0] && in_game &&
                      (pixel_x >= bullet_x[0]) && (pixel_x < bullet_x[0] + BULLET_SIZE) &&
                      (game_y >= bullet_y[0]) && (game_y < bullet_y[0] + BULLET_SIZE);
    wire in_bullet1 = bullet_active[1] && in_game &&
                      (pixel_x >= bullet_x[1]) && (pixel_x < bullet_x[1] + BULLET_SIZE) &&
                      (game_y >= bullet_y[1]) && (game_y < bullet_y[1] + BULLET_SIZE);
    wire in_bullet2 = bullet_active[2] && in_game &&
                      (pixel_x >= bullet_x[2]) && (pixel_x < bullet_x[2] + BULLET_SIZE) &&
                      (game_y >= bullet_y[2]) && (game_y < bullet_y[2] + BULLET_SIZE);
    wire in_bullet3 = bullet_active[3] && in_game &&
                      (pixel_x >= bullet_x[3]) && (pixel_x < bullet_x[3] + BULLET_SIZE) &&
                      (game_y >= bullet_y[3]) && (game_y < bullet_y[3] + BULLET_SIZE);
    
    wire any_p1_bullet = (in_bullet0 && !bullet_owner[0]) || (in_bullet1 && !bullet_owner[1]) ||
                         (in_bullet2 && !bullet_owner[2]) || (in_bullet3 && !bullet_owner[3]);
    wire any_p2_bullet = (in_bullet0 && bullet_owner[0]) || (in_bullet1 && bullet_owner[1]) ||
                         (in_bullet2 && bullet_owner[2]) || (in_bullet3 && bullet_owner[3]);
    wire any_bullet = in_bullet0 | in_bullet1 | in_bullet2 | in_bullet3;
    
    // 墙壁
    wire in_brick = in_game && (map_tile == 2'd1);
    wire in_steel = in_game && (map_tile == 2'd2);
    
    // 坦克形状
    wire [2:0] tank_px = pixel_x[2:0];
    wire [2:0] tank_py = game_y[2:0];
    
    // 简化的坦克形状
    reg p1_pixel, p2_pixel;
    
    always @(*) begin
        p1_pixel = 1'b0;
        if (in_p1_tank) begin
            case (p1_dir)
                2'd0: p1_pixel = (tank_px >= 2 && tank_px <= 5) || (tank_py >= 3 && tank_py <= 6);
                2'd1: p1_pixel = (tank_px >= 2 && tank_px <= 5) || (tank_py >= 1 && tank_py <= 4);
                2'd2: p1_pixel = (tank_py >= 2 && tank_py <= 5) || (tank_px >= 3 && tank_px <= 6);
                2'd3: p1_pixel = (tank_py >= 2 && tank_py <= 5) || (tank_px >= 1 && tank_px <= 4);
            endcase
        end
    end
    
    always @(*) begin
        p2_pixel = 1'b0;
        if (in_p2_tank) begin
            case (p2_dir)
                2'd0: p2_pixel = (tank_px >= 2 && tank_px <= 5) || (tank_py >= 3 && tank_py <= 6);
                2'd1: p2_pixel = (tank_px >= 2 && tank_px <= 5) || (tank_py >= 1 && tank_py <= 4);
                2'd2: p2_pixel = (tank_py >= 2 && tank_py <= 5) || (tank_px >= 3 && tank_px <= 6);
                2'd3: p2_pixel = (tank_py >= 2 && tank_py <= 5) || (tank_px >= 1 && tank_px <= 4);
            endcase
        end
    end
    
    // 生命值显示
    wire in_p1_heart1 = in_status && (pixel_x >= 2) && (pixel_x < 8) && (pixel_y >= 1) && (pixel_y < 5) && (p1_hp >= 1);
    wire in_p1_heart2 = in_status && (pixel_x >= 10) && (pixel_x < 16) && (pixel_y >= 1) && (pixel_y < 5) && (p1_hp >= 2);
    wire in_p1_heart3 = in_status && (pixel_x >= 18) && (pixel_x < 24) && (pixel_y >= 1) && (pixel_y < 5) && (p1_hp >= 3);
    
    wire in_p2_heart1 = in_status && (pixel_x >= 176) && (pixel_x < 182) && (pixel_y >= 1) && (pixel_y < 5) && (p2_hp >= 1);
    wire in_p2_heart2 = in_status && (pixel_x >= 184) && (pixel_x < 190) && (pixel_y >= 1) && (pixel_y < 5) && (p2_hp >= 2);
    wire in_p2_heart3 = in_status && (pixel_x >= 192) && (pixel_x < 198) && (pixel_y >= 1) && (pixel_y < 5) && (p2_hp >= 3);
    
    wire any_heart = in_p1_heart1 | in_p1_heart2 | in_p1_heart3 |
                     in_p2_heart1 | in_p2_heart2 | in_p2_heart3;
    
    // 像素输出
    always @(posedge pclk) begin
        if (!rstn || !in_display) begin
            rgb <= 12'h000;
        end
        else begin
            if (any_p1_bullet) begin
                rgb <= COLOR_P1_BULLET;
            end
            else if (any_p2_bullet) begin
                rgb <= COLOR_P2_BULLET;
            end
            else if (p1_pixel) begin
                rgb <= COLOR_P1_TANK;
            end
            else if (p2_pixel) begin
                rgb <= COLOR_P2_TANK;
            end
            else if (in_brick) begin
                rgb <= COLOR_BRICK;
            end
            else if (in_steel) begin
                rgb <= COLOR_STEEL;
            end
            else if (any_heart) begin
                rgb <= COLOR_HEART;
            end
            else begin
                rgb <= COLOR_BG;
            end
        end
    end

endmodule