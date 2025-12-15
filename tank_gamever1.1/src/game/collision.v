// 碰撞检测模块

module collision #(
    parameter integer BULLET_NUM = 64
) (
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
    
    // 子弹状态（支持 64/128）
    input [BULLET_NUM-1:0]     bullet_active,
    input [BULLET_NUM*8-1:0]   bullet_x,
    input [BULLET_NUM*8-1:0]   bullet_y,
    input [BULLET_NUM-1:0]     bullet_owner,
    
    // 碰撞输出
    output reg      p1_hit,
    output reg      p2_hit,
    output reg [BULLET_NUM-1:0] bullet_destroy
);

    // 坦克大小: 3x4
    localparam TANK_W = 3;
    localparam TANK_H = 4;
    // 子弹大小: 2x2
    localparam BULLET_SIZE = 2;
    
    // 子弹坐标拆包
    wire [7:0] bx [0:BULLET_NUM-1];
    wire [7:0] by [0:BULLET_NUM-1];
    genvar gi;
    generate
        for (gi = 0; gi < BULLET_NUM; gi = gi + 1) begin : unpack
            assign bx[gi] = bullet_x[gi*8 +: 8];
            assign by[gi] = bullet_y[gi*8 +: 8];
        end
    endgenerate
    
    // 碰撞检测
    wire [BULLET_NUM-1:0] hit_p1, hit_p2;
    
    genvar i;
    generate
        for (i = 0; i < BULLET_NUM; i = i + 1) begin : collision_check
            // 任何玩家发出的子弹都会对任何人造成伤害（包括“误伤”）
            assign hit_p1[i] = bullet_active[i] && p1_alive &&
                               (bx[i] < p1_x + TANK_W) && (bx[i] + BULLET_SIZE > p1_x) &&
                               (by[i] < p1_y + TANK_H) && (by[i] + BULLET_SIZE > p1_y);
            
            assign hit_p2[i] = bullet_active[i] && p2_alive &&
                               (bx[i] < p2_x + TANK_W) && (bx[i] + BULLET_SIZE > p2_x) &&
                               (by[i] < p2_y + TANK_H) && (by[i] + BULLET_SIZE > p2_y);
        end
    endgenerate
    
    always @(posedge clk) begin
        if (!rstn) begin
            p1_hit <= 1'b0;
            p2_hit <= 1'b0;
            bullet_destroy <= {BULLET_NUM{1'b0}};
        end
        else begin
            p1_hit <= |hit_p1;
            p2_hit <= |hit_p2;
            bullet_destroy <= hit_p1 | hit_p2;
        end
    end

endmodule
