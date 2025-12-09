// 地图模块
// 存储和管理游戏地图

module map (
    input           clk,
    input           rstn,
    
    // 读取端口 (渲染用)
    input [4:0]     rd_x,           // 0-24
    input [4:0]     rd_y,           // 0-17
    output reg [1:0] rd_tile,       // 0=空 1=砖墙 2=铁墙
    
    // 写入端口 (子弹破坏墙壁)
    input           wr_en,
    input [4:0]     wr_x,
    input [4:0]     wr_y,
    input [1:0]     wr_tile
);

    // 地图大小: 25 x 18 格子
    // 每格 8x8 像素
    // 总游戏区域: 200 x 144 像素 (顶部6像素留给状态栏)
    
    // 地图存储 (使用寄存器数组)
    // 0 = 空地
    // 1 = 砖墙 (可摧毁)
    // 2 = 铁墙 (不可摧毁)
    reg [1:0] tiles [0:24][0:17];
    
    integer i, j;
    
    // 初始化地图
    initial begin
        // 先全部设为空地
        for (i = 0; i < 25; i = i + 1) begin
            for (j = 0; j < 18; j = j + 1) begin
                tiles[i][j] = 2'd0;
            end
        end
        
        // 设置边界铁墙
        for (i = 0; i < 25; i = i + 1) begin
            tiles[i][0] = 2'd2;     // 上边界
            tiles[i][17] = 2'd2;    // 下边界
        end
        for (j = 0; j < 18; j = j + 1) begin
            tiles[0][j] = 2'd2;     // 左边界
            tiles[24][j] = 2'd2;    // 右边界
        end
        
        // 设置中间障碍物 (砖墙)
        // 左侧区域
        tiles[4][3] = 2'd1; tiles[5][3] = 2'd1;
        tiles[4][4] = 2'd1; tiles[5][4] = 2'd1;
        
        tiles[4][7] = 2'd1; tiles[5][7] = 2'd1;
        tiles[4][8] = 2'd1; tiles[5][8] = 2'd1;
        
        tiles[4][13] = 2'd1; tiles[5][13] = 2'd1;
        tiles[4][14] = 2'd1; tiles[5][14] = 2'd1;
        
        // 右侧区域
        tiles[19][3] = 2'd1; tiles[20][3] = 2'd1;
        tiles[19][4] = 2'd1; tiles[20][4] = 2'd1;
        
        tiles[19][7] = 2'd1; tiles[20][7] = 2'd1;
        tiles[19][8] = 2'd1; tiles[20][8] = 2'd1;
        
        tiles[19][13] = 2'd1; tiles[20][13] = 2'd1;
        tiles[19][14] = 2'd1; tiles[20][14] = 2'd1;
        
        // 中间区域
        tiles[11][5] = 2'd1; tiles[12][5] = 2'd1; tiles[13][5] = 2'd1;
        tiles[11][6] = 2'd1; tiles[12][6] = 2'd1; tiles[13][6] = 2'd1;
        
        tiles[11][11] = 2'd1; tiles[12][11] = 2'd1; tiles[13][11] = 2'd1;
        tiles[11][12] = 2'd1; tiles[12][12] = 2'd1; tiles[13][12] = 2'd1;
        
        // 中央铁墙 (不可摧毁)
        tiles[12][8] = 2'd2; tiles[12][9] = 2'd2;
    end
    
    // 读取
    always @(posedge clk) begin
        if (rd_x < 25 && rd_y < 18)
            rd_tile <= tiles[rd_x][rd_y];
        else
            rd_tile <= 2'd0;
    end
    
    // 写入 (用于子弹摧毁砖墙)
    always @(posedge clk) begin
        if (!rstn) begin
            // 复位时重新初始化地图
            // 这里简化处理，实际可以用 initial 块的值
        end
        else if (wr_en) begin
            if (wr_x < 25 && wr_y < 18) begin
                // 只能摧毁砖墙，铁墙不变
                if (tiles[wr_x][wr_y] == 2'd1) begin
                    tiles[wr_x][wr_y] <= wr_tile;
                end
            end
        end
    end

endmodule
