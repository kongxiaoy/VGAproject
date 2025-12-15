// 游戏专用显示数据处理模块
// 不使用VRAM，直接输出像素坐标

module game_ddp (
    input               hen,
    input               ven,
    input               rstn,
    input               pclk,
    
    // 输出当前像素坐标 (200x150 分辨率)
    output reg [7:0]    pixel_x,        // 0-199
    output reg [8:0]    pixel_y,        // 0-149
    output reg          in_display      // 是否在有效显示区
);

    // 放大倍数 (4x4 = 800x600 -> 200x150)
    reg [1:0] sx, sy;
    
    // 上一次的有效信号
    reg hen_d, ven_d;
    wire hen_fall, ven_fall;
    
    always @(posedge pclk) begin
        hen_d <= hen;
        ven_d <= ven;
    end
    
    assign hen_fall = hen_d & ~hen;  // hen下降沿
    assign ven_fall = ven_d & ~ven;  // ven下降沿
    
    always @(posedge pclk) begin
        if (!rstn) begin
            pixel_x <= 8'd0;
            pixel_y <= 9'd0;
            sx <= 2'd0;
            sy <= 2'd0;
            in_display <= 1'b0;
        end
        else begin
            in_display <= hen & ven;
            
            if (hen & ven) begin
                // 在有效显示区
                sx <= sx + 1'b1;
                
                if (sx == 2'd3) begin
                    // 每4个像素，x坐标+1
                    sx <= 2'd0;
                    if (pixel_x < 199)
                        pixel_x <= pixel_x + 1'b1;
                end
            end
            else if (hen_fall) begin
                // 一行结束
                pixel_x <= 8'd0;
                sx <= 2'd0;
                
                sy <= sy + 1'b1;
                if (sy == 2'd3) begin
                    sy <= 2'd0;
                    if (pixel_y < 149)
                        pixel_y <= pixel_y + 1'b1;
                end
            end
            else if (ven_fall) begin
                // 一帧结束
                pixel_x <= 8'd0;
                pixel_y <= 9'd0;
                sx <= 2'd0;
                sy <= 2'd0;
            end
        end
    end

endmodule
