//`timescale 1ns / 1ps

//module imageProcessTop(
//    input               axi_clk,
//    input               axi_reset_n,
//    // AXI-Stream Slave Interface (from DMA)
//    input               i_data_valid,
//    input       [7:0]   i_data,
//    output              o_data_ready,
//    // AXI-Stream Master Interface (to DMA)
//    output              o_data_valid,
//    output      [7:0]   o_data,
//    output              o_data_last,
//    input               i_data_ready,
//    // Interrupt
//    output              o_intr
//);

//    // Internal Signals
//    wire [71:0] pixel_data;
//    wire        pixel_data_valid;
//    wire [7:0]  convolved_data;
//    wire        convolved_data_valid;
    
//    // TLAST Generation Signals
//    wire        last_pixel_from_ic;
//    reg         last_pixel_d1, last_pixel_d2, last_pixel_d3;
//    wire        final_tlast;
    
//    // FIFO signals
//    wire        fifo_s_axis_tready; // For backpressure
//    wire        fifo_m_axis_tlast;  // FIFO's TLAST output

//    // *** FIX 3: Proper backpressure ***
//    // This tells the upstream DMA to stop sending data if our pipeline is full.
//    assign o_data_ready = fifo_s_axis_tready;

//    imageControl IC(
//        .i_clk(axi_clk),
//        .i_rst(!axi_reset_n),
//        .i_pixel_data(i_data),
//        .i_pixel_data_valid(i_data_valid),
//        .o_pixel_data(pixel_data),
//        .o_pixel_data_valid(pixel_data_valid),
//        .o_intr(o_intr),
//        .o_last_pixel(last_pixel_from_ic)
//    );

//    conv conv(
//        .i_clk(axi_clk),
//        .i_pixel_data(pixel_data),
//        .i_pixel_data_valid(pixel_data_valid),
//        .o_convolved_data(convolved_data),
//        .o_convolved_data_valid(convolved_data_valid)
//    );

//    // *** FIX 1: Correctly reset the TLAST pipeline ***
//    // This pipeline must only be reset by the system reset, not by the
//    // completion of a previous frame.
//    always @(posedge axi_clk)
//    begin
//        if(!axi_reset_n) begin
//            last_pixel_d1 <= 1'b0;
//            last_pixel_d2 <= 1'b0;
//            last_pixel_d3 <= 1'b0;
//        end
//        else begin
//            // We assume here that there's no backpressure between IC and conv
//            // so we don't need to check for a 'ready' signal here.
//            last_pixel_d1 <= last_pixel_from_ic;
//            last_pixel_d2 <= last_pixel_d1;
//            last_pixel_d3 <= last_pixel_d2;
//        end
//    end
    
//    // *** FIX 2: Correctly generate the TLAST signal for the FIFO input ***
//    // TLAST must be aligned with the valid data it corresponds to.
//    assign final_tlast = last_pixel_d3 & convolved_data_valid;

//    outputBuffer OB (
//        .wr_rst_busy(),
//        .rd_rst_busy(),
//        .s_aclk(axi_clk),
//        .s_aresetn(axi_reset_n),
//        .s_axis_tvalid(convolved_data_valid),
//        .s_axis_tready(fifo_s_axis_tready),  // Connect output for backpressure
//        .s_axis_tdata(convolved_data),
//        .s_axis_tlast(final_tlast),          // Correct TLAST input
//        .m_axis_tvalid(o_data_valid),
//        .m_axis_tready(i_data_ready),
//        .m_axis_tdata(o_data),
//        .m_axis_tlast(fifo_m_axis_tlast)     // Connect to internal wire
//    );

//    // Connect the internal FIFO TLAST output to the module's output port
//    assign o_data_last = fifo_m_axis_tlast;
    
//endmodule


`timescale 1ns / 1ps

module imageProcessTop(
    input               axi_clk,
    input               axi_reset_n,
    // AXI-Stream Slave Interface (from DMA)
    input               i_data_valid,
    input       [7:0]   i_data,
    output              o_data_ready,
    // AXI-Stream Master Interface (to DMA)
    output              o_data_valid,
    output      [7:0]   o_data,
    output              o_data_last,
    input               i_data_ready,
    // Interrupt
    output              o_intr
);

    // Internal Signals
    wire [71:0] pixel_window;
    wire        pixel_window_valid;
    wire        pixel_window_ready; // Backpressure signal FROM conv module
    wire        pixel_window_last;

    wire [7:0]  convolved_data;
    wire        convolved_data_valid;
    wire        convolved_data_ready; // Backpressure signal FROM FIFO
    wire        convolved_data_last;

    // The entire pipeline is ready only if all stages are ready
    assign o_data_ready = pixel_window_ready;

    // Instantiate the main controller with corrected backpressure ports
    imageControl IC(
        .i_clk(axi_clk),
        .i_rst(!axi_reset_n),
        .i_pixel_data(i_data),
        .i_pixel_data_valid(i_data_valid),
        .o_input_ready(o_data_ready), // Connect to top-level ready
        .o_pixel_data(pixel_window),
        .o_pixel_data_valid(pixel_window_valid),
        .o_pixel_data_last(pixel_window_last),
        .i_output_ready(pixel_window_ready), // Connect backpressure from downstream
        .o_intr(o_intr)
    );

    // Instantiate the convolution kernel with backpressure
    // NOTE: You will need to add i_pixel_data_last, i_pixel_data_ready, and o_convolved_data_last ports to your 'conv' module
    conv conv(
        .i_clk(axi_clk),
        .i_pixel_data(pixel_window),
        .i_pixel_data_valid(pixel_window_valid),
        .i_pixel_data_last(pixel_window_last),
        .i_pixel_data_ready(convolved_data_ready),
        .o_convolved_data(convolved_data),
        .o_convolved_data_valid(convolved_data_valid),
        .o_convolved_data_last(convolved_data_last)
    );
    
    // The 'imageControl' module is ready if the 'conv' module is ready
    assign pixel_window_ready = convolved_data_ready;

    // Instantiate the output FIFO buffer
    outputBuffer OB (
        .s_aclk(axi_clk),
        .s_aresetn(axi_reset_n),
        .s_axis_tvalid(convolved_data_valid),
        .s_axis_tready(convolved_data_ready), 
        .s_axis_tdata(convolved_data),
        .s_axis_tlast(convolved_data_last),
        .m_axis_tvalid(o_data_valid),
        .m_axis_tready(i_data_ready),
        .m_axis_tdata(o_data),
        .m_axis_tlast(o_data_last)
    );

endmodule