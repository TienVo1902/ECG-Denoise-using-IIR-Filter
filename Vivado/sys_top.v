`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2025 09:51:19 AM
// Design Name: 
// Module Name: sys_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module IIR_Top (
    input wire clk_in,  
    input wire reset    
);

    // Clock Wizard
    wire clk_out1_wire; 
    wire locked_wire;   

    // BRAM
    wire [11:0] addr_wire;   
    wire signed [23:0] douta_wire;  
    wire        ena_wire;    
    wire [0:0]  wea_wire;     

    reg  [11:0] addr_reg;    
    wire        system_reset; 

    // IIR Filter
    wire signed [39:0] filtered_ecg_wire; 
    wire               iir_ce_out_wire;    

    assign system_reset = reset || !locked_wire;
    assign ena_wire = locked_wire;
    assign wea_wire = 1'b0;
    assign addr_wire = addr_reg;

    always @(posedge clk_out1_wire or posedge system_reset) begin
        if (system_reset) begin
            addr_reg <= 12'd0; 
        end 
        else if (ena_wire) begin 
            if (addr_reg == 12'd2499) begin 
                addr_reg <= 12'd0; 
            end 
            else begin
                addr_reg <= addr_reg + 1; 
            end
        end
    end


    // Clocking Wizard 
    clk_wiz_0 clk_wiz_inst (
        .clk_out1(clk_out1_wire), 
        .reset(reset),            
        .locked(locked_wire),     
        .clk_in1(clk_in)          
    );

    // (Block Memory Generator (BRAM)
    blk_mem_gen_0 bram_inst (
        .clka(clk_out1_wire),   
        .ena(ena_wire),         
        .wea(wea_wire),         
        .addra(addr_wire),      
        .dina(24'd0),           
        .douta(douta_wire)      
    );

    // IIR Filter 
    IIR_Filter iir_filter_inst (
        .clk(clk_out1_wire),        
        .reset(system_reset),       
        .clk_enable(ena_wire),      
        .In1(douta_wire),           
        .ce_out(iir_ce_out_wire),   
        .Out1(filtered_ecg_wire)    
    );

    // Integrated Logic Analyzer (ILA)
    ila_0 ila_inst (
        .clk(clk_out1_wire),    // input wire clk
        .probe0(addr_wire),         // input wire [11:0]  probe0 
        .probe1(douta_wire),        // input wire [23:0]  probe1 
        .probe2(filtered_ecg_wire)  // // input wire [39:0]  probe2 
    );

endmodule
