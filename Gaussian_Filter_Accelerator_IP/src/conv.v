`timescale 1ns / 1ps

module conv(
    input               i_clk,
    // Input Stream with full flow control
    input       [71:0]  i_pixel_data,
    input               i_pixel_data_valid,
    input               i_pixel_data_last,    // NEW: End-of-frame signal
    input               i_pixel_data_ready,   // NEW: Backpressure signal from downstream

    // Output Stream with full flow control
    output reg  [7:0]   o_convolved_data,
    output reg          o_convolved_data_valid,
    output reg          o_convolved_data_last   // NEW: Pass the end-of-frame signal
);
    
    integer i;  
    reg [7:0] kernel [8:0];
    
    // Pipeline stage 1 registers
    reg [15:0] multData[8:0];
    reg        multDataValid;
    reg        multDataLast;

    // Pipeline stage 2 registers
    reg [15:0] sumData;
    reg        sumDataValid;
    reg        sumDataLast;

    // Kernel initialization
    initial
    begin
        kernel[0] = 1; kernel[1] = 2; kernel[2] = 1;
        kernel[3] = 2; kernel[4] = 4; kernel[5] = 2;
        kernel[6] = 1; kernel[7] = 2; kernel[8] = 1;
    end

    // The pipeline advances only if the downstream stage is ready to accept data.
    // This signal gates all pipeline stages to implement stalling.
    wire advance_pipeline = i_pixel_data_ready;

    // Stage 1: Multiplication
    // This stage is controlled by the input valid signal
    always @(posedge i_clk)
    begin
        if (advance_pipeline) begin
            for(i = 0; i < 9; i = i + 1) begin
                multData[i] <= kernel[i] * i_pixel_data[i*8 +: 8];
            end
            multDataValid <= i_pixel_data_valid;
            multDataLast  <= i_pixel_data_last; // Pass 'last' signal into the pipeline
        end
    end

    // Stage 2: Summation
    // This stage is controlled by the valid signal from the previous stage
    always @(posedge i_clk)
    begin
        if (advance_pipeline) begin
            sumData <= multData[0] + multData[1] + multData[2] +
                       multData[3] + multData[4] + multData[5] +
                       multData[6] + multData[7] + multData[8];

            sumDataValid <= multDataValid;
            sumDataLast  <= multDataLast; // Pass 'last' signal to the next stage
        end
    end

    // Stage 3: Division and Output
    // This is the final output stage of the module
    always @(posedge i_clk)
    begin
        if (advance_pipeline) begin
            o_convolved_data      <= sumData >> 4; // Divide by 16
            o_convolved_data_valid <= sumDataValid;
            o_convolved_data_last  <= sumDataLast; // Output the final 'last' signal
        end
    end
    
endmodule