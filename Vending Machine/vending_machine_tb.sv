`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Riichard Liu
// 
// Create Date: 09/16/2019 11:57:54 PM
// Design Name: 
// Module Name: vending_machine_tb
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


module vending_machine_tb;
    // Inputs
	logic i_clk;
	logic i_rst_n;
	logic i_quarter;
	logic i_dollar;
	logic [3:0] i_buttons;

	// Outputs
	logic [3:0] o_item;
	logic [4:0] o_amt;
	logic [4:0] o_change;
    logic       o_msg_en;

	parameter	    REFUND  = 4'b0001, 
	                ITEM_1	= 4'b0010,
					ITEM_2 	= 4'b0100,
					ITEM_3 	= 4'b1000;
					
	// Instantiation
	vending_machine u1(.*);
	
	initial begin 
		forever #5 i_clk = ~i_clk;
	end
	
	initial begin
		// Initialize Inputs
		i_clk = '0;
		i_rst_n = '1;
		i_quarter = '0;
		i_dollar = '0;
		i_buttons = '0;

		#5    i_rst_n = '0;
		#10   i_rst_n = '1;

        // testing item dispense functionality
        // item 1 and no change
		#10    i_quarter = 1;
		#10    i_quarter = 0;
		#10    i_quarter = 1;
        #10    i_quarter = 0;
		#10    i_buttons = ITEM_1;
		#10    i_buttons = 0;
		#50

        // testing change functionality
        // item 2 and change
		#10    i_quarter = 1;
		#10    i_quarter = 0;
		#10    i_quarter = 1;
        #10    i_quarter = 0;
		#10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_quarter = 1;
        #10    i_quarter = 0;
		#10    i_buttons = ITEM_2;
		#10    i_buttons = 0;
		#50
		
		// testing max amt caps
		// should get change and item 3
		#10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_dollar = 1;
        #10    i_dollar = 0;        
        #10    i_buttons = ITEM_3;
        #10    i_buttons = 0;
        #50
        
        // testing refund
        #10    i_quarter = 1;
        #10    i_quarter = 0;
        #10    i_quarter = 1;
        #10    i_quarter = 0;
        #10    i_dollar = 1;
        #10    i_dollar = 0;
        #10    i_quarter = 1;
        #10    i_quarter = 0;
        #10    i_buttons = REFUND;
        #10    i_buttons = 0;
        #50
        
         // testing not enough money
        #10    i_quarter = 1;
        #10    i_quarter = 0;
        #10    i_quarter = 1;
        #10    i_quarter = 0;
        #10    i_buttons = ITEM_2;
        #10    i_buttons = 0;    
        #50
		
//		#30
//		dispense_b = 0;
//		#40
//		dollar_in = 1;
//		#10
//		dollar_in = 0;
//		dispense_b = ITEM_2;
//		#10
//		dispense_b = 0;
//		#30
//		dollar_in = 1;
//		#30
//		dollar_in = 0;
//		dispense_b = ITEM_3;
//		#10
//		dispense_b = 0;
//		#30
//		dispense_b = 0;
//		dollar_in = 1;
//		#100
//		dollar_in = 0;
//		dispense_b = ITEM_3;
//		#30
		
		$finish;
	end
endmodule
