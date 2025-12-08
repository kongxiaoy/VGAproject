module DST (
    input                   rstn,
    input                   pclk,
    output      reg         hen,        // 水平显示有效
    output      reg         ven,        // 垂直显示有效
    output      reg         hs,         // 行同步
    output      reg         vs          // 场同步
);

    // 水平参数 (题目已给)
    localparam HSW_t    = 119;
    localparam HBP_t    = 63;
    localparam HEN_t    = 799;
    localparam HFP_t    = 55;

    // 垂直参数 (800x600@72Hz, 50MHz PCLK)
    // 根据 VESA 标准：Sync=6, BP=23, Active=600, FP=37
    localparam VSW_t    = 5;   // 6 - 1
    localparam VBP_t    = 22;  // 23 - 1
    localparam VEN_t    = 599; // 600 - 1
    localparam VFP_t    = 36;  // 37 - 1

    // 状态机状态定义
    localparam SW       = 2'b00; // 同步段
    localparam BP       = 2'b01; // 后沿段
    localparam EN       = 2'b10; // 有效数据显示段
    localparam FP       = 2'b11; // 前沿段

    reg     ce_v;        // 垂直计数器使能信号
    reg     [ 1 : 0]    h_state;
    reg     [ 1 : 0]    v_state;
    reg     [15 : 0]    d_h;
    reg     [15 : 0]    d_v;
    wire    [15 : 0]    q_h;
    wire    [15 : 0]    q_v;

    // 水平计数器
    CntS #(16, HSW_t) hcnt (
        .clk        (pclk),
        .rstn       (rstn),
        .d          (d_h),
        .ce         (1'b1),
        .q          (q_h)
    );

    // 垂直计数器
    // 只有当一行扫描结束时，ce_v 才会变高，垂直计数器才减 1
    CntS #(16, VSW_t) vcnt (
        .clk        (pclk),
        .rstn       (rstn),
        .d          (d_v),
        .ce         (ce_v), 
        .q          (q_v)
    );

    // 水平状态机和输出逻辑
    always @(*) begin
        case (h_state)
            SW: begin d_h = HBP_t; hs = 1; hen = 0; end // 同步脉冲通常是正极性或负极性，800x600@72Hz通常为正极性(1)
            BP: begin d_h = HEN_t; hs = 0; hen = 0; end
            EN: begin d_h = HFP_t; hs = 0; hen = 1; end
            FP: begin d_h = HSW_t; hs = 0; hen = 0; end
        endcase
    end

    // 垂直状态机和输出逻辑 (补全部分)
    always @(*) begin
        case (v_state)
            SW: begin d_v = VBP_t; vs = 1; ven = 0; end // Sync
            BP: begin d_v = VEN_t; vs = 0; ven = 0; end // Back Porch
            EN: begin d_v = VFP_t; vs = 0; ven = 1; end // Active
            FP: begin d_v = VSW_t; vs = 0; ven = 0; end // Front Porch
        endcase
    end

    // 状态跳转逻辑
    always @(posedge pclk) begin
        if (!rstn) begin
            h_state <= SW; 
            v_state <= SW; 
            ce_v <= 1'b0;
        end
        else begin
            // 水平状态跳转
            if(q_h == 0) begin
                h_state <= h_state + 2'b01;
                
                // 水平扫描一帧结束逻辑 (在 FP 状态结束时)
                if (h_state == FP) begin
                    ce_v <= 0; // 下个周期 h_state 变回 SW，ce_v 复位
                    // 垂直状态跳转逻辑
                    if (q_v == 0)
                        v_state <= v_state + 2'b01;
                end
                else
                    ce_v <= 0;
            end
            // 产生垂直计数器使能脉冲
            // 在一行即将结束时 (h_state == FP 且计数器快到 0 时) 拉高 ce_v
            // 原代码逻辑分析：当 q_h == 1 且 h_state == FP 时，下一个周期 q_h 变 0，
            // 此时 ce_v 变高，刚好在 q_h=0 的那个周期触发 vcnt 计数。
            else if (q_h == 1) begin
                if(h_state == FP)
                    ce_v <= 1;
                else
                    ce_v <= 0;
            end
            else ce_v <= 0;
        end
    end

endmodule