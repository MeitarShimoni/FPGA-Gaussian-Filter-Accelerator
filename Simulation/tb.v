
`timescale 1ns / 1ps

`define headerSize 1080
`define imageSize (640*480)
`define totalSize (`imageSize * 4) // Total pixels for two frames

module tb();

    reg clk;
    reg reset;
    reg [7:0] imgData;
    
    // Handles for input file and the CURRENT output file
    integer input_file;
    integer output_file_handle; 
    
    integer i;
    reg imgDataValid;
    wire intr;
    wire [7:0] outData;
    wire outDataValid;
    wire outDataLast;
    integer receivedData = 0;
    
    // Event to synchronize between sender and receiver
    event frame1_received;

    // DUT instantiation
    imageProcessTop dut(
        .axi_clk(clk),
        .axi_reset_n(reset),

        .i_data_valid(imgDataValid),
        .i_data(imgData),
        .o_data_ready(),
        .o_data_valid(outDataValid),
        .o_data(outData),
        .o_data_last(outDataLast),
        .i_data_ready(1'b1),
        .o_intr(intr)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Task to send one full frame's pixel data
    task send_frame_data;
    begin
        // Rewind the input file to the start of the pixel data
        $fseek(input_file, `headerSize, 0);
        
        for(i=0; i < `imageSize; i=i+1) begin
            @(posedge clk);
            $fscanf(input_file, "%c", imgData);
            imgDataValid <= 1'b1;
        end
        
        @(posedge clk);
        imgDataValid <= 1'b0;
    end
    endtask

    // Main stimulus block that controls the flow
    initial begin
        // 1. Initial Reset and File Setup
        reset = 0; // Assert reset (active low)
        imgDataValid = 0;
        #100;
        reset = 1; // De-assert reset
        #100;

        input_file = $fopen("input_image.bmp", "rb");
        
        // --- Setup for Frame 1 ---
        $display("? [%t] Setting up for Frame 1.", $time);
        output_file_handle = $fopen("gaussian_output_frame1.bmp", "wb");

        // Copy header to the first output file
        for(i=0; i < `headerSize; i=i+1) begin
            $fseek(input_file, i, 0);
            $fscanf(input_file, "%c", imgData);
            $fwrite(output_file_handle, "%c", imgData);
        end

        // 2. Send the first frame's data
        send_frame_data();
        $display("? [%t] Finished sending data for Frame 1.", $time);

        // 3. Wait for the receiver to confirm it got the whole frame
//        @(outDataLast);
       ////////////////////////////////////////////////////////////////////////////////////////////////
//        reset = 0;
//        #100;
//        reset = 1; // De-assert reset
//        #100; 
        // --- Setup for Frame 2 ---
        $display("? [%t] Setting up for Frame 2.", $time);
        $fclose(output_file_handle); // Close the first file
        output_file_handle = $fopen("gaussian_output_frame2.bmp", "wb"); // Open the second

        // Copy header to the second output file
        for(i=0; i < `headerSize; i=i+1) begin
            $fseek(input_file, i, 0);
            $fscanf(input_file, "%c", imgData);
            $fwrite(output_file_handle, "%c", imgData);
        end
        
        // 4. Send the second frame's data
        send_frame_data();
        $display("? [%t] Finished sending data for Frame 2.", $time);


////////////////////////////////////////////////////////////////////////////////////// 3 
//        @(outDataLast);
//        reset = 0;
//        #100;
//        reset = 1; // De-assert reset
//        #100; 
       $display("? [%t] Setting up for Frame 3.", $time);
        output_file_handle = $fopen("gaussian_output_frame3.bmp", "wb");

        // Copy header to the first output file
        for(i=0; i < `headerSize; i=i+1) begin
            $fseek(input_file, i, 0);
            $fscanf(input_file, "%c", imgData);
            $fwrite(output_file_handle, "%c", imgData);
        end

        // 2. Send the first frame's data
        send_frame_data();
        $display("? [%t] Finished sending data for Frame 3.", $time);

        // 3. Wait for the receiver to confirm it got the whole frame
//        @(outDataLast);






///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////// 3 
//        @(outDataLast);
//        reset = 0;
//        #100;
//        reset = 1; // De-assert reset
//        #100; 
       $display("? [%t] Setting up for Frame 4.", $time);
        output_file_handle = $fopen("gaussian_output_frame4.bmp", "wb");

        // Copy header to the first output file
        for(i=0; i < `headerSize; i=i+1) begin
            $fseek(input_file, i, 0);
            $fscanf(input_file, "%c", imgData);
            $fwrite(output_file_handle, "%c", imgData);
        end

        // 2. Send the first frame's data
        send_frame_data();
        $display("? [%t] Finished sending data for Frame 3.", $time);

        // 3. Wait for the receiver to confirm it got the whole frame
//        @(outDataLast);






///////////////////////////////////////////////////////////////////////////////////



        // 5. Clean up
        $fclose(input_file);
    end

    // Receiver and file writer block
    always @(posedge clk) begin
        if (outDataValid) begin
            // Write to whichever file is currently open
            $fwrite(output_file_handle, "%c", outData);
            
            // Check for TLAST signal
            if (outDataLast) begin
                $display("? TLAST received at pixel %0d", receivedData);
                // If this is the end of the first frame, trigger the event
                if (receivedData == `imageSize - 1) begin
                    ->frame1_received; 
                end
            end
            
            receivedData = receivedData + 1;
        end 

        // Stop simulation after receiving two full frames
        if (receivedData >= `totalSize) begin
            $display("? Done writing %d pixels for two frames.", receivedData);
            $fclose(output_file_handle); // Close the final file
            $stop;
        end
    end

endmodule
