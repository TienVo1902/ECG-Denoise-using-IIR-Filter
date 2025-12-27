`timescale 1 ns / 1 ps

// --------------------------------------------------------------------
// Module:         IIR_Filter_tb
// Description:    Testbench for IIR_Filter.
//               - Reads samples from an absolute path.
//               - Writes filtered output to an absolute path.
// --------------------------------------------------------------------
module IIR_Filter_tb;

    localparam CLK_PERIOD      = 100; 
    
    localparam IN_FILE_NAME  = "D:/Advanced_Topic/IIR_Filter_1/Matlab/ecg_input.txt";
    
    localparam OUT_FILE_NAME = "D:/Advanced_Topic/IIR_Filter_1/Matlab/ecg_output.txt";

    reg                      clk;
    reg                      reset;
    reg                      clk_enable;
    reg signed [23:0]        In1;

    wire                     ce_out;
    wire signed [39:0]       Out1;

    integer                  in_file_handle;
    integer                  out_file_handle;
    integer                  scan_status;
    reg signed [31:0]        temp_input_val;
    integer                  sample_count;

    // --- DUT Instantiation ---
    IIR_Filter uut (
        .clk(clk),
        .reset(reset),
        .clk_enable(clk_enable),
        .In1(In1),
        .ce_out(ce_out),
        .Out1(Out1)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Test Sequence ---
    initial begin
        // 1. Open files
        $display("Simulation: Opening files...");
        in_file_handle = $fopen(IN_FILE_NAME, "r");
        if (in_file_handle == 0) begin
            $display("ERROR: Could not open input file: %s", IN_FILE_NAME);
            $finish;
        end

        out_file_handle = $fopen(OUT_FILE_NAME, "w");
        if (out_file_handle == 0) begin
            $display("ERROR: Could not create output file: %s", OUT_FILE_NAME);
            $finish;
        end

        // 2. Initialize & Reset
        $display("Simulation: Initializing and asserting reset...");
        clk_enable   = 0;
        In1          = 0;
        sample_count = 0;
        reset        = 1;
        
        @(posedge clk);
        @(posedge clk);
        reset        = 0;
        clk_enable   = 1;
        $display("Simulation: Reset de-asserted. Starting data application...");
        @(posedge clk);

        // 3. Read data and write results
        while (!$feof(in_file_handle)) begin
            scan_status = $fscanf(in_file_handle, "%d\n", temp_input_val);

            if (scan_status == 1) begin
                @(posedge clk);
                In1 = temp_input_val;
                $fdisplay(out_file_handle, "%d", Out1);
                sample_count = sample_count + 1;
            end
        end

        // 4. Flush pipeline and finish
        $display("Simulation: End of input file. Flushing pipeline...");
        repeat (20) begin
             @(posedge clk);
             $fdisplay(out_file_handle, "%d", Out1);
        end

        $display("Simulation: Finished. Processed %d samples.", sample_count);
        $display("Output written to: %s", OUT_FILE_NAME);
        
        // 5. Clean up
        $fclose(in_file_handle);
        $fclose(out_file_handle);
        $finish;
    end

endmodule