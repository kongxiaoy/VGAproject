// 子弹管理模块 (修复版)
// 展开数组端口，兼容Verilog标准

module bullet (
    input           clk,
    input           rstn,
    input           game_tick,
    
    // P1 发射
    input           p1_fire,
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input [1:0]     p1_dir,
    
    // P2 发射
    input           p2_fire,
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input [1:0]     p2_dir,
    
    // 地图碰撞
    output reg [4:0]    map_check_x,
    output reg [4:0]    map_check_y,
    input [1:0]         map_tile,
    
    // 墙壁破坏
    output reg          destroy_wall,
    output reg [4:0]    destroy_x,
    output reg [4:0]    destroy_y,
    
    // 子弹状态输出 - 展开为单独信号
    output reg [3:0]    bullet_active,
    output reg [7:0]    bullet_x0, bullet_x1, bullet_x2, bullet_x3,
    output reg [7:0]    bullet_y0, bullet_y1, bullet_y2, bullet_y3,
    output reg [1:0]    bullet_dir0, bullet_dir1, bullet_dir2, bullet_dir3,
    output reg [3:0]    bullet_owner   // 0=P1, 1=P2
);

    // 内部数组
    reg [7:0] bullet_x [0:3];
    reg [7:0] bullet_y [0:3];
    reg [1:0] bullet_dir [0:3];
    
    // 同步到输出端口
    always @(*) begin
        bullet_x0 = bullet_x[0]; bullet_x1 = bullet_x[1];
        bullet_x2 = bullet_x[2]; bullet_x3 = bullet_x[3];
        bullet_y0 = bullet_y[0]; bullet_y1 = bullet_y[1];
        bullet_y2 = bullet_y[2]; bullet_y3 = bullet_y[3];
        bullet_dir0 = bullet_dir[0]; bullet_dir1 = bullet_dir[1];
        bullet_dir2 = bullet_dir[2]; bullet_dir3 = bullet_dir[3];
    end

    // 子弹速度
    localparam BULLET_SPEED = 2;
    
    // 游戏区域边界
    localparam MIN_X = 8;
    localparam MAX_X = 192;
    localparam MIN_Y = 8;
    localparam MAX_Y = 136;
    
    // 状态机
    reg [2:0] process_idx;
    reg [1:0] bullet_state;
    
    localparam B_IDLE = 2'd0;
    localparam B_CHECK = 2'd1;
    localparam B_UPDATE = 2'd2;
    
    reg [7:0] next_x, next_y;
    
    integer i;
    
    // 初始化
    initial begin
        bullet_active = 4'b0000;
        bullet_owner = 4'b0000;
        for (i = 0; i < 4; i = i + 1) begin
            bullet_x[i] = 8'd0;
            bullet_y[i] = 8'd0;
            bullet_dir[i] = 2'd0;
        end
    end
    
    always @(posedge clk) begin
        if (!rstn) begin
            bullet_active <= 4'b0000;
            bullet_owner <= 4'b0000;
            process_idx <= 3'd0;
            bullet_state <= B_IDLE;
            destroy_wall <= 1'b0;
            
            for (i = 0; i < 4; i = i + 1) begin
                bullet_x[i] <= 8'd0;
                bullet_y[i] <= 8'd0;
                bullet_dir[i] <= 2'd0;
            end
        end
        else begin
            destroy_wall <= 1'b0;
            
            // P1 发射
            if (p1_fire) begin
                if (!bullet_active[0]) begin
                    bullet_active[0] <= 1'b1;
                    bullet_x[0] <= p1_x;
                    bullet_y[0] <= p1_y;
                    bullet_dir[0] <= p1_dir;
                    bullet_owner[0] <= 1'b0;
                end
                else if (!bullet_active[1]) begin
                    bullet_active[1] <= 1'b1;
                    bullet_x[1] <= p1_x;
                    bullet_y[1] <= p1_y;
                    bullet_dir[1] <= p1_dir;
                    bullet_owner[1] <= 1'b0;
                end
            end
            
            // P2 发射
            if (p2_fire) begin
                if (!bullet_active[2]) begin
                    bullet_active[2] <= 1'b1;
                    bullet_x[2] <= p2_x;
                    bullet_y[2] <= p2_y;
                    bullet_dir[2] <= p2_dir;
                    bullet_owner[2] <= 1'b1;
                end
                else if (!bullet_active[3]) begin
                    bullet_active[3] <= 1'b1;
                    bullet_x[3] <= p2_x;
                    bullet_y[3] <= p2_y;
                    bullet_dir[3] <= p2_dir;
                    bullet_owner[3] <= 1'b1;
                end
            end
            
            // 更新子弹位置
            if (game_tick) begin
                case (bullet_state)
                    B_IDLE: begin
                        if (bullet_active[process_idx]) begin
                            case (bullet_dir[process_idx])
                                2'd0: begin
                                    next_x <= bullet_x[process_idx];
                                    next_y <= bullet_y[process_idx] - BULLET_SPEED;
                                end
                                2'd1: begin
                                    next_x <= bullet_x[process_idx];
                                    next_y <= bullet_y[process_idx] + BULLET_SPEED;
                                end
                                2'd2: begin
                                    next_x <= bullet_x[process_idx] - BULLET_SPEED;
                                    next_y <= bullet_y[process_idx];
                                end
                                2'd3: begin
                                    next_x <= bullet_x[process_idx] + BULLET_SPEED;
                                    next_y <= bullet_y[process_idx];
                                end
                            endcase
                            
                            map_check_x <= bullet_x[process_idx] / 8;
                            map_check_y <= bullet_y[process_idx] / 8;
                            bullet_state <= B_CHECK;
                        end
                        else begin
                            if (process_idx >= 3)
                                process_idx <= 3'd0;
                            else
                                process_idx <= process_idx + 1'b1;
                        end
                    end
                    
                    B_CHECK: begin
                        bullet_state <= B_UPDATE;
                    end
                    
                    B_UPDATE: begin
                        if (next_x < MIN_X || next_x >= MAX_X ||
                            next_y < MIN_Y || next_y >= MAX_Y) begin
                            bullet_active[process_idx] <= 1'b0;
                        end
                        else if (map_tile == 2'd1) begin
                            bullet_active[process_idx] <= 1'b0;
                            destroy_wall <= 1'b1;
                            destroy_x <= map_check_x;
                            destroy_y <= map_check_y;
                        end
                        else if (map_tile == 2'd2) begin
                            bullet_active[process_idx] <= 1'b0;
                        end
                        else begin
                            bullet_x[process_idx] <= next_x;
                            bullet_y[process_idx] <= next_y;
                        end
                        
                        if (process_idx >= 3)
                            process_idx <= 3'd0;
                        else
                            process_idx <= process_idx + 1'b1;
                        
                        bullet_state <= B_IDLE;
                    end
                    
                    default: bullet_state <= B_IDLE;
                endcase
            end
        end
    end

endmodule