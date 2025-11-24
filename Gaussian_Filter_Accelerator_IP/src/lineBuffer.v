`timescale 1ns / 1ps

module lineBuffer(
    input           i_clk,
    input           i_rst,
    input   [7:0]   i_data,
    input           i_data_valid,
    output  [7:0]   o_data,
    input           i_rd_data
); 

    // Memory for one line of 640 pixels
    reg [7:0] line [639:0];

    // Pointers are 10-bit to address up to 640
    reg [9:0] wrPntr;
    reg [9:0] rdPntr;

    // --- Write Logic ---
    always @(posedge i_clk)
    begin
        if(i_data_valid)
            line[wrPntr] <= i_data;
    end

    // Write pointer with boundary check
    always @(posedge i_clk)
    begin
        if(i_rst)
            wrPntr <= 'd0;
        else if(i_data_valid) begin
            if (wrPntr == 639)
                wrPntr <= 'd0;
            else
                wrPntr <= wrPntr + 1;
        end
    end

    // --- Read Logic ---
    // Read pointer with boundary check
    always @(posedge i_clk)
    begin
        if(i_rst)
            rdPntr <= 'd0;
        else if(i_rd_data) begin
            if (rdPntr == 639)
                rdPntr <= 'd0;
            else
                rdPntr <= rdPntr + 1;
        end
    end

    // Assign the memory output directly to the output port.
    // This removes the one-cycle latency bug that causes the frame shift.
    assign o_data = line[rdPntr];

endmodule
