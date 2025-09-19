//`timescale 1ns / 1ps

//`define headerSize 1080
//`define imageSize 640*480

//module tb(

//    );


//    reg clk;
//    reg reset;
//    reg [7:0] imgData;
//    integer file,file1,i;
//    reg imgDataValid;
//    integer sentSize;
//    wire intr;
//    wire [7:0] outData;
//    wire outDataValid;
//    wire outDataLast; // NEW: Wire for the TLAST signal
//    integer receivedData=0;

//    initial
//    begin
//        clk = 1'b0;
//        forever
//        begin
//            #5 clk = ~clk;
//        end
//    end

//    initial
//    begin
//        reset = 0;
//        sentSize = 0;
//        imgDataValid = 0;
//        #100;
//        reset = 1;
//        #100;
//        file = $fopen("input_image.bmp","rb");
//        file1 = $fopen("gaussian_output.bmp","wb");
//        for(i=0;i<`headerSize;i=i+1)
//        begin
//            $fscanf(file,"%c",imgData);
//            $fwrite(file1,"%c",imgData);
//        end

//        for(i=0;i<`imageSize;i=i+1) // CHANGED
//        begin
//            @(posedge clk);
//            $fscanf(file,"%c",imgData);
//            imgDataValid <= 1'b1;
//        end
//        sentSize = 4*640;
//        @(posedge clk);
//        imgDataValid <= 1'b0;
//        while(sentSize < `imageSize)
//        begin
//            @(posedge intr);
//            for(i=0;i<640;i=i+1)
//            begin
//                @(posedge clk);
//                $fscanf(file,"%c",imgData);
//                imgDataValid <= 1'b1;   
//            end
//            @(posedge clk);
//            imgDataValid <= 1'b0;
//            sentSize = sentSize+640;
//        end
//        $display("? Finished sending real image data (%d bytes)", sentSize);

//        @(posedge clk);
//        imgDataValid <= 1'b0;
//        @(posedge intr);
//        for(i=0;i<640;i=i+1)
//        begin
//            @(posedge clk);
//            imgData <= 0;
//            imgDataValid <= 1'b1;   
//        end
//        @(posedge clk);
//        imgDataValid <= 1'b0;
//        @(posedge intr);
//        for(i=0;i<640;i=i+1)
//        begin
//            @(posedge clk);
//            imgData <= 0;
//            imgDataValid <= 1'b1;   
//        end
//        @(posedge clk);
//        imgDataValid <= 1'b0;
//        $fclose(file);
//    end

//    // This block now checks for TLAST
//    always @(posedge clk)
//    begin
//        if(outDataValid)
//        begin
//            $fwrite(file1,"%c",outData);
//            // $display("out[%0d] = %0d", receivedData, outData);
            
//            // NEW: Check TLAST signal
//            if (outDataLast) begin
//                $display("? TLAST received at pixel %0d", receivedData);
//                // The last pixel is index (imageSize - 1)
//                if (receivedData != `imageSize - 1) begin
//                    $display("? ERROR: TLAST received too early!");
//                end
//            end
            
//            receivedData = receivedData+1;
//        end 
        
//        if(receivedData % 50000 == 0 && receivedData > 0)
//            $display("Progress: %d pixels received", receivedData);

//        if(receivedData >= `imageSize)
//        begin
//            // NEW: Final check to ensure TLAST was asserted on the last pixel
//            if (!outDataLast) begin
//                $display("? ERROR: TLAST was NOT received on the last pixel!");
//            end
            
//            $display("? Done writing %d pixels", receivedData);
//            $fclose(file1);
//            $stop;
//        end
//    end

//    always @(posedge intr)
//        $display("? intr triggered at time %t, sentSize = %d", $time, sentSize);


//    imageProcessTop dut(
//        .axi_clk(clk),
//        .axi_reset_n(reset),
//        //slave interface
//        .i_data_valid(imgDataValid),
//        .i_data(imgData),
//        .o_data_ready(),
//        //master interface
//        .o_data_valid(outDataValid),
//        .o_data(outData),
//        .o_data_last(outDataLast), // NEW: Connect the TLAST output
//        .i_data_ready(1'b1),
//        //interrupt
//        .o_intr(intr)
//    );  

//endmodule


//`timescale 1ns / 1ps

//`define headerSize 1080
//`define imageSize (640*480)
//`define totalSize (`imageSize * 2) // Total pixels for two frames

//module tb();

//    reg clk;
//    reg reset;
//    reg [7:0] imgData;
//    integer file, file1, i;
//    reg imgDataValid;
//    wire intr;
//    wire [7:0] outData;
//    wire outDataValid;
//    wire outDataLast;
//    integer receivedData = 0;

//    // DUT instantiation
//    imageProcessTop dut(
//        .axi_clk(clk),
//        .axi_reset_n(reset),
//        .i_data_valid(imgDataValid),
//        .i_data(imgData),
//        .o_data_ready(),
//        .o_data_valid(outDataValid),
//        .o_data(outData),
//        .o_data_last(outDataLast),
//        .i_data_ready(1'b1),
//        .o_intr(intr)
//    );

//    // Clock generation
//    initial begin
//        clk = 1'b0;
//        forever #5 clk = ~clk;
//    end

//    // Task to send one full frame
//    task send_frame;
//        integer sentSize;
//    begin
//        // Rewind the file to the start of the pixel data
//        $fseek(file, `headerSize, 0);
//        sentSize = 0;
//        imgDataValid = 0;
//        $display("? [%t] Starting to send frame.", $time);

//        // This loop structure mimics your original logic
//        for(i=0; i < (`imageSize); i=i+1) begin
//            @(posedge clk);
//            $fscanf(file, "%c", imgData);
//            imgDataValid <= 1'b1;
//        end
        
//        @(posedge clk);
//        imgDataValid <= 1'b0;
        
//        // Wait for the final interrupt of the frame to ensure it's processed
//        // This part of your original logic might need adjustment depending on how
//        // the interrupt behaves at the very end of a frame.
//        // For simplicity, we'll just wait a bit to ensure the pipeline is clear.
//        #1000; 
//        $display("? [%t] Finished sending frame.", $time);
//    end
//    endtask

//    // Main stimulus block
//    initial begin
//        // 1. Initial Reset and File Setup
//        reset = 0; // Assert reset (active low)
//        imgDataValid = 0;
//        #100;
//        reset = 1; // De-assert reset
//        #100;

//        file = $fopen("input_image.bmp", "rb");
//        file1 = $fopen("gaussian_output_2frames.bmp", "wb");

//        // Copy header to the new file
//        for(i=0; i < `headerSize; i=i+1) begin
//            $fscanf(file, "%c", imgData);
//            $fwrite(file1, "%c", imgData);
//        end

//        // 2. Send the first frame
//        send_frame();

//        // 3. Reset DUT and send the second frame
//        $display("? Resetting DUT for the second frame.");
////        reset = 0; // Assert reset
////        #100;
////        reset = 1; // De-assert reset
////        #100;
        
//        send_frame();

//        // 4. Clean up
//        $display("? Finished sending all data.");
//        $fclose(file);
//    end

//    // Receiver and checker block
//    always @(posedge clk) begin
//        if (outDataValid) begin
//            $fwrite(file1, "%c", outData);
            
//            // Check for TLAST at the end of EACH frame
//            if (outDataLast) begin
//                if ((receivedData % `imageSize) == (`imageSize - 1)) begin
//                    $display("? TLAST received correctly at the end of frame (pixel %0d)", receivedData);
//                end else begin
//                    $display("? ERROR: TLAST received at unexpected pixel %0d!", receivedData);
//                end
//            end
            
//            receivedData = receivedData + 1;
//        end 

//        // Stop simulation after receiving two full frames
//        if (receivedData >= `totalSize) begin
//            $display("? Done writing %d pixels for two frames.", receivedData);
//            $fclose(file1);
//            $stop;
//        end
//    end

//endmodule




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
