// 游戏主控制器 - 修复版

module game_ctrl (
    input           clk,
    input           pclk,
    input           rstn,
    input           game_reset,     // 软件复位
    
    // 玩家输入
    input           p1_up, p1_down, p1_left, p1_right, p1_fire, p1_skill,
    input           p2_up, p2_down, p2_left, p2_right, p2_fire, p2_skill,
    
    // 技能选择输入
    input [1:0]     p1_skill_sel,
    input [1:0]     p2_skill_sel,
    input           p1_ready,
    input           p2_ready,
    
    // VGA 坐标输入
    input [7:0]     pixel_x,
    input [8:0]     pixel_y,
    input           in_display,
    
    // RGB 输出
    output [11:0]   rgb,
    
    // 游戏状态
    output reg      game_start,
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
    
    // 软件复位信号 - 同步到内部
    reg soft_reset;
    always @(posedge clk) begin
        if (!rstn)
            soft_reset <= 1'b0;
        else
            soft_reset <= game_reset;
    end
    
    // 内部复位 = 硬件复位 或 软件复位
    wire internal_rstn = rstn & ~soft_reset;
    
    // 游戏开始控制
    always @(posedge clk) begin
        if (!rstn || soft_reset) begin
            game_start <= 1'b0;
        end
        else if (p1_ready && p2_ready && !game_start) begin
            game_start <= 1'b1;
        end
    end
    
    // P1 坦克信号
    wire [7:0] p1_x, p1_y;
    wire [1:0] p1_dir, p1_hp;
    wire p1_alive;
    wire p1_fire_bullet, p1_fire_spread, p1_fire_pierce;
    wire [7:0] p1_bullet_x, p1_bullet_y;
    wire [1:0] p1_bullet_dir;
    wire [7:0] p1_check_x, p1_check_y;
    wire p1_shield;
    wire [2:0] p1_pierce_cnt, p1_spread_cnt;
    
    // P2 坦克信号
    wire [7:0] p2_x, p2_y;
    wire [1:0] p2_dir, p2_hp;
    wire p2_alive;
    wire p2_fire_bullet, p2_fire_spread, p2_fire_pierce;
    wire [7:0] p2_bullet_x, p2_bullet_y;
    wire [1:0] p2_bullet_dir;
    wire [7:0] p2_check_x, p2_check_y;
    wire p2_shield;
    wire [2:0] p2_pierce_cnt, p2_spread_cnt;
    
    // 子弹信号 (8颗)
    wire [7:0] bullet_active;
    wire [7:0] bullet_x0, bullet_x1, bullet_x2, bullet_x3;
    wire [7:0] bullet_x4, bullet_x5, bullet_x6, bullet_x7;
    wire [7:0] bullet_y0, bullet_y1, bullet_y2, bullet_y3;
    wire [7:0] bullet_y4, bullet_y5, bullet_y6, bullet_y7;
    wire [1:0] bullet_dir0, bullet_dir1, bullet_dir2, bullet_dir3;
    wire [1:0] bullet_dir4, bullet_dir5, bullet_dir6, bullet_dir7;
    wire [7:0] bullet_owner;
    wire [7:0] bullet_pierce;
    
    // 墙壁检测信号
    wire [7:0] render_map_x, render_map_y;
    wire render_wall;
    wire [7:0] bullet_wall_x, bullet_wall_y;
    wire bullet_wall_hit;
    
    // 碰撞检测
    wire p1_hit, p2_hit;
    wire [7:0] bullet_destroy;
    
    // ========== 地图模块 - 多端口访问 ==========
    // 渲染端口
    map map_render (
        .clk            (pclk),
        .rstn           (rstn),
        .rd_x           (render_map_x),
        .rd_y           (render_map_y),
        .rd_wall        (render_wall),
        .bullet_x       (8'd0),
        .bullet_y       (8'd0),
        .bullet_hit_wall()
    );
    
    // P1 碰撞检测端口
    wire p1_wall_hit;
    map map_p1 (
        .clk            (clk),
        .rstn           (rstn),
        .rd_x           (p1_check_x),
        .rd_y           (p1_check_y),
        .rd_wall        (p1_wall_hit),
        .bullet_x       (8'd0),
        .bullet_y       (8'd0),
        .bullet_hit_wall()
    );
    
    // P2 碰撞检测端口
    wire p2_wall_hit;
    map map_p2 (
        .clk            (clk),
        .rstn           (rstn),
        .rd_x           (p2_check_x),
        .rd_y           (p2_check_y),
        .rd_wall        (p2_wall_hit),
        .bullet_x       (8'd0),
        .bullet_y       (8'd0),
        .bullet_hit_wall()
    );
    
    // 子弹碰撞检测端口
    map map_bullet (
        .clk            (clk),
        .rstn           (rstn),
        .rd_x           (8'd0),
        .rd_y           (8'd0),
        .rd_wall        (),
        .bullet_x       (bullet_wall_x),
        .bullet_y       (bullet_wall_y),
        .bullet_hit_wall(bullet_wall_hit)
    );
    
    // P1 坦克
    tank #(
        .INIT_X     (8'd10),
        .INIT_Y     (8'd70),
        .INIT_DIR   (2'd3)
    ) tank_p1 (
        .clk            (clk),
        .rstn           (internal_rstn),
        .game_tick      (game_tick),
        .game_start     (game_start),
        .move_up        (p1_up),
        .move_down      (p1_down),
        .move_left      (p1_left),
        .move_right     (p1_right),
        .fire           (p1_fire),
        .use_skill      (p1_skill),
        .skill_type     (p1_skill_sel),
        .check_x        (p1_check_x),
        .check_y        (p1_check_y),
        .hit_wall       (p1_wall_hit),
        .hit            (p1_hit),
        .fire_bullet    (p1_fire_bullet),
        .fire_spread    (p1_fire_spread),
        .fire_pierce    (p1_fire_pierce),
        .bullet_start_x (p1_bullet_x),
        .bullet_start_y (p1_bullet_y),
        .bullet_dir     (p1_bullet_dir),
        .pos_x          (p1_x),
        .pos_y          (p1_y),
        .dir            (p1_dir),
        .hp             (p1_hp),
        .alive          (p1_alive),
        .shield_active  (p1_shield),
        .pierce_count   (p1_pierce_cnt),
        .spread_count   (p1_spread_cnt)
    );
    
    // P2 坦克
    tank #(
        .INIT_X     (8'd177),
        .INIT_Y     (8'd70),
        .INIT_DIR   (2'd2)
    ) tank_p2 (
        .clk            (clk),
        .rstn           (internal_rstn),
        .game_tick      (game_tick),
        .game_start     (game_start),
        .move_up        (p2_up),
        .move_down      (p2_down),
        .move_left      (p2_left),
        .move_right     (p2_right),
        .fire           (p2_fire),
        .use_skill      (p2_skill),
        .skill_type     (p2_skill_sel),
        .check_x        (p2_check_x),
        .check_y        (p2_check_y),
        .hit_wall       (p2_wall_hit),
        .hit            (p2_hit),
        .fire_bullet    (p2_fire_bullet),
        .fire_spread    (p2_fire_spread),
        .fire_pierce    (p2_fire_pierce),
        .bullet_start_x (p2_bullet_x),
        .bullet_start_y (p2_bullet_y),
        .bullet_dir     (p2_bullet_dir),
        .pos_x          (p2_x),
        .pos_y          (p2_y),
        .dir            (p2_dir),
        .hp             (p2_hp),
        .alive          (p2_alive),
        .shield_active  (p2_shield),
        .pierce_count   (p2_pierce_cnt),
        .spread_count   (p2_spread_cnt)
    );
    
    // 子弹模块
    bullet bullet_inst (
        .clk            (clk),
        .rstn           (internal_rstn),
        .game_tick      (game_tick),
        .game_start     (game_start),
        .p1_fire        (p1_fire_bullet),
        .p1_spread      (p1_fire_spread),
        .p1_pierce      (p1_fire_pierce),
        .p1_x           (p1_bullet_x),
        .p1_y           (p1_bullet_y),
        .p1_dir         (p1_bullet_dir),
        .p2_fire        (p2_fire_bullet),
        .p2_spread      (p2_fire_spread),
        .p2_pierce      (p2_fire_pierce),
        .p2_x           (p2_bullet_x),
        .p2_y           (p2_bullet_y),
        .p2_dir         (p2_bullet_dir),
        .wall_check_x   (bullet_wall_x),
        .wall_check_y   (bullet_wall_y),
        .wall_hit       (bullet_wall_hit),
        .bullet_active  (bullet_active),
        .bullet_x0      (bullet_x0),
        .bullet_x1      (bullet_x1),
        .bullet_x2      (bullet_x2),
        .bullet_x3      (bullet_x3),
        .bullet_x4      (bullet_x4),
        .bullet_x5      (bullet_x5),
        .bullet_x6      (bullet_x6),
        .bullet_x7      (bullet_x7),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_y4      (bullet_y4),
        .bullet_y5      (bullet_y5),
        .bullet_y6      (bullet_y6),
        .bullet_y7      (bullet_y7),
        .bullet_dir0    (bullet_dir0),
        .bullet_dir1    (bullet_dir1),
        .bullet_dir2    (bullet_dir2),
        .bullet_dir3    (bullet_dir3),
        .bullet_dir4    (bullet_dir4),
        .bullet_dir5    (bullet_dir5),
        .bullet_dir6    (bullet_dir6),
        .bullet_dir7    (bullet_dir7),
        .bullet_owner   (bullet_owner),
        .bullet_pierce  (bullet_pierce)
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
        .bullet_x4      (bullet_x4),
        .bullet_x5      (bullet_x5),
        .bullet_x6      (bullet_x6),
        .bullet_x7      (bullet_x7),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_y4      (bullet_y4),
        .bullet_y5      (bullet_y5),
        .bullet_y6      (bullet_y6),
        .bullet_y7      (bullet_y7),
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
        .game_start     (game_start),
        .game_over      (game_over),
        .p1_win         (p1_win),
        .p1_skill_sel   (p1_skill_sel),
        .p2_skill_sel   (p2_skill_sel),
        .p1_ready       (p1_ready),
        .p2_ready       (p2_ready),
        .p1_x           (p1_x),
        .p1_y           (p1_y),
        .p1_dir         (p1_dir),
        .p1_hp          (p1_hp),
        .p1_alive       (p1_alive),
        .p1_shield      (p1_shield),
        .p2_x           (p2_x),
        .p2_y           (p2_y),
        .p2_dir         (p2_dir),
        .p2_hp          (p2_hp),
        .p2_alive       (p2_alive),
        .p2_shield      (p2_shield),
        .bullet_active  (bullet_active),
        .bullet_x0      (bullet_x0),
        .bullet_x1      (bullet_x1),
        .bullet_x2      (bullet_x2),
        .bullet_x3      (bullet_x3),
        .bullet_x4      (bullet_x4),
        .bullet_x5      (bullet_x5),
        .bullet_x6      (bullet_x6),
        .bullet_x7      (bullet_x7),
        .bullet_y0      (bullet_y0),
        .bullet_y1      (bullet_y1),
        .bullet_y2      (bullet_y2),
        .bullet_y3      (bullet_y3),
        .bullet_y4      (bullet_y4),
        .bullet_y5      (bullet_y5),
        .bullet_y6      (bullet_y6),
        .bullet_y7      (bullet_y7),
        .bullet_owner   (bullet_owner),
        .map_rd_x       (render_map_x),
        .map_rd_y       (render_map_y),
        .map_wall       (render_wall),
        .rgb            (rgb)
    );
    
    // 游戏结束判断
    always @(posedge clk) begin
        if (!rstn || soft_reset) begin
            game_over <= 1'b0;
            p1_win <= 1'b0;
        end
        else if (game_start && !game_over) begin
            if (!p1_alive) begin
                game_over <= 1'b1;
                p1_win <= 1'b0;  // P2 wins
            end
            else if (!p2_alive) begin
                game_over <= 1'b1;
                p1_win <= 1'b1;  // P1 wins
            end
        end
    end

endmodule