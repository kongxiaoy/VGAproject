// 碰撞检测模块

module collision (
    input           clk,
    input           rstn,
    
    // P1 坦克
    input [7:0]     p1_x,
    input [7:0]     p1_y,
    input           p1_alive,
    
    // P2 坦克
    input [7:0]     p2_x,
    input [7:0]     p2_y,
    input           p2_alive,
    
    // 子弹状态 (8颗)
    input [7:0]     bullet_active,
    input [7:0]     bullet_x0, bullet_x1, bullet_x2, bullet_x3,
    input [7:0]     bullet_x4, bullet_x5, bullet_x6, bullet_x7,
    input [7:0]     bullet_y0, bullet_y1, bullet_y2, bullet_y3,
    input [7:0]     bullet_y4, bullet_y5, bullet_y6, bullet_y7,
    input [7:0]     bullet_owner,
    
    // 碰撞输出
    output reg      p1_hit,
    output reg      p2_hit,
    output reg [7:0] bullet_destroy
);

    // 坦克大小: 3x4
    localparam TANK_W = 3;
    localparam TANK_H = 4;
    // 子弹大小: 2x2
    localparam BULLET_SIZE = 2;
    
    // 内部数组
    wire [7:0] bx [0:7];
    wire [7:0] by [0:7];
    
    assign bx[0] = bullet_x0; assign bx[1] = bullet_x1;
    assign bx[2] = bullet_x2; assign bx[3] = bullet_x3;
    assign bx[4] = bullet_x4; assign bx[5] = bullet_x5;
    assign bx[6] = bullet_x6; assign bx[7] = bullet_x7;
    assign by[0] = bullet_y0; assign by[1] = bullet_y1;
    assign by[2] = bullet_y2; assign by[3] = bullet_y3;
    assign by[4] = bullet_y4; assign by[5] = bullet_y5;
    assign by[6] = bullet_y6; assign by[7] = bullet_y7;
    
    // 碰撞检测
    wire [7:0] hit_p1, hit_p2;
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : collision_check
            // P2的子弹打P1
            assign hit_p1[i] = bullet_active[i] && bullet_owner[i] && p1_alive &&
                               (bx[i] < p1_x + TANK_W) && (bx[i] + BULLET_SIZE > p1_x) &&
                               (by[i] < p1_y + TANK_H) && (by[i] + BULLET_SIZE > p1_y);
            
            // P1的子弹打P2
            assign hit_p2[i] = bullet_active[i] && !bullet_owner[i] && p2_alive &&
                               (bx[i] < p2_x + TANK_W) && (bx[i] + BULLET_SIZE > p2_x) &&
                               (by[i] < p2_y + TANK_H) && (by[i] + BULLET_SIZE > p2_y);
        end
    endgenerate
    
    always @(posedge clk) begin
        if (!rstn) begin
            p1_hit <= 1'b0;
            p2_hit <= 1'b0;
            bullet_destroy <= 8'd0;
        end
        else begin
            p1_hit <= |hit_p1;
            p2_hit <= |hit_p2;
            bullet_destroy <= hit_p1 | hit_p2;
        end
    end

endmodule
