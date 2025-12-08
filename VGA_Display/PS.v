module PS#(
    parameter WIDTH = 1
)(
    input             s,
    input             clk,
    output            p
);
    reg s_reg;
    always @(posedge clk) begin
        s_reg <= s;
    end
    
    // 取下降沿: 上一周期是1，当前周期是0
    // 但注意 DST 中传入的是 ~(hen&ven)，所以我们要检测的是输入信号的“上升沿”
    // 或者是 (hen&ven) 的下降沿。
    // 题目代码是 input s = ~(hen&ven)。
    // 当显示结束时，hen&ven 变为 0， s 变为 1。
    // 所以我们要检测 s 的 上升沿？
    // 让我们看 DDP 代码： else if(p) begin ... end
    // DDP 需要在每一行有效像素结束后复位 X 坐标，增加 Y 坐标。
    // 所以我们需要在 hen&ven 变低的那一瞬间产生脉冲。
    // 如果传入的是 ~(hen&ven)，它从 0 变 1。
    // 那么检测上升沿： s & !s_reg
    
    assign p = s & (~s_reg); 

endmodule