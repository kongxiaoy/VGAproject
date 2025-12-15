// 地图模块 - 迷宫风格
// 墙壁为2像素宽的线条

module map (
    input           clk,
    input           rstn,
    
    // 读取端口 (渲染用) - 像素级
    input [7:0]     rd_x,           // 0-199
    input [7:0]     rd_y,           // 0-143
    output reg      rd_wall,        // 1=墙壁, 0=空地
    
    // 子弹碰撞检测
    input [7:0]     bullet_x,
    input [7:0]     bullet_y,
    output reg      bullet_hit_wall
);

    // ============================================================
    // 可修改参数区域
    // ============================================================
    localparam WT = 2;  // 墙壁厚度（像素）
    // ============================================================

    // 判断渲染坐标是否为墙壁
    reg rd_is_wall;
    
    always @(*) begin
        rd_is_wall = 1'b0;
        
        // === 外边框 ===
        if (rd_y < WT) rd_is_wall = 1'b1;           // 上
        if (rd_y >= 142) rd_is_wall = 1'b1;         // 下
        if (rd_x < WT) rd_is_wall = 1'b1;           // 左
        if (rd_x >= 198) rd_is_wall = 1'b1;         // 右
        
        // === 水平墙壁 ===
        // y=20 行
        if (rd_y >= 20 && rd_y < 20+WT) begin
            if (rd_x >= 30 && rd_x <= 50) rd_is_wall = 1'b1;
            if (rd_x >= 70 && rd_x <= 90) rd_is_wall = 1'b1;
            if (rd_x >= 110 && rd_x <= 130) rd_is_wall = 1'b1;
            if (rd_x >= 150 && rd_x <= 170) rd_is_wall = 1'b1;
        end
        
        // y=40 行
        if (rd_y >= 40 && rd_y < 40+WT) begin
            if (rd_x >= 10 && rd_x <= 40) rd_is_wall = 1'b1;
            if (rd_x >= 60 && rd_x <= 80) rd_is_wall = 1'b1;
            if (rd_x >= 120 && rd_x <= 140) rd_is_wall = 1'b1;
            if (rd_x >= 160 && rd_x <= 190) rd_is_wall = 1'b1;
        end
        
        // y=60 行
        if (rd_y >= 60 && rd_y < 60+WT) begin
            if (rd_x >= 30 && rd_x <= 60) rd_is_wall = 1'b1;
            if (rd_x >= 90 && rd_x <= 110) rd_is_wall = 1'b1;
            if (rd_x >= 140 && rd_x <= 170) rd_is_wall = 1'b1;
        end
        
        // y=80 行 (中线)
        if (rd_y >= 80 && rd_y < 80+WT) begin
            if (rd_x >= 20 && rd_x <= 50) rd_is_wall = 1'b1;
            if (rd_x >= 70 && rd_x <= 130) rd_is_wall = 1'b1;
            if (rd_x >= 150 && rd_x <= 180) rd_is_wall = 1'b1;
        end
        
        // y=100 行
        if (rd_y >= 100 && rd_y < 100+WT) begin
            if (rd_x >= 10 && rd_x <= 40) rd_is_wall = 1'b1;
            if (rd_x >= 60 && rd_x <= 90) rd_is_wall = 1'b1;
            if (rd_x >= 110 && rd_x <= 140) rd_is_wall = 1'b1;
            if (rd_x >= 160 && rd_x <= 190) rd_is_wall = 1'b1;
        end
        
        // y=120 行
        if (rd_y >= 120 && rd_y < 120+WT) begin
            if (rd_x >= 30 && rd_x <= 60) rd_is_wall = 1'b1;
            if (rd_x >= 80 && rd_x <= 120) rd_is_wall = 1'b1;
            if (rd_x >= 140 && rd_x <= 170) rd_is_wall = 1'b1;
        end
        
        // === 垂直墙壁 ===
        // x=40
        if (rd_x >= 40 && rd_x < 40+WT) begin
            if (rd_y >= 20 && rd_y <= 40) rd_is_wall = 1'b1;
            if (rd_y >= 100 && rd_y <= 120) rd_is_wall = 1'b1;
        end
        
        // x=80
        if (rd_x >= 80 && rd_x < 80+WT) begin
            if (rd_y >= 40 && rd_y <= 60) rd_is_wall = 1'b1;
            if (rd_y >= 100 && rd_y <= 120) rd_is_wall = 1'b1;
        end
        
        // x=120
        if (rd_x >= 120 && rd_x < 120+WT) begin
            if (rd_y >= 20 && rd_y <= 40) rd_is_wall = 1'b1;
            if (rd_y >= 100 && rd_y <= 120) rd_is_wall = 1'b1;
        end
        
        // x=160
        if (rd_x >= 160 && rd_x < 160+WT) begin
            if (rd_y >= 40 && rd_y <= 60) rd_is_wall = 1'b1;
            if (rd_y >= 100 && rd_y <= 120) rd_is_wall = 1'b1;
        end
        
        // x=20
        if (rd_x >= 20 && rd_x < 20+WT) begin
            if (rd_y >= 60 && rd_y <= 80) rd_is_wall = 1'b1;
        end
        
        // x=60
        if (rd_x >= 60 && rd_x < 60+WT) begin
            if (rd_y >= 80 && rd_y <= 100) rd_is_wall = 1'b1;
        end
        
        // x=100
        if (rd_x >= 100 && rd_x < 100+WT) begin
            if (rd_y >= 60 && rd_y <= 80) rd_is_wall = 1'b1;
        end
        
        // x=140
        if (rd_x >= 140 && rd_x < 140+WT) begin
            if (rd_y >= 80 && rd_y <= 100) rd_is_wall = 1'b1;
        end
        
        // x=180
        if (rd_x >= 180 && rd_x < 180+WT) begin
            if (rd_y >= 60 && rd_y <= 80) rd_is_wall = 1'b1;
        end
    end
    
    // 判断子弹坐标是否为墙壁
    reg bullet_is_wall;
    
    always @(*) begin
        bullet_is_wall = 1'b0;
        
        // === 外边框 ===
        if (bullet_y < WT) bullet_is_wall = 1'b1;
        if (bullet_y >= 142) bullet_is_wall = 1'b1;
        if (bullet_x < WT) bullet_is_wall = 1'b1;
        if (bullet_x >= 198) bullet_is_wall = 1'b1;
        
        // === 水平墙壁 ===
        if (bullet_y >= 20 && bullet_y < 20+WT) begin
            if (bullet_x >= 30 && bullet_x <= 50) bullet_is_wall = 1'b1;
            if (bullet_x >= 70 && bullet_x <= 90) bullet_is_wall = 1'b1;
            if (bullet_x >= 110 && bullet_x <= 130) bullet_is_wall = 1'b1;
            if (bullet_x >= 150 && bullet_x <= 170) bullet_is_wall = 1'b1;
        end
        
        if (bullet_y >= 40 && bullet_y < 40+WT) begin
            if (bullet_x >= 10 && bullet_x <= 40) bullet_is_wall = 1'b1;
            if (bullet_x >= 60 && bullet_x <= 80) bullet_is_wall = 1'b1;
            if (bullet_x >= 120 && bullet_x <= 140) bullet_is_wall = 1'b1;
            if (bullet_x >= 160 && bullet_x <= 190) bullet_is_wall = 1'b1;
        end
        
        if (bullet_y >= 60 && bullet_y < 60+WT) begin
            if (bullet_x >= 30 && bullet_x <= 60) bullet_is_wall = 1'b1;
            if (bullet_x >= 90 && bullet_x <= 110) bullet_is_wall = 1'b1;
            if (bullet_x >= 140 && bullet_x <= 170) bullet_is_wall = 1'b1;
        end
        
        if (bullet_y >= 80 && bullet_y < 80+WT) begin
            if (bullet_x >= 20 && bullet_x <= 50) bullet_is_wall = 1'b1;
            if (bullet_x >= 70 && bullet_x <= 130) bullet_is_wall = 1'b1;
            if (bullet_x >= 150 && bullet_x <= 180) bullet_is_wall = 1'b1;
        end
        
        if (bullet_y >= 100 && bullet_y < 100+WT) begin
            if (bullet_x >= 10 && bullet_x <= 40) bullet_is_wall = 1'b1;
            if (bullet_x >= 60 && bullet_x <= 90) bullet_is_wall = 1'b1;
            if (bullet_x >= 110 && bullet_x <= 140) bullet_is_wall = 1'b1;
            if (bullet_x >= 160 && bullet_x <= 190) bullet_is_wall = 1'b1;
        end
        
        if (bullet_y >= 120 && bullet_y < 120+WT) begin
            if (bullet_x >= 30 && bullet_x <= 60) bullet_is_wall = 1'b1;
            if (bullet_x >= 80 && bullet_x <= 120) bullet_is_wall = 1'b1;
            if (bullet_x >= 140 && bullet_x <= 170) bullet_is_wall = 1'b1;
        end
        
        // === 垂直墙壁 ===
        if (bullet_x >= 40 && bullet_x < 40+WT) begin
            if (bullet_y >= 20 && bullet_y <= 40) bullet_is_wall = 1'b1;
            if (bullet_y >= 100 && bullet_y <= 120) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 80 && bullet_x < 80+WT) begin
            if (bullet_y >= 40 && bullet_y <= 60) bullet_is_wall = 1'b1;
            if (bullet_y >= 100 && bullet_y <= 120) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 120 && bullet_x < 120+WT) begin
            if (bullet_y >= 20 && bullet_y <= 40) bullet_is_wall = 1'b1;
            if (bullet_y >= 100 && bullet_y <= 120) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 160 && bullet_x < 160+WT) begin
            if (bullet_y >= 40 && bullet_y <= 60) bullet_is_wall = 1'b1;
            if (bullet_y >= 100 && bullet_y <= 120) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 20 && bullet_x < 20+WT) begin
            if (bullet_y >= 60 && bullet_y <= 80) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 60 && bullet_x < 60+WT) begin
            if (bullet_y >= 80 && bullet_y <= 100) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 100 && bullet_x < 100+WT) begin
            if (bullet_y >= 60 && bullet_y <= 80) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 140 && bullet_x < 140+WT) begin
            if (bullet_y >= 80 && bullet_y <= 100) bullet_is_wall = 1'b1;
        end
        
        if (bullet_x >= 180 && bullet_x < 180+WT) begin
            if (bullet_y >= 60 && bullet_y <= 80) bullet_is_wall = 1'b1;
        end
    end
    
    // 寄存器输出
    always @(posedge clk) begin
        rd_wall <= rd_is_wall;
        bullet_hit_wall <= bullet_is_wall;
    end

endmodule