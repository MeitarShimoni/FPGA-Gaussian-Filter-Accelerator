// Helper module for the horizontal window - CORRECTED VERSION
module line_window (
    input               i_clk,
    input               i_en,
    input       [7:0]   i_data,
    output      [23:0]  o_win
);
    reg [7:0] d1_reg, d2_reg;

    always @(posedge i_clk) begin
        if (i_en) begin
            d1_reg <= i_data;
            d2_reg <= d1_reg;
        end
    end

    // Combinatorially assemble the window from the current input and the registered previous values
    assign o_win = {d2_reg, d1_reg, i_data};
endmodule