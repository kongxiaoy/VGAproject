// 碰撞检测模块 (修复版)

module collision (
    input           clk,
    input           rstn,
    
    // P1 坦克位置
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input           p1_alive,
    
    // P2 坦克位置
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input           p2_alive,
    
    // 子弹状态 - 展开的信号
    input [3:0]     bullet_active,
    input [7:0]     bullet_x0, bullet_x1, bullet_x2, bullet_x3,
    input [7:0]     bullet_y0, bullet_y1, bullet_y2, bullet_y3,
    input [3:0]     bullet_owner,
    
    // 碰撞输出
    output reg      p1_hit,
    output reg      p2_hit,
    output reg [3:0] bullet_destroy
);

    // 坦克和子弹大小
    localparam TANK_SIZE = 8;
    localparam BULLET_SIZE = 2;
    
    // 内部数组
    wire [7:0] bullet_x [0:3];
    wire [7:0] bullet_y [0:3];
    
    assign bullet_x[0] = bullet_x0; assign bullet_x[1] = bullet_x1;
    assign bullet_x[2] = bullet_x2; assign bullet_x[3] = bullet_x3;
    assign bullet_y[0] = bullet_y0; assign bullet_y[1] = bullet_y1;
    assign bullet_y[2] = bullet_y2; assign bullet_y[3] = bullet_y3;
    
    // 碰撞检测
    wire [3:0] hit_p1, hit_p2;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : collision_check
            // P2的子弹打P1
            assign hit_p1[i] = bullet_active[i] && bullet_owner[i] && p1_alive &&
                               (bullet_x[i] < p1_x + TANK_SIZE) && (bullet_x[i] + BULLET_SIZE > p1_x) &&
                               (bullet_y[i] < p1_y + TANK_SIZE) && (bullet_y[i] + BULLET_SIZE > p1_y);
            
            // P1的子弹打P2
            assign hit_p2[i] = bullet_active[i] && !bullet_owner[i] && p2_alive &&
                               (bullet_x[i] < p2_x + TANK_SIZE) && (bullet_x[i] + BULLET_SIZE > p2_x) &&
                               (bullet_y[i] < p2_y + TANK_SIZE) && (bullet_y[i] + BULLET_SIZE > p2_y);
        end
    endgenerate
    
    always @(posedge clk) begin
        if (!rstn) begin
            p1_hit <= 1'b0;
            p2_hit <= 1'b0;
            bullet_destroy <= 4'b0000;
        end
        else begin
            p1_hit <= |hit_p1;
            p2_hit <= |hit_p2;
            bullet_destroy <= hit_p1 | hit_p2;
        end
    end

endmodule