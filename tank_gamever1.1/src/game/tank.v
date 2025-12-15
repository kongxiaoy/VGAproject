// 坦克模块 - 修复版
// 坦克大小: 3x4 像素

module tank #(
    parameter INIT_X = 8'd20,
    parameter INIT_Y = 8'd70,
    parameter INIT_DIR = 2'd3
)(
    input           clk,
    input           rstn,
    input           game_tick,
    input           game_start,
    
    // 控制输入
    input           move_up,
    input           move_down,
    input           move_left,
    input           move_right,
    input           fire,
    input           use_skill,
    
    // 技能选择
    input [1:0]     skill_type,
    
    // 墙壁碰撞检测 - 输出检测坐标
    output reg [7:0]    check_x,
    output reg [7:0]    check_y,
    input               hit_wall,
    
    // 被击中信号
    input           hit,
    
    // 发射子弹
    output reg      fire_bullet,
    output reg      fire_spread,
    output reg      fire_pierce,
    output [7:0]    bullet_start_x,
    output [7:0]    bullet_start_y,
    output [1:0]    bullet_dir,
    
    // 坦克状态输出
    output reg [7:0]    pos_x,
    output reg [7:0]    pos_y,
    output reg [1:0]    dir,
    output reg [1:0]    hp,
    output reg          alive,
    
    // 技能状态输出
    output reg          shield_active,
    output reg [2:0]    pierce_count,
    output reg [2:0]    spread_count
);

    // ============================================================
    // 可修改参数区域
    // ============================================================
    localparam SPEED_NORMAL = 1;
    localparam SPEED_BOOST = 2;
    localparam BOOST_DURATION = 300;
    localparam PIERCE_INIT = 3;
    localparam SPREAD_INIT = 3;
    localparam FIRE_COOLDOWN = 15;
    // ============================================================

    localparam TANK_WIDTH = 3;
    localparam TANK_HEIGHT = 4;
    
    // 游戏区域边界
    localparam MIN_X = 4;
    localparam MAX_X = 193;
    localparam MIN_Y = 4;
    localparam MAX_Y = 136;
    
    reg [1:0] move_speed;
    reg [8:0] boost_timer;
    reg boost_active;
    reg [7:0] next_x, next_y;
    reg [4:0] fire_cooldown_cnt;

    // ============================================================
    // 双人手感优化：
    // 1) 将 fire 视作“按键电平”，在内部做上升沿检测（fire_pressed）
    // 2) 增加一个很短的“开火缓冲”（fire_buffer），允许玩家提前一点按键
    // ============================================================
    reg fire_prev;
    reg fire_buffer;
    reg [3:0] fire_buffer_cnt; // 缓冲窗口（tick 数）
    wire fire_pressed = fire && !fire_prev;
    
    // 子弹发射位置
    assign bullet_start_x = (dir == 2'd2) ? pos_x - 2 :
                            (dir == 2'd3) ? pos_x + TANK_WIDTH : pos_x + 1;
    assign bullet_start_y = (dir == 2'd0) ? pos_y - 2 :
                            (dir == 2'd1) ? pos_y + TANK_HEIGHT : pos_y + 1;
    assign bullet_dir = dir;
    
    // 状态机
    localparam IDLE = 3'd0;
    localparam CHECK1 = 3'd1;
    localparam CHECK2 = 3'd2;
    localparam CHECK3 = 3'd3;
    localparam MOVE = 3'd4;
    
    reg [2:0] state;
    reg [1:0] move_dir;
    reg wall_blocked;
    reg skill_initialized;
    
    always @(posedge clk) begin
        if (!rstn) begin
            pos_x <= INIT_X;
            pos_y <= INIT_Y;
            dir <= INIT_DIR;
            hp <= 2'd3;
            alive <= 1'b1;
            fire_bullet <= 1'b0;
            fire_spread <= 1'b0;
            fire_pierce <= 1'b0;
            fire_cooldown_cnt <= 5'd0;
            state <= IDLE;
            move_speed <= SPEED_NORMAL;
            boost_timer <= 9'd0;
            boost_active <= 1'b0;
            shield_active <= 1'b0;
            pierce_count <= 3'd0;
            spread_count <= 3'd0;
            skill_initialized <= 1'b0;
            check_x <= 8'd0;
            check_y <= 8'd0;
            wall_blocked <= 1'b0;

            fire_prev <= 1'b0;
            fire_buffer <= 1'b0;
            fire_buffer_cnt <= 4'd0;
        end
        else begin
            fire_bullet <= 1'b0;
            fire_spread <= 1'b0;
            fire_pierce <= 1'b0;

            // fire 上升沿检测（每个 tick 都更新 prev）
            fire_prev <= fire;

            // 开火缓冲倒计时
            if (fire_buffer_cnt > 0 && game_tick) begin
                fire_buffer_cnt <= fire_buffer_cnt - 1'b1;
                if (fire_buffer_cnt == 1) fire_buffer <= 1'b0;
            end
            
            // 游戏开始时初始化技能
            if (game_start && !skill_initialized) begin
                skill_initialized <= 1'b1;
                case (skill_type)
                    2'd0: ; // 加速
                    2'd1: shield_active <= 1'b1;
                    2'd2: pierce_count <= PIERCE_INIT;
                    2'd3: spread_count <= SPREAD_INIT;
                endcase
            end
            
            // 被击中处理
            if (hit && alive) begin
                if (shield_active) begin
                    shield_active <= 1'b0;
                end
                else if (hp > 0) begin
                    hp <= hp - 1'b1;
                    if (hp == 1) alive <= 1'b0;
                end
            end
            
            // 加速计时
            if (boost_active && game_tick) begin
                if (boost_timer > 0) boost_timer <= boost_timer - 1'b1;
                else begin
                    boost_active <= 1'b0;
                    move_speed <= SPEED_NORMAL;
                end
            end
            
            // 使用技能
            if (use_skill && alive && skill_initialized) begin
                if (skill_type == 2'd0 && !boost_active) begin
                    boost_active <= 1'b1;
                    boost_timer <= BOOST_DURATION;
                    move_speed <= SPEED_BOOST;
                end
            end
            
            // 开火冷却
            if (fire_cooldown_cnt > 0 && game_tick) begin
                fire_cooldown_cnt <= fire_cooldown_cnt - 1'b1;
            end
            
            // 游戏逻辑
            if (game_tick && alive && skill_initialized) begin
                case (state)
                    IDLE: begin
                        // ========= 处理开火（手感优化版） =========
                        // 玩家按下开火键时，先写入 fire_buffer；
                        // 冷却结束时如果缓冲仍在，就立即发射。
                        if (fire_pressed) begin
                            fire_buffer <= 1'b1;
                            fire_buffer_cnt <= 4'd6; // 约 6 个 tick 的“提前按键窗口”
                        end

                        if (fire_buffer && fire_cooldown_cnt == 0) begin
                            fire_bullet <= 1'b1;
                            fire_cooldown_cnt <= FIRE_COOLDOWN;
                            fire_buffer <= 1'b0;
                            fire_buffer_cnt <= 4'd0;
                            if (spread_count > 0) begin
                                fire_spread <= 1'b1;
                                spread_count <= spread_count - 1'b1;
                            end
                            if (pierce_count > 0) begin
                                fire_pierce <= 1'b1;
                                pierce_count <= pierce_count - 1'b1;
                            end
                        end
                        
                        wall_blocked <= 1'b0;
                        
                        // 处理移动
                        if (move_up) begin
                            dir <= 2'd0;
                            move_dir <= 2'd0;
                            next_y <= (pos_y > MIN_Y + move_speed) ? pos_y - move_speed : MIN_Y;
                            next_x <= pos_x;
                            // 检测点1：左上角
                            check_x <= pos_x;
                            check_y <= (pos_y > MIN_Y + move_speed) ? pos_y - move_speed : MIN_Y;
                            state <= CHECK1;
                        end
                        else if (move_down) begin
                            dir <= 2'd1;
                            move_dir <= 2'd1;
                            next_y <= (pos_y < MAX_Y - move_speed) ? pos_y + move_speed : MAX_Y;
                            next_x <= pos_x;
                            check_x <= pos_x;
                            check_y <= (pos_y < MAX_Y - move_speed) ? pos_y + TANK_HEIGHT - 1 + move_speed : MAX_Y + TANK_HEIGHT - 1;
                            state <= CHECK1;
                        end
                        else if (move_left) begin
                            dir <= 2'd2;
                            move_dir <= 2'd2;
                            next_x <= (pos_x > MIN_X + move_speed) ? pos_x - move_speed : MIN_X;
                            next_y <= pos_y;
                            check_x <= (pos_x > MIN_X + move_speed) ? pos_x - move_speed : MIN_X;
                            check_y <= pos_y;
                            state <= CHECK1;
                        end
                        else if (move_right) begin
                            dir <= 2'd3;
                            move_dir <= 2'd3;
                            next_x <= (pos_x < MAX_X - move_speed) ? pos_x + move_speed : MAX_X;
                            next_y <= pos_y;
                            check_x <= (pos_x < MAX_X - move_speed) ? pos_x + TANK_WIDTH - 1 + move_speed : MAX_X + TANK_WIDTH - 1;
                            check_y <= pos_y;
                            state <= CHECK1;
                        end
                    end
                    
                    CHECK1: begin
                        if (hit_wall) wall_blocked <= 1'b1;
                        // 设置第二个检测点
                        case (move_dir)
                            2'd0: begin check_x <= pos_x + TANK_WIDTH - 1; check_y <= next_y; end
                            2'd1: begin check_x <= pos_x + TANK_WIDTH - 1; check_y <= next_y + TANK_HEIGHT - 1; end
                            2'd2: begin check_x <= next_x; check_y <= pos_y + TANK_HEIGHT - 1; end
                            2'd3: begin check_x <= next_x + TANK_WIDTH - 1; check_y <= pos_y + TANK_HEIGHT - 1; end
                        endcase
                        state <= CHECK2;
                    end
                    
                    CHECK2: begin
                        if (hit_wall) wall_blocked <= 1'b1;
                        // 设置第三个检测点 (中点)
                        case (move_dir)
                            2'd0: begin check_x <= pos_x + 1; check_y <= next_y; end
                            2'd1: begin check_x <= pos_x + 1; check_y <= next_y + TANK_HEIGHT - 1; end
                            2'd2: begin check_x <= next_x; check_y <= pos_y + 1; end
                            2'd3: begin check_x <= next_x + TANK_WIDTH - 1; check_y <= pos_y + 1; end
                        endcase
                        state <= CHECK3;
                    end
                    
                    CHECK3: begin
                        if (hit_wall) wall_blocked <= 1'b1;
                        state <= MOVE;
                    end
                    
                    MOVE: begin
                        if (!wall_blocked) begin
                            pos_x <= next_x;
                            pos_y <= next_y;
                        end
                        state <= IDLE;
                    end
                    
                    default: state <= IDLE;
                endcase
            end
        end
    end

endmodule