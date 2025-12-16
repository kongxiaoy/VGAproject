// 迷宫模块 - 经典吃豆人简化版
// 20x15 格子，每格 10x10 像素
// 总分辨率 200x150

module maze (
    input           clk,
    input           rstn,
    input           game_reset,
    
    // 查询接口 - 格子坐标
    input [4:0]     query_x,        // 0-19
    input [3:0]     query_y,        // 0-14
    output          is_wall,
    output          has_dot,
    
    // 渲染接口 - 像素坐标
    input [7:0]     pixel_x,        // 0-199
    input [7:0]     pixel_y,        // 0-149
    output          render_wall,
    output          render_dot,
    
    // 吃豆子接口
    input           eat_dot,
    input [4:0]     eat_x,
    input [3:0]     eat_y,
    
    // 状态输出
    output          all_dots_eaten,
    output [7:0]    dots_remaining
);

    // 格子大小
    localparam CELL_SIZE = 10;
    
    // 迷宫尺寸
    localparam MAZE_W = 20;
    localparam MAZE_H = 15;
    
    // ========================================
    // 迷宫布局定义 (1=墙, 0=路)
    // 经典吃豆人简化版
    // ========================================
    
    // 迷宫数据 - 每行20位
    wire [19:0] maze_row [0:14];
    
    // Row 0: 全墙
    assign maze_row[0]  = 20'b11111111111111111111;
    // Row 1: 上部通道
    assign maze_row[1]  = 20'b10000000110000000001;
    // Row 2: 
    assign maze_row[2]  = 20'b10111011110111101101;
    // Row 3: 
    assign maze_row[3]  = 20'b10000000000000000001;
    // Row 4:
    assign maze_row[4]  = 20'b10110111001110110101;
    // Row 5:
    assign maze_row[5]  = 20'b10000001000001000001;
    // Row 6:
    assign maze_row[6]  = 20'b11110101111101010111;
    // Row 7: 中间通道
    assign maze_row[7]  = 20'b10000100000001000001;
    // Row 8:
    assign maze_row[8]  = 20'b10110101111101011101;
    // Row 9:
    assign maze_row[9]  = 20'b10000100000001000001;
    // Row 10:
    assign maze_row[10] = 20'b10111101110111011101;
    // Row 11:
    assign maze_row[11] = 20'b10000000010000000001;
    // Row 12:
    assign maze_row[12] = 20'b10111011010110111101;
    // Row 13:
    assign maze_row[13] = 20'b10000000000000000001;
    // Row 14: 全墙
    assign maze_row[14] = 20'b11111111111111111111;
    
    // ========================================
    // 墙壁查询
    // ========================================
    
    // 格子坐标查询
    wire wall_at_query = maze_row[query_y][MAZE_W - 1 - query_x];
    assign is_wall = wall_at_query;
    
    // 像素坐标转格子坐标
    wire [4:0] render_cell_x = pixel_x / CELL_SIZE;
    wire [3:0] render_cell_y = pixel_y / CELL_SIZE;
    
    // 渲染墙壁查询
    assign render_wall = maze_row[render_cell_y][MAZE_W - 1 - render_cell_x];
    
    // ========================================
    // 豆子状态 (300个格子，用位图存储)
    // ========================================
    
    // 每行20个豆子状态
    reg [19:0] dots_row [0:14];
    
    // 初始豆子位置 (路上有豆子，墙上没有)
    wire [19:0] init_dots [0:14];
    assign init_dots[0]  = ~maze_row[0];   // 路上有豆子
    assign init_dots[1]  = ~maze_row[1];
    assign init_dots[2]  = ~maze_row[2];
    assign init_dots[3]  = ~maze_row[3];
    assign init_dots[4]  = ~maze_row[4];
    assign init_dots[5]  = ~maze_row[5];
    assign init_dots[6]  = ~maze_row[6];
    assign init_dots[7]  = ~maze_row[7];
    assign init_dots[8]  = ~maze_row[8];
    assign init_dots[9]  = ~maze_row[9];
    assign init_dots[10] = ~maze_row[10];
    assign init_dots[11] = ~maze_row[11];
    assign init_dots[12] = ~maze_row[12];
    assign init_dots[13] = ~maze_row[13];
    assign init_dots[14] = ~maze_row[14];
    
    // 豆子状态管理
    integer i;
    always @(posedge clk) begin
        if (!rstn || game_reset) begin
            // 初始化豆子
            for (i = 0; i < MAZE_H; i = i + 1) begin
                dots_row[i] <= init_dots[i];
            end
        end
        else if (eat_dot) begin
            // 吃掉豆子
            dots_row[eat_y][MAZE_W - 1 - eat_x] <= 1'b0;
        end
    end
    
    // 查询豆子
    assign has_dot = dots_row[query_y][MAZE_W - 1 - query_x];
    
    // 渲染豆子 - 只在格子中心附近显示
    wire [3:0] pixel_in_cell_x = pixel_x % CELL_SIZE;
    wire [3:0] pixel_in_cell_y = pixel_y % CELL_SIZE;
    wire in_dot_area = (pixel_in_cell_x >= 4) && (pixel_in_cell_x <= 5) &&
                       (pixel_in_cell_y >= 4) && (pixel_in_cell_y <= 5);
    wire dot_exists = dots_row[render_cell_y][MAZE_W - 1 - render_cell_x];
    assign render_dot = in_dot_area && dot_exists && !render_wall;
    
    // ========================================
    // 豆子计数
    // ========================================
    
    // 统计剩余豆子数量
    reg [7:0] dot_count;
    integer r, c;
    always @(*) begin
        dot_count = 8'd0;
        for (r = 0; r < MAZE_H; r = r + 1) begin
            for (c = 0; c < MAZE_W; c = c + 1) begin
                if (dots_row[r][c]) begin
                    dot_count = dot_count + 1'b1;
                end
            end
        end
    end
    
    assign dots_remaining = dot_count;
    assign all_dots_eaten = (dot_count == 8'd0);

endmodule
