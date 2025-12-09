// 坦克模块
// 管理单个坦克的状态

module tank #(
    parameter INIT_X = 8'd24,       // 初始X位置 (像素)
    parameter INIT_Y = 8'd72,       // 初始Y位置 (像素)
    parameter INIT_DIR = 2'd3       // 初始方向: 0=上 1=下 2=左 3=右
)(
    input           clk,
    input           rstn,
    input           game_tick,      // 游戏逻辑时钟 (约30Hz)
    
    // 控制输入
    input           move_up,
    input           move_down,
    input           move_left,
    input           move_right,
    input           fire,
    
    // 地图碰撞检测
    output [4:0]    check_tile_x,   // 检查的格子X
    output [4:0]    check_tile_y,   // 检查的格子Y
    input [1:0]     tile_type,      // 格子类型
    
    // 被击中信号
    input           hit,
    
    // 发射子弹
    output reg      fire_bullet,
    output [7:0]    bullet_start_x,
    output [7:0]    bullet_start_y,
    output [1:0]    bullet_dir,
    
    // 坦克状态输出
    output reg [7:0]    pos_x,
    output reg [7:0]    pos_y,
    output reg [1:0]    dir,
    output reg [1:0]    hp,
    output reg          alive
);

    // 坦克大小: 8x8 像素
    localparam TANK_SIZE = 8;
    
    // 移动速度 (每tick移动的像素数)
    localparam MOVE_SPEED = 1;
    
    // 游戏区域边界 (像素)
    localparam MIN_X = 8;           // 左边界 (1格墙)
    localparam MAX_X = 191;         // 右边界 (200 - 8 - 1)
    localparam MIN_Y = 8;           // 上边界
    localparam MAX_Y = 135;         // 下边界 (144 - 8 - 1)
    
    // 下一位置
    reg [7:0] next_x, next_y;
    reg [1:0] next_dir;
    
    // 碰撞检测
    reg [4:0] check_x, check_y;
    wire can_move;
    
    // 开火冷却
    reg [4:0] fire_cooldown;
    
    // 计算要检查的地图格子
    assign check_tile_x = check_x;
    assign check_tile_y = check_y;
    
    // 可以移动 = 目标格子是空地
    assign can_move = (tile_type == 2'd0);
    
    // 子弹发射位置 (坦克前方中心)
    assign bullet_start_x = pos_x + 4;
    assign bullet_start_y = pos_y + 4;
    assign bullet_dir = dir;
    
    // 状态机
    localparam IDLE = 2'd0;
    localparam CHECK_COLLISION = 2'd1;
    localparam MOVE = 2'd2;
    
    reg [1:0] state;
    
    always @(posedge clk) begin
        if (!rstn) begin
            pos_x <= INIT_X;
            pos_y <= INIT_Y;
            dir <= INIT_DIR;
            hp <= 2'd3;
            alive <= 1'b1;
            fire_bullet <= 1'b0;
            fire_cooldown <= 5'd0;
            state <= IDLE;
            next_x <= INIT_X;
            next_y <= INIT_Y;
            next_dir <= INIT_DIR;
            check_x <= 5'd0;
            check_y <= 5'd0;
        end
        else begin
            fire_bullet <= 1'b0;
            
            // 被击中处理
            if (hit && alive) begin
                if (hp > 0) begin
                    hp <= hp - 1'b1;
                    if (hp == 1) begin
                        alive <= 1'b0;
                    end
                end
            end
            
            // 开火冷却递减
            if (fire_cooldown > 0 && game_tick) begin
                fire_cooldown <= fire_cooldown - 1'b1;
            end
            
            // 游戏逻辑
            if (game_tick && alive) begin
                case (state)
                    IDLE: begin
                        // 处理开火
                        if (fire && fire_cooldown == 0) begin
                            fire_bullet <= 1'b1;
                            fire_cooldown <= 5'd15;  // 冷却时间
                        end
                        
                        // 处理移动
                        if (move_up) begin
                            next_dir <= 2'd0;
                            next_x <= pos_x;
                            next_y <= (pos_y > MIN_Y) ? pos_y - MOVE_SPEED : pos_y;
                            // 检查上方两个角的格子
                            check_x <= pos_x / 8;
                            check_y <= (pos_y - MOVE_SPEED) / 8;
                            state <= CHECK_COLLISION;
                        end
                        else if (move_down) begin
                            next_dir <= 2'd1;
                            next_x <= pos_x;
                            next_y <= (pos_y < MAX_Y) ? pos_y + MOVE_SPEED : pos_y;
                            check_x <= pos_x / 8;
                            check_y <= (pos_y + TANK_SIZE) / 8;
                            state <= CHECK_COLLISION;
                        end
                        else if (move_left) begin
                            next_dir <= 2'd2;
                            next_x <= (pos_x > MIN_X) ? pos_x - MOVE_SPEED : pos_x;
                            next_y <= pos_y;
                            check_x <= (pos_x - MOVE_SPEED) / 8;
                            check_y <= pos_y / 8;
                            state <= CHECK_COLLISION;
                        end
                        else if (move_right) begin
                            next_dir <= 2'd3;
                            next_x <= (pos_x < MAX_X) ? pos_x + MOVE_SPEED : pos_x;
                            next_y <= pos_y;
                            check_x <= (pos_x + TANK_SIZE) / 8;
                            check_y <= pos_y / 8;
                            state <= CHECK_COLLISION;
                        end
                        else begin
                            // 没有移动输入，只更新方向
                        end
                    end
                    
                    CHECK_COLLISION: begin
                        // 等待一个周期读取地图
                        state <= MOVE;
                    end
                    
                    MOVE: begin
                        dir <= next_dir;
                        if (can_move) begin
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
