// 游戏主控制器 (修复版)

module game_ctrl (
    input           clk,
    input           pclk,
    input           rstn,
    
    // 玩家输入
    input           p1_up, p1_down, p1_left, p1_right, p1_fire,
    input           p2_up, p2_down, p2_left, p2_right, p2_fire,
    
    // VGA 坐标输入
    input [7:0]     pixel_x,
    input [8:0]     pixel_y,
    input           in_display,
    
    // RGB 输出
    output [11:0]   rgb,
    
    // 游戏状态
    output reg      game_over,
    output reg      p1_win
);

    // 游戏tick生成 (约30Hz)
    reg [21:0] tick_cnt;
    reg game_tick;
    
    always @(posedge clk) begin
        if (!rstn) begin
            tick_cnt <= 22'd0;
            game_tick <= 1'b0;
        end
        else begin
            if (tick_cnt >= 22'd3333333) begin
                tick_cnt <= 22'd0;
                game_tick <= 1'b1;
            end
            else begin
                tick_cnt <= tick_cnt + 1'b1;
                game_tick <= 1'b0;
            end
        end
    end
    
    // P1 坦克信号
    wire [7:0] p1_x, p1_y;
    wire [1:0] p1_dir, p1_hp;
    wire p1_alive;
    wire p1_fire_bullet;
    wire [7:0] p1_bullet_x, p1_bullet_y;
    wire [1:0] p1_bullet_dir;
    wire [4:0] p1_check_x, p1_check_y;
    
    // P2 坦克信号
    wire [7:0] p2_x, p2_y;
    wire [1:0] p2_dir, p2_hp;
    wire p2_alive;
    wire p2_fire_bullet;
    wire [7:0] p2_bullet_x, p2_bullet_y;
    wire [1:0] p2_bullet_dir;
    wire [4:0] p2_check_x, p2_check_y;
    
    // 子弹信号 - 展开
    wire [3:0] bullet_active;
    wire [7:0] bullet_x0, bullet_x1, bullet_x2, bullet_x3;
    wire [7:0] bullet_y0, bullet_y1, bullet_y2, bullet_y3;
    wire [1:0] bullet_dir0, bullet_dir1, bullet_dir2, bullet_dir3;
    wire [3:0] bullet_owner;
    
    wire [4:0] bullet_map_x, bullet_map_y;
    wire destroy_wall;
    wire [4:0] destroy_x, destroy_y;
    
    // 碰撞检测
    wire p1_hit, p2_hit;
    wire [3:0] bullet_destroy;
    
    // 地图信号
    wire [4:0] render_map_x, render_map_y;
    wire [1:0] render_tile;
    
    // 分数
    reg [7:0] p1_score, p2_score;
    
    // 地图模块
    map map_inst (
        .clk        (pclk),
        .rstn       (rstn),
        .rd_x       (render_map_x),
        .rd_y       (render_map_y),
        .rd_tile    (render_tile),
        .wr_en      (destroy_wall),
        .wr_x       (destroy_x),
        .wr_y       (destroy_y),
        .wr_tile    (2'd0)
    );
    
    // P1 坦克
    tank #(
        .INIT_X     (8'd24),
        .INIT_Y     (8'd64),
        .INIT_DIR   (2'd3)
    ) tank_p1 (
        .clk            (clk),
        .rstn           (rstn),
        .game_tick      (game_tick),
        .move_up        (p1_up),
        .move_down      (p1_down),
        .move_left      (p1_left),
        .move_right     (p1_right),
        .fire           (p1_fire),
        .check_tile_x   (p1_check_x),
        .check_tile_y   (p1_check_y),
        .tile_type      (render_tile),
        .hit            (p1_hit),
        .fire_bullet    (p1_fire_bullet),
        .bullet_start_x (p1_bullet_x),
        .bullet_start_y (p1_bullet_y),
        .bullet_dir     (p1_bullet_dir),
        .pos_x          (p1_x),
        .pos_y          (p1_y),
        .dir            (p1_dir),
        .hp             (p1_hp),
        .alive          (p1_alive)
    );
    
    // P2 坦克
    tank #(
        .INIT_X     (8'd168),
        .INIT_Y     (8'd64),
        .INIT_DIR   (2'd2)
    ) tank_p2 (
        .clk            (clk),
        .rstn           (rstn),
        .game_tick      (game_tick),
        .move_up        (p2_up),
        .move_down      (p2_down),
        .move_left      (p2_left),
        .move_right     (p2_right),
        .fire           (p2_fire),
        .check_tile_x   (p2_check_x),
        .check_tile_y   (p2_check_y),
        .tile_type      (render_tile),
        .hit            (p2_hit),
        .fire_bullet    (p2_fire_bullet),
        .bullet_start_x (p2_bullet_x),
        .bullet_start_y (p2_bullet_y),
        .bullet_dir     (p2_bullet_dir),
        .pos_x          (p2_x),
        .pos_y          (p2_y),
        .dir            (p2_dir),
        .hp             (p2_hp),
        .alive          (p2_alive)
    );
    
    // 子弹模块
    bullet bullet_inst (
        .clk            (clk),
        .rstn           (rstn),
        .game_tick      (game_tick),
        .p1_fire        (p1_fire_bullet),
        .p1_x           (p1_bullet_x),
        .p1_y           (p1_bullet_y),
        .p1_dir         (p1_bullet_dir),
        .p2_fire        (p2_fire_bullet),
        .p2_x           (p2_bullet_x),
        .p2_y           (p2_bullet_y),
        .p2_dir         (p2_bullet_dir),
        .map_check_x    (bullet_map_x),
        .map_check_y    (bullet_map_y),
        .map_tile       (render_tile),
        .destroy_wall   (destroy_wall),
        .destroy_x      (destroy_x),
        .destroy_y      (destroy_y),
        .bullet_active  (bullet_active),
        .bullet_x0      (bullet_x0),
        .bullet_x1      (bullet_x1),
        .bullet_x2      (bullet_x2),
        .bullet_x3      (bullet_x3),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_dir0    (bullet_dir0),
        .bullet_dir1    (bullet_dir1),
        .bullet_dir2    (bullet_dir2),
        .bullet_dir3    (bullet_dir3),
        .bullet_owner   (bullet_owner)
    );
    
    // 碰撞检测
    collision collision_inst (
        .clk            (clk),
        .rstn           (rstn),
        .p1_x           (p1_x),
        .p1_y           (p1_y),
        .p1_alive       (p1_alive),
        .p2_x           (p2_x),
        .p2_y           (p2_y),
        .p2_alive       (p2_alive),
        .bullet_active  (bullet_active),
        .bullet_x0      (bullet_x0),
        .bullet_x1      (bullet_x1),
        .bullet_x2      (bullet_x2),
        .bullet_x3      (bullet_x3),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_owner   (bullet_owner),
        .p1_hit         (p1_hit),
        .p2_hit         (p2_hit),
        .bullet_destroy (bullet_destroy)
    );
    
    // 渲染
    renderer renderer_inst (
        .pclk           (pclk),
        .rstn           (rstn),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .in_display     (in_display),
        .p1_x           (p1_x),
        .p1_y           (p1_y),
        .p1_dir         (p1_dir),
        .p1_hp          (p1_hp),
        .p1_alive       (p1_alive),
        .p2_x           (p2_x),
        .p2_y           (p2_y),
        .p2_dir         (p2_dir),
        .p2_hp          (p2_hp),
        .p2_alive       (p2_alive),
        .bullet_active  (bullet_active),
        .bullet_x0      (bullet_x0),
        .bullet_x1      (bullet_x1),
        .bullet_x2      (bullet_x2),
        .bullet_x3      (bullet_x3),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_owner   (bullet_owner),
        .map_rd_x       (render_map_x),
        .map_rd_y       (render_map_y),
        .map_tile       (render_tile),
        .p1_score       (p1_score),
        .p2_score       (p2_score),
        .game_over      (game_over),
        .p1_win         (p1_win),
        .rgb            (rgb)
    );
    
    // 分数和游戏结束
    always @(posedge clk) begin
        if (!rstn) begin
            p1_score <= 8'd0;
            p2_score <= 8'd0;
            game_over <= 1'b0;
            p1_win <= 1'b0;
        end
        else begin
            if (p1_hit) p2_score <= p2_score + 1'b1;
            if (p2_hit) p1_score <= p1_score + 1'b1;
            
            if (!p1_alive && !game_over) begin
                game_over <= 1'b1;
                p1_win <= 1'b0;
            end
            if (!p2_alive && !game_over) begin
                game_over <= 1'b1;
                p1_win <= 1'b1;
            end
        end
    end

endmodule