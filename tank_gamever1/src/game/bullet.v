// 子弹管理模块 - 支持反弹、散弹、穿墙
// 子弹速度为坦克速度的1.5倍（坦克速度1，子弹速度使用计数器实现1.5）

module bullet (
    input           clk,
    input           rstn,
    input           game_tick,
    input           game_start,
    
    // P1 发射
    input           p1_fire,
    input           p1_spread,
    input           p1_pierce,
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input [1:0]     p1_dir,
    
    // P2 发射
    input           p2_fire,
    input           p2_spread,
    input           p2_pierce,
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input [1:0]     p2_dir,
    
    // 墙壁碰撞
    output reg [7:0]    wall_check_x,
    output reg [7:0]    wall_check_y,
    input               wall_hit,
    
    // 子弹状态输出
    output reg [7:0]    bullet_active,
    output reg [7:0]    bullet_x0, bullet_x1, bullet_x2, bullet_x3,
    output reg [7:0]    bullet_x4, bullet_x5, bullet_x6, bullet_x7,
    output reg [7:0]    bullet_y0, bullet_y1, bullet_y2, bullet_y3,
    output reg [7:0]    bullet_y4, bullet_y5, bullet_y6, bullet_y7,
    output reg [1:0]    bullet_dir0, bullet_dir1, bullet_dir2, bullet_dir3,
    output reg [1:0]    bullet_dir4, bullet_dir5, bullet_dir6, bullet_dir7,
    output reg [7:0]    bullet_owner,
    output reg [7:0]    bullet_pierce
);

    // ============================================================
    // 可修改参数区域
    // ============================================================
    // 子弹速度：每2个tick移动3像素 (相当于1.5倍速度)
    // 坦克速度是每tick移动1像素
    localparam BULLET_MOVE_PIXELS = 2;  // 每次移动像素数
    localparam MAX_BOUNCES = 3;          // 最大反弹次数
    // ============================================================

    // 内部存储
    reg [7:0] b_x [0:7];
    reg [7:0] b_y [0:7];
    reg [1:0] b_dir [0:7];
    reg [1:0] b_bounce [0:7];  // 反弹计数
    
    // 游戏边界
    localparam MIN_X = 2;
    localparam MAX_X = 196;
    localparam MIN_Y = 2;
    localparam MAX_Y = 140;
    
    // 状态机
    reg [2:0] process_idx;
    reg [2:0] bullet_state;
    
    localparam B_IDLE = 3'd0;
    localparam B_CALC_NEXT = 3'd1;
    localparam B_CHECK_WALL = 3'd2;
    localparam B_UPDATE = 3'd3;
    
    reg [7:0] next_x, next_y;
    reg [1:0] next_dir;
    reg check_bounce;
    
    // 同步输出
    always @(*) begin
        bullet_x0 = b_x[0]; bullet_x1 = b_x[1]; bullet_x2 = b_x[2]; bullet_x3 = b_x[3];
        bullet_x4 = b_x[4]; bullet_x5 = b_x[5]; bullet_x6 = b_x[6]; bullet_x7 = b_x[7];
        bullet_y0 = b_y[0]; bullet_y1 = b_y[1]; bullet_y2 = b_y[2]; bullet_y3 = b_y[3];
        bullet_y4 = b_y[4]; bullet_y5 = b_y[5]; bullet_y6 = b_y[6]; bullet_y7 = b_y[7];
        bullet_dir0 = b_dir[0]; bullet_dir1 = b_dir[1]; bullet_dir2 = b_dir[2]; bullet_dir3 = b_dir[3];
        bullet_dir4 = b_dir[4]; bullet_dir5 = b_dir[5]; bullet_dir6 = b_dir[6]; bullet_dir7 = b_dir[7];
    end
    
    // 找空闲槽位
    wire [2:0] free_slot;
    assign free_slot = !bullet_active[0] ? 3'd0 :
                       !bullet_active[1] ? 3'd1 :
                       !bullet_active[2] ? 3'd2 :
                       !bullet_active[3] ? 3'd3 :
                       !bullet_active[4] ? 3'd4 :
                       !bullet_active[5] ? 3'd5 :
                       !bullet_active[6] ? 3'd6 :
                       !bullet_active[7] ? 3'd7 : 3'd0;
    wire has_free = (bullet_active != 8'hFF);
    
    // 第二、第三空闲槽位 (散弹用)
    wire [7:0] active_after_1 = bullet_active | (8'b1 << free_slot);
    wire [2:0] free_slot2 = !active_after_1[0] ? 3'd0 : !active_after_1[1] ? 3'd1 :
                            !active_after_1[2] ? 3'd2 : !active_after_1[3] ? 3'd3 :
                            !active_after_1[4] ? 3'd4 : !active_after_1[5] ? 3'd5 :
                            !active_after_1[6] ? 3'd6 : !active_after_1[7] ? 3'd7 : 3'd0;
    
    wire [7:0] active_after_2 = active_after_1 | (8'b1 << free_slot2);
    wire [2:0] free_slot3 = !active_after_2[0] ? 3'd0 : !active_after_2[1] ? 3'd1 :
                            !active_after_2[2] ? 3'd2 : !active_after_2[3] ? 3'd3 :
                            !active_after_2[4] ? 3'd4 : !active_after_2[5] ? 3'd5 :
                            !active_after_2[6] ? 3'd6 : !active_after_2[7] ? 3'd7 : 3'd0;
    
    integer i;
    
    always @(posedge clk) begin
        if (!rstn || !game_start) begin
            bullet_active <= 8'd0;
            bullet_owner <= 8'd0;
            bullet_pierce <= 8'd0;
            process_idx <= 3'd0;
            bullet_state <= B_IDLE;
            for (i = 0; i < 8; i = i + 1) begin
                b_x[i] <= 8'd0;
                b_y[i] <= 8'd0;
                b_dir[i] <= 2'd0;
                b_bounce[i] <= 2'd0;
            end
        end
        else begin
            // P1 发射
            if (p1_fire && has_free) begin
                bullet_active[free_slot] <= 1'b1;
                b_x[free_slot] <= p1_x;
                b_y[free_slot] <= p1_y;
                b_dir[free_slot] <= p1_dir;
                b_bounce[free_slot] <= 2'd0;
                bullet_owner[free_slot] <= 1'b0;
                bullet_pierce[free_slot] <= p1_pierce;
                
                // 散弹
                if (p1_spread && (active_after_1 != 8'hFF)) begin
                    bullet_active[free_slot2] <= 1'b1;
                    b_x[free_slot2] <= p1_x + 3;
                    b_y[free_slot2] <= p1_y;
                    b_dir[free_slot2] <= p1_dir;
                    b_bounce[free_slot2] <= 2'd0;
                    bullet_owner[free_slot2] <= 1'b0;
                    bullet_pierce[free_slot2] <= p1_pierce;
                    
                    if (active_after_2 != 8'hFF) begin
                        bullet_active[free_slot3] <= 1'b1;
                        b_x[free_slot3] <= (p1_x > 3) ? p1_x - 3 : 8'd0;
                        b_y[free_slot3] <= p1_y;
                        b_dir[free_slot3] <= p1_dir;
                        b_bounce[free_slot3] <= 2'd0;
                        bullet_owner[free_slot3] <= 1'b0;
                        bullet_pierce[free_slot3] <= p1_pierce;
                    end
                end
            end
            
            // P2 发射
            if (p2_fire && has_free) begin
                bullet_active[free_slot] <= 1'b1;
                b_x[free_slot] <= p2_x;
                b_y[free_slot] <= p2_y;
                b_dir[free_slot] <= p2_dir;
                b_bounce[free_slot] <= 2'd0;
                bullet_owner[free_slot] <= 1'b1;
                bullet_pierce[free_slot] <= p2_pierce;
                
                if (p2_spread && (active_after_1 != 8'hFF)) begin
                    bullet_active[free_slot2] <= 1'b1;
                    b_x[free_slot2] <= p2_x + 3;
                    b_y[free_slot2] <= p2_y;
                    b_dir[free_slot2] <= p2_dir;
                    b_bounce[free_slot2] <= 2'd0;
                    bullet_owner[free_slot2] <= 1'b1;
                    bullet_pierce[free_slot2] <= p2_pierce;
                    
                    if (active_after_2 != 8'hFF) begin
                        bullet_active[free_slot3] <= 1'b1;
                        b_x[free_slot3] <= (p2_x > 3) ? p2_x - 3 : 8'd0;
                        b_y[free_slot3] <= p2_y;
                        b_dir[free_slot3] <= p2_dir;
                        b_bounce[free_slot3] <= 2'd0;
                        bullet_owner[free_slot3] <= 1'b1;
                        bullet_pierce[free_slot3] <= p2_pierce;
                    end
                end
            end
            
            // 更新子弹位置
            if (game_tick) begin
                case (bullet_state)
                    B_IDLE: begin
                        if (bullet_active[process_idx]) begin
                            bullet_state <= B_CALC_NEXT;
                        end
                        else begin
                            process_idx <= (process_idx == 3'd7) ? 3'd0 : process_idx + 3'd1;
                        end
                    end
                    
                    B_CALC_NEXT: begin
                        // 计算下一位置
                        case (b_dir[process_idx])
                            2'd0: begin // 上
                                next_x <= b_x[process_idx];
                                next_y <= (b_y[process_idx] > BULLET_MOVE_PIXELS) ? 
                                          b_y[process_idx] - BULLET_MOVE_PIXELS : 8'd0;
                            end
                            2'd1: begin // 下
                                next_x <= b_x[process_idx];
                                next_y <= b_y[process_idx] + BULLET_MOVE_PIXELS;
                            end
                            2'd2: begin // 左
                                next_x <= (b_x[process_idx] > BULLET_MOVE_PIXELS) ?
                                          b_x[process_idx] - BULLET_MOVE_PIXELS : 8'd0;
                                next_y <= b_y[process_idx];
                            end
                            2'd3: begin // 右
                                next_x <= b_x[process_idx] + BULLET_MOVE_PIXELS;
                                next_y <= b_y[process_idx];
                            end
                        endcase
                        next_dir <= b_dir[process_idx];
                        check_bounce <= 1'b0;
                        
                        // 设置墙壁检测坐标
                        wall_check_x <= b_x[process_idx];
                        wall_check_y <= b_y[process_idx];
                        
                        bullet_state <= B_CHECK_WALL;
                    end
                    
                    B_CHECK_WALL: begin
                        bullet_state <= B_UPDATE;
                    end
                    
                    B_UPDATE: begin
                        // 边界检测和反弹
                        if (next_x <= MIN_X || next_x >= MAX_X) begin
                            // 左右边界反弹
                            if (b_bounce[process_idx] < MAX_BOUNCES) begin
                                // 反转水平方向
                                if (b_dir[process_idx] == 2'd2) b_dir[process_idx] <= 2'd3;  // 左->右
                                else if (b_dir[process_idx] == 2'd3) b_dir[process_idx] <= 2'd2;  // 右->左
                                b_bounce[process_idx] <= b_bounce[process_idx] + 1'b1;
                                // 保持在边界内
                                if (next_x <= MIN_X) b_x[process_idx] <= MIN_X + 1;
                                else b_x[process_idx] <= MAX_X - 1;
                            end
                            else begin
                                bullet_active[process_idx] <= 1'b0;
                            end
                        end
                        else if (next_y <= MIN_Y || next_y >= MAX_Y) begin
                            // 上下边界反弹
                            if (b_bounce[process_idx] < MAX_BOUNCES) begin
                                // 反转垂直方向
                                if (b_dir[process_idx] == 2'd0) b_dir[process_idx] <= 2'd1;  // 上->下
                                else if (b_dir[process_idx] == 2'd1) b_dir[process_idx] <= 2'd0;  // 下->上
                                b_bounce[process_idx] <= b_bounce[process_idx] + 1'b1;
                                if (next_y <= MIN_Y) b_y[process_idx] <= MIN_Y + 1;
                                else b_y[process_idx] <= MAX_Y - 1;
                            end
                            else begin
                                bullet_active[process_idx] <= 1'b0;
                            end
                        end
                        // 墙壁碰撞
                        else if (wall_hit && !bullet_pierce[process_idx]) begin
                            // 墙壁反弹
                            if (b_bounce[process_idx] < MAX_BOUNCES) begin
                                // 简单反弹：反转当前方向
                                case (b_dir[process_idx])
                                    2'd0: b_dir[process_idx] <= 2'd1;
                                    2'd1: b_dir[process_idx] <= 2'd0;
                                    2'd2: b_dir[process_idx] <= 2'd3;
                                    2'd3: b_dir[process_idx] <= 2'd2;
                                endcase
                                b_bounce[process_idx] <= b_bounce[process_idx] + 1'b1;
                            end
                            else begin
                                bullet_active[process_idx] <= 1'b0;
                            end
                        end
                        else begin
                            // 正常移动
                            b_x[process_idx] <= next_x;
                            b_y[process_idx] <= next_y;
                        end
                        
                        process_idx <= (process_idx == 3'd7) ? 3'd0 : process_idx + 3'd1;
                        bullet_state <= B_IDLE;
                    end
                    
                    default: bullet_state <= B_IDLE;
                endcase
            end
        end
    end

endmodule