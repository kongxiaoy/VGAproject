// 吃豆人游戏主控模块 - 修复版
// 修复：1)玩家穿墙 2)幽灵不追踪

module pacman_game (
    input           clk,
    input           rstn,
    input           pclk,
    
    // 玩家输入
    input           key_up,
    input           key_down,
    input           key_left,
    input           key_right,
    input           key_reset,
    
    // VGA 坐标
    input [7:0]     pixel_x,
    input [7:0]     pixel_y,
    input           in_display,
    
    // RGB 输出
    output [11:0]   rgb
);

    // ========================================
    // 参数定义
    // ========================================
    localparam CELL_SIZE = 10;
    localparam MAZE_W = 20;
    localparam MAZE_H = 15;
    
    // 方向
    localparam DIR_NONE  = 3'd0;
    localparam DIR_UP    = 3'd1;
    localparam DIR_DOWN  = 3'd2;
    localparam DIR_LEFT  = 3'd3;
    localparam DIR_RIGHT = 3'd4;
    
    // 游戏状态
    localparam STATE_READY = 2'd0;
    localparam STATE_PLAY  = 2'd1;
    localparam STATE_WIN   = 2'd2;
    localparam STATE_LOSE  = 2'd3;
    
    // 速度
    localparam PLAYER_SPEED = 1;
    localparam GHOST_SPEED  = 1;
    
    // 实体大小
    localparam PLAYER_SIZE = 5;
    localparam GHOST_SIZE = 5;
    
    // ========================================
    // 墙壁判定函数 - 内联避免时序问题
    // ========================================
    function is_wall;
        input [4:0] cx;  // 格子 x (0-19)
        input [3:0] cy;  // 格子 y (0-14)
        reg [19:0] row;
        begin
            case (cy)
                4'd0:  row = 20'b11111111111111111111;
                4'd1:  row = 20'b10000000110000000001;
                4'd2:  row = 20'b10111011110111101101;
                4'd3:  row = 20'b10000000000000000001;
                4'd4:  row = 20'b10110111001110110101;
                4'd5:  row = 20'b10000001000001000001;
                4'd6:  row = 20'b11110101111101010111;
                4'd7:  row = 20'b10000100000001000001;
                4'd8:  row = 20'b10110101111101011101;
                4'd9:  row = 20'b10000100000001000001;
                4'd10: row = 20'b10111101110111011101;
                4'd11: row = 20'b10000000010000000001;
                4'd12: row = 20'b10111011010110111101;
                4'd13: row = 20'b10000000000000000001;
                4'd14: row = 20'b11111111111111111111;
                default: row = 20'b11111111111111111111;
            endcase
            is_wall = row[MAZE_W - 1 - cx];
        end
    endfunction
    
    // ========================================
    // 游戏 Tick 生成 (约30Hz)
    // ========================================
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
    
    // ========================================
    // 复位逻辑
    // ========================================
    reg soft_reset;
    reg key_reset_prev;
    
    always @(posedge clk) begin
        if (!rstn) begin
            soft_reset <= 1'b0;
            key_reset_prev <= 1'b0;
        end
        else begin
            key_reset_prev <= key_reset;
            if (key_reset && !key_reset_prev)
                soft_reset <= 1'b1;
            else
                soft_reset <= 1'b0;
        end
    end
    
    wire internal_rstn = rstn && !soft_reset;
    
    // ========================================
    // 游戏状态机
    // ========================================
    reg [1:0] game_state;
    wire all_dots_eaten;
    reg player_hit;
    
    always @(posedge clk) begin
        if (!internal_rstn) begin
            game_state <= STATE_READY;
        end
        else begin
            case (game_state)
                STATE_READY: begin
                    if (key_up || key_down || key_left || key_right)
                        game_state <= STATE_PLAY;
                end
                STATE_PLAY: begin
                    if (all_dots_eaten)
                        game_state <= STATE_WIN;
                    else if (player_hit)
                        game_state <= STATE_LOSE;
                end
                STATE_WIN, STATE_LOSE: begin
                    // 等待复位
                end
            endcase
        end
    end
    
    wire game_active = (game_state == STATE_PLAY);
    
    // ========================================
    // 玩家状态
    // ========================================
    reg [7:0] player_x, player_y;
    reg [2:0] player_dir;
    reg [2:0] player_next_dir;
    
    // 玩家初始位置
    localparam PLAYER_INIT_X = 10 * CELL_SIZE + (CELL_SIZE - PLAYER_SIZE) / 2;  // 格子(10,11)
    localparam PLAYER_INIT_Y = 11 * CELL_SIZE + (CELL_SIZE - PLAYER_SIZE) / 2;
    
    // 玩家当前格子和格子内偏移
    wire [4:0] player_cell_x = (player_x + PLAYER_SIZE/2) / CELL_SIZE;
    wire [3:0] player_cell_y = (player_y + PLAYER_SIZE/2) / CELL_SIZE;
    wire [3:0] player_offset_x = (player_x + PLAYER_SIZE/2) % CELL_SIZE;
    wire [3:0] player_offset_y = (player_y + PLAYER_SIZE/2) % CELL_SIZE;
    
    // 玩家是否在格子中心附近（可以转向）
    wire player_at_center_x = (player_offset_x >= 4 && player_offset_x <= 5);
    wire player_at_center_y = (player_offset_y >= 4 && player_offset_y <= 5);
    wire player_at_center = player_at_center_x && player_at_center_y;
    
    // 检查玩家某方向是否可以移动
    wire player_can_up    = !is_wall(player_cell_x, player_cell_y - 1);
    wire player_can_down  = !is_wall(player_cell_x, player_cell_y + 1);
    wire player_can_left  = !is_wall(player_cell_x - 1, player_cell_y);
    wire player_can_right = !is_wall(player_cell_x + 1, player_cell_y);
    
    // ========================================
    // 幽灵状态
    // ========================================
    reg [7:0] ghost1_x, ghost1_y;
    reg [2:0] ghost1_dir;
    reg [7:0] ghost2_x, ghost2_y;
    reg [2:0] ghost2_dir;
    
    // 幽灵初始位置
    localparam GHOST1_INIT_X = 1 * CELL_SIZE + (CELL_SIZE - GHOST_SIZE) / 2;
    localparam GHOST1_INIT_Y = 1 * CELL_SIZE + (CELL_SIZE - GHOST_SIZE) / 2;
    localparam GHOST2_INIT_X = 18 * CELL_SIZE + (CELL_SIZE - GHOST_SIZE) / 2;
    localparam GHOST2_INIT_Y = 1 * CELL_SIZE + (CELL_SIZE - GHOST_SIZE) / 2;
    
    // 幽灵1格子信息
    wire [4:0] ghost1_cell_x = (ghost1_x + GHOST_SIZE/2) / CELL_SIZE;
    wire [3:0] ghost1_cell_y = (ghost1_y + GHOST_SIZE/2) / CELL_SIZE;
    wire [3:0] ghost1_offset_x = (ghost1_x + GHOST_SIZE/2) % CELL_SIZE;
    wire [3:0] ghost1_offset_y = (ghost1_y + GHOST_SIZE/2) % CELL_SIZE;
    wire ghost1_at_center = (ghost1_offset_x >= 4 && ghost1_offset_x <= 5) &&
                            (ghost1_offset_y >= 4 && ghost1_offset_y <= 5);
    
    // 幽灵1可移动方向
    wire ghost1_can_up    = !is_wall(ghost1_cell_x, ghost1_cell_y - 1);
    wire ghost1_can_down  = !is_wall(ghost1_cell_x, ghost1_cell_y + 1);
    wire ghost1_can_left  = !is_wall(ghost1_cell_x - 1, ghost1_cell_y);
    wire ghost1_can_right = !is_wall(ghost1_cell_x + 1, ghost1_cell_y);
    
    // 幽灵2格子信息
    wire [4:0] ghost2_cell_x = (ghost2_x + GHOST_SIZE/2) / CELL_SIZE;
    wire [3:0] ghost2_cell_y = (ghost2_y + GHOST_SIZE/2) / CELL_SIZE;
    wire [3:0] ghost2_offset_x = (ghost2_x + GHOST_SIZE/2) % CELL_SIZE;
    wire [3:0] ghost2_offset_y = (ghost2_y + GHOST_SIZE/2) % CELL_SIZE;
    wire ghost2_at_center = (ghost2_offset_x >= 4 && ghost2_offset_x <= 5) &&
                            (ghost2_offset_y >= 4 && ghost2_offset_y <= 5);
    
    // 幽灵2可移动方向
    wire ghost2_can_up    = !is_wall(ghost2_cell_x, ghost2_cell_y - 1);
    wire ghost2_can_down  = !is_wall(ghost2_cell_x, ghost2_cell_y + 1);
    wire ghost2_can_left  = !is_wall(ghost2_cell_x - 1, ghost2_cell_y);
    wire ghost2_can_right = !is_wall(ghost2_cell_x + 1, ghost2_cell_y);
    
    // 幽灵追踪方向
    wire ghost1_want_up    = (player_cell_y < ghost1_cell_y);
    wire ghost1_want_down  = (player_cell_y > ghost1_cell_y);
    wire ghost1_want_left  = (player_cell_x < ghost1_cell_x);
    wire ghost1_want_right = (player_cell_x > ghost1_cell_x);
    
    wire ghost2_want_up    = (player_cell_y < ghost2_cell_y);
    wire ghost2_want_down  = (player_cell_y > ghost2_cell_y);
    wire ghost2_want_left  = (player_cell_x < ghost2_cell_x);
    wire ghost2_want_right = (player_cell_x > ghost2_cell_x);
    
    // ========================================
    // 迷宫实例（只用于渲染和豆子）
    // ========================================
    wire render_wall, render_dot;
    wire [7:0] dots_remaining;
    
    reg eat_dot;
    reg [4:0] eat_x;
    reg [3:0] eat_y;
    
    maze maze_inst (
        .clk            (clk),
        .rstn           (rstn),
        .game_reset     (soft_reset),
        .query_x        (player_cell_x),
        .query_y        (player_cell_y),
        .is_wall        (),  // 不使用，用函数代替
        .has_dot        (),
        .pixel_x        (pixel_x),
        .pixel_y        (pixel_y),
        .render_wall    (render_wall),
        .render_dot     (render_dot),
        .eat_dot        (eat_dot),
        .eat_x          (eat_x),
        .eat_y          (eat_y),
        .all_dots_eaten (all_dots_eaten),
        .dots_remaining (dots_remaining)
    );
    
    // ========================================
    // 玩家移动逻辑
    // ========================================
    always @(posedge clk) begin
        if (!internal_rstn) begin
            player_x <= PLAYER_INIT_X;
            player_y <= PLAYER_INIT_Y;
            player_dir <= DIR_NONE;
            player_next_dir <= DIR_NONE;
            eat_dot <= 1'b0;
        end
        else begin
            eat_dot <= 1'b0;
            
            // 记录预输入方向
            if (key_up) player_next_dir <= DIR_UP;
            else if (key_down) player_next_dir <= DIR_DOWN;
            else if (key_left) player_next_dir <= DIR_LEFT;
            else if (key_right) player_next_dir <= DIR_RIGHT;
            
            if (game_tick && game_active) begin
                // 在格子中心时尝试转向
                if (player_at_center && player_next_dir != DIR_NONE) begin
                    case (player_next_dir)
                        DIR_UP:    if (player_can_up)    player_dir <= DIR_UP;
                        DIR_DOWN:  if (player_can_down)  player_dir <= DIR_DOWN;
                        DIR_LEFT:  if (player_can_left)  player_dir <= DIR_LEFT;
                        DIR_RIGHT: if (player_can_right) player_dir <= DIR_RIGHT;
                    endcase
                end
                
                // 执行移动
                case (player_dir)
                    DIR_UP: begin
                        if (player_at_center_x) begin
                            if (player_can_up || player_offset_y > 5)
                                player_y <= player_y - PLAYER_SPEED;
                        end
                    end
                    DIR_DOWN: begin
                        if (player_at_center_x) begin
                            if (player_can_down || player_offset_y < 4)
                                player_y <= player_y + PLAYER_SPEED;
                        end
                    end
                    DIR_LEFT: begin
                        if (player_at_center_y) begin
                            if (player_can_left || player_offset_x > 5)
                                player_x <= player_x - PLAYER_SPEED;
                        end
                    end
                    DIR_RIGHT: begin
                        if (player_at_center_y) begin
                            if (player_can_right || player_offset_x < 4)
                                player_x <= player_x + PLAYER_SPEED;
                        end
                    end
                endcase
                
                // 吃豆子
                if (player_at_center) begin
                    eat_dot <= 1'b1;
                    eat_x <= player_cell_x;
                    eat_y <= player_cell_y;
                end
            end
        end
    end
    
    // ========================================
    // 幽灵1移动逻辑
    // ========================================
    always @(posedge clk) begin
        if (!internal_rstn) begin
            ghost1_x <= GHOST1_INIT_X;
            ghost1_y <= GHOST1_INIT_Y;
            ghost1_dir <= DIR_RIGHT;
        end
        else if (game_tick && game_active) begin
            // 在格子中心时选择方向
            if (ghost1_at_center) begin
                // 优先朝玩家方向，不能掉头
                if (ghost1_want_up && ghost1_can_up && ghost1_dir != DIR_DOWN)
                    ghost1_dir <= DIR_UP;
                else if (ghost1_want_down && ghost1_can_down && ghost1_dir != DIR_UP)
                    ghost1_dir <= DIR_DOWN;
                else if (ghost1_want_left && ghost1_can_left && ghost1_dir != DIR_RIGHT)
                    ghost1_dir <= DIR_LEFT;
                else if (ghost1_want_right && ghost1_can_right && ghost1_dir != DIR_LEFT)
                    ghost1_dir <= DIR_RIGHT;
                // 次选：任意可行方向（不掉头）
                else if (ghost1_can_up && ghost1_dir != DIR_DOWN)
                    ghost1_dir <= DIR_UP;
                else if (ghost1_can_right && ghost1_dir != DIR_LEFT)
                    ghost1_dir <= DIR_RIGHT;
                else if (ghost1_can_down && ghost1_dir != DIR_UP)
                    ghost1_dir <= DIR_DOWN;
                else if (ghost1_can_left && ghost1_dir != DIR_RIGHT)
                    ghost1_dir <= DIR_LEFT;
                // 死胡同：掉头
                else if (ghost1_can_up) ghost1_dir <= DIR_UP;
                else if (ghost1_can_down) ghost1_dir <= DIR_DOWN;
                else if (ghost1_can_left) ghost1_dir <= DIR_LEFT;
                else if (ghost1_can_right) ghost1_dir <= DIR_RIGHT;
            end
            
            // 执行移动
            case (ghost1_dir)
                DIR_UP: begin
                    if (ghost1_can_up || ghost1_offset_y > 5)
                        ghost1_y <= ghost1_y - GHOST_SPEED;
                end
                DIR_DOWN: begin
                    if (ghost1_can_down || ghost1_offset_y < 4)
                        ghost1_y <= ghost1_y + GHOST_SPEED;
                end
                DIR_LEFT: begin
                    if (ghost1_can_left || ghost1_offset_x > 5)
                        ghost1_x <= ghost1_x - GHOST_SPEED;
                end
                DIR_RIGHT: begin
                    if (ghost1_can_right || ghost1_offset_x < 4)
                        ghost1_x <= ghost1_x + GHOST_SPEED;
                end
            endcase
        end
    end
    
    // ========================================
    // 幽灵2移动逻辑
    // ========================================
    always @(posedge clk) begin
        if (!internal_rstn) begin
            ghost2_x <= GHOST2_INIT_X;
            ghost2_y <= GHOST2_INIT_Y;
            ghost2_dir <= DIR_LEFT;
        end
        else if (game_tick && game_active) begin
            // 在格子中心时选择方向
            if (ghost2_at_center) begin
                if (ghost2_want_up && ghost2_can_up && ghost2_dir != DIR_DOWN)
                    ghost2_dir <= DIR_UP;
                else if (ghost2_want_down && ghost2_can_down && ghost2_dir != DIR_UP)
                    ghost2_dir <= DIR_DOWN;
                else if (ghost2_want_left && ghost2_can_left && ghost2_dir != DIR_RIGHT)
                    ghost2_dir <= DIR_LEFT;
                else if (ghost2_want_right && ghost2_can_right && ghost2_dir != DIR_LEFT)
                    ghost2_dir <= DIR_RIGHT;
                else if (ghost2_can_up && ghost2_dir != DIR_DOWN)
                    ghost2_dir <= DIR_UP;
                else if (ghost2_can_left && ghost2_dir != DIR_RIGHT)
                    ghost2_dir <= DIR_LEFT;
                else if (ghost2_can_down && ghost2_dir != DIR_UP)
                    ghost2_dir <= DIR_DOWN;
                else if (ghost2_can_right && ghost2_dir != DIR_LEFT)
                    ghost2_dir <= DIR_RIGHT;
                else if (ghost2_can_up) ghost2_dir <= DIR_UP;
                else if (ghost2_can_down) ghost2_dir <= DIR_DOWN;
                else if (ghost2_can_left) ghost2_dir <= DIR_LEFT;
                else if (ghost2_can_right) ghost2_dir <= DIR_RIGHT;
            end
            
            // 执行移动
            case (ghost2_dir)
                DIR_UP: begin
                    if (ghost2_can_up || ghost2_offset_y > 5)
                        ghost2_y <= ghost2_y - GHOST_SPEED;
                end
                DIR_DOWN: begin
                    if (ghost2_can_down || ghost2_offset_y < 4)
                        ghost2_y <= ghost2_y + GHOST_SPEED;
                end
                DIR_LEFT: begin
                    if (ghost2_can_left || ghost2_offset_x > 5)
                        ghost2_x <= ghost2_x - GHOST_SPEED;
                end
                DIR_RIGHT: begin
                    if (ghost2_can_right || ghost2_offset_x < 4)
                        ghost2_x <= ghost2_x + GHOST_SPEED;
                end
            endcase
        end
    end
    
    // ========================================
    // 碰撞检测
    // ========================================
    wire hit_ghost1 = (player_x < ghost1_x + GHOST_SIZE) && (player_x + PLAYER_SIZE > ghost1_x) &&
                      (player_y < ghost1_y + GHOST_SIZE) && (player_y + PLAYER_SIZE > ghost1_y);
    wire hit_ghost2 = (player_x < ghost2_x + GHOST_SIZE) && (player_x + PLAYER_SIZE > ghost2_x) &&
                      (player_y < ghost2_y + GHOST_SIZE) && (player_y + PLAYER_SIZE > ghost2_y);
    
    always @(posedge clk) begin
        if (!internal_rstn)
            player_hit <= 1'b0;
        else if (game_active)
            player_hit <= hit_ghost1 || hit_ghost2;
    end
    
    // ========================================
    // 渲染
    // ========================================
    localparam COLOR_BG     = 12'h000;
    localparam COLOR_WALL   = 12'h00F;
    localparam COLOR_DOT    = 12'hFFF;
    localparam COLOR_PLAYER = 12'hFF0;
    localparam COLOR_GHOST1 = 12'hF00;
    localparam COLOR_GHOST2 = 12'hF0F;
    localparam COLOR_WIN    = 12'h0F0;
    localparam COLOR_LOSE   = 12'hF00;
    
    wire in_player = (pixel_x >= player_x) && (pixel_x < player_x + PLAYER_SIZE) &&
                     (pixel_y >= player_y) && (pixel_y < player_y + PLAYER_SIZE);
    
    wire in_ghost1 = (pixel_x >= ghost1_x) && (pixel_x < ghost1_x + GHOST_SIZE) &&
                     (pixel_y >= ghost1_y) && (pixel_y < ghost1_y + GHOST_SIZE);
    
    wire in_ghost2 = (pixel_x >= ghost2_x) && (pixel_x < ghost2_x + GHOST_SIZE) &&
                     (pixel_y >= ghost2_y) && (pixel_y < ghost2_y + GHOST_SIZE);
    
    wire in_result_box = (pixel_x >= 60) && (pixel_x < 140) && 
                         (pixel_y >= 60) && (pixel_y < 90);
    
    reg [11:0] rgb_out;
    
    always @(posedge pclk) begin
        if (!rstn || !in_display) begin
            rgb_out <= 12'h000;
        end
        else begin
            case (game_state)
                STATE_READY, STATE_PLAY: begin
                    if (in_player) rgb_out <= COLOR_PLAYER;
                    else if (in_ghost1) rgb_out <= COLOR_GHOST1;
                    else if (in_ghost2) rgb_out <= COLOR_GHOST2;
                    else if (render_dot) rgb_out <= COLOR_DOT;
                    else if (render_wall) rgb_out <= COLOR_WALL;
                    else rgb_out <= COLOR_BG;
                end
                
                STATE_WIN: begin
                    if (in_result_box) rgb_out <= COLOR_WIN;
                    else if (render_wall) rgb_out <= COLOR_WALL;
                    else rgb_out <= COLOR_BG;
                end
                
                STATE_LOSE: begin
                    if (in_result_box) rgb_out <= COLOR_LOSE;
                    else if (in_ghost1) rgb_out <= COLOR_GHOST1;
                    else if (in_ghost2) rgb_out <= COLOR_GHOST2;
                    else if (render_wall) rgb_out <= COLOR_WALL;
                    else rgb_out <= COLOR_BG;
                end
            endcase
        end
    end
    
    assign rgb = rgb_out;

endmodule
