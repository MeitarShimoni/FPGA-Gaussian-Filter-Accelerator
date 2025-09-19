`timescale 1ns / 1ps

// =================================================================
// === CORRECTED "Golden" Version of imageControl ===
// =================================================================
module imageControl(
    input               i_clk,
    input               i_rst,
    // Input Stream
    input       [7:0]   i_pixel_data,
    input               i_pixel_data_valid,
    output              o_input_ready,      // To upstream
    // Output Stream
    output reg  [71:0]  o_pixel_data,
    output reg          o_pixel_data_valid,
    output reg          o_pixel_data_last,
    input               i_output_ready,     // From downstream
    // Interrupt
    output reg          o_intr
);

    // 1. States and Internal Signals
    localparam STATE_IDLE = 1'b0;
    localparam STATE_PROCESSING = 1'b1;
    reg  state;

    // Counters
    reg [9:0] wr_pixel_cnt, wr_line_cnt;
    reg [9:0] rd_pixel_cnt, rd_line_cnt;

    // Line buffer pointers
    reg [1:0] wr_buf_ptr, rd_buf_ptr;

    // Control signals
    wire wr_en = i_pixel_data_valid && o_input_ready;
    wire rd_en = o_pixel_data_valid && i_output_ready;
    wire line_written = wr_en && (wr_pixel_cnt == 639);
    wire line_read = rd_en && (rd_pixel_cnt == 639);

    wire start_processing = (wr_line_cnt == 3) && (state == STATE_IDLE); // CRITICAL FIX: Must be 3
    wire stop_processing  = line_read && (rd_line_cnt == 477);

    // Line buffer signals
    reg [3:0] line_buf_rd_en_logic;
    wire [3:0] line_buf_wr_en = (1'b1 << wr_buf_ptr) & {4{wr_en}};
    wire [3:0] line_buf_rd_en = line_buf_rd_en_logic & {4{rd_en}};

    wire [7:0] lb0_out, lb1_out, lb2_out, lb3_out;
    wire [23:0] lb0_win, lb1_win, lb2_win, lb3_win;

    // We pass the backpressure signal through.
    assign o_input_ready = i_output_ready;

    // 2. State Machine
    always @(posedge i_clk) begin
        if (i_rst) state <= STATE_IDLE;
        else if (start_processing) state <= STATE_PROCESSING;
        else if (stop_processing) state <= STATE_IDLE;
    end

    // 3. Counters
    always @(posedge i_clk) if (i_rst) wr_pixel_cnt <= 0; else if (wr_en) wr_pixel_cnt <= (wr_pixel_cnt == 639) ? 0 : wr_pixel_cnt + 1;
    always @(posedge i_clk) if (i_rst) wr_line_cnt <= 0; else if (line_written) wr_line_cnt <= (wr_line_cnt == 479) ? 0 : wr_line_cnt + 1;

    always @(posedge i_clk) if (i_rst || stop_processing) rd_pixel_cnt <= 0; else if (rd_en) rd_pixel_cnt <= (rd_pixel_cnt == 639) ? 0 : rd_pixel_cnt + 1;
    always @(posedge i_clk) if (i_rst || stop_processing) rd_line_cnt <= 0; else if (line_read) rd_line_cnt <= rd_line_cnt + 1;

    // 4. Buffer Pointers & Enables
    always @(posedge i_clk) if (i_rst) wr_buf_ptr <= 0; else if (line_written) wr_buf_ptr <= wr_buf_ptr + 1;
    always @(posedge i_clk) if (i_rst || stop_processing) rd_buf_ptr <= 0; else if (line_read) rd_buf_ptr <= rd_buf_ptr + 1;

    always @(*) begin
        case(rd_buf_ptr)
            0: line_buf_rd_en_logic = 4'b0111;
            1: line_buf_rd_en_logic = 4'b1110;
            2: line_buf_rd_en_logic = 4'b1101;
            3: line_buf_rd_en_logic = 4'b1011;
            default: line_buf_rd_en_logic = 4'b0000;
        endcase
    end

    // 5. Output Logic
    always @(posedge i_clk) if(i_rst) o_pixel_data_valid <= 1'b0; else o_pixel_data_valid <= (state == STATE_PROCESSING);
    always @(posedge i_clk) if(i_rst) o_pixel_data_last <= 1'b0; else o_pixel_data_last <= stop_processing;
    always @(posedge i_clk) if(i_rst) o_intr <= 1'b0; else if (line_read) o_intr <= 1'b1; else o_intr <= 1'b0;

    // 6. Data Path
    line_window lw0(.i_clk(i_clk), .i_en(line_buf_rd_en[0]), .i_data(lb0_out), .o_win(lb0_win));
    line_window lw1(.i_clk(i_clk), .i_en(line_buf_rd_en[1]), .i_data(lb1_out), .o_win(lb1_win));
    line_window lw2(.i_clk(i_clk), .i_en(line_buf_rd_en[2]), .i_data(lb2_out), .o_win(lb2_win));
    line_window lw3(.i_clk(i_clk), .i_en(line_buf_rd_en[3]), .i_data(lb3_out), .o_win(lb3_win));

    always @(posedge i_clk) begin
        if (rd_en) begin
            case(rd_buf_ptr)
                0: o_pixel_data <= {lb2_win, lb1_win, lb0_win};
                1: o_pixel_data <= {lb3_win, lb2_win, lb1_win};
                2: o_pixel_data <= {lb0_win, lb3_win, lb2_win};
                3: o_pixel_data <= {lb1_win, lb0_win, lb3_win};
                default: o_pixel_data <= 72'b0;
            endcase
        end
    end

    // 7. Instantiations
    lineBuffer lB0(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel_data), .i_data_valid(line_buf_wr_en[0]), .o_data(lb0_out), .i_rd_data(line_buf_rd_en[0]));
    lineBuffer lB1(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel_data), .i_data_valid(line_buf_wr_en[1]), .o_data(lb1_out), .i_rd_data(line_buf_rd_en[1]));
    lineBuffer lB2(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel_data), .i_data_valid(line_buf_wr_en[2]), .o_data(lb2_out), .i_rd_data(line_buf_rd_en[2]));
    lineBuffer lB3(.i_clk(i_clk), .i_rst(i_rst), .i_data(i_pixel_data), .i_data_valid(line_buf_wr_en[3]), .o_data(lb3_out), .i_rd_data(line_buf_rd_en[3]));

endmodule