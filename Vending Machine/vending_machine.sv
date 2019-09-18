`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Richard Liu
// 
// Create Date: 09/16/2019 05:45:18 PM
// Design Name: 
// Module Name: vending_machine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     Vending Machine that takes either a quarter or a dollar input and has 3 choices
//                  Choices are to spend $0.50, $1.00, $1.50 or to just return money. 
//                  Change will be dispensed
//                  Amount taken caps at MAX_AMT which defaults at $4.00
//                      -- after MAX_AMT, machine will still take money but will not increment
//                 
// Dependencies:    i_buttons are passed through a debouncer
//                  Assume buttons will not be pressed while machine is dispensing
//                  We expect only one action at a time (for example, a quarter and a dollar will not be input
//                  at the same time), therefore one latch_clr will be used for all latches
//
// Notes:           Rising edge detector to latch buttons and input money I would want to use in
//                  a separate module, but for ease of access, I put it all in one file
//                  
//                  If button is pressed when no money is given, ignore
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vending_machine #(   parameter   NUM_CHOICES_SIZE = 3,
                                        MAX_AMT_SIZE = 5)
    (
        input  wire                             i_clk,
                                                i_rst_n,
                                                i_quarter,
                                                i_dollar,
        input  wire     [NUM_CHOICES_SIZE-1:0]  i_buttons,
        output logic    [4:0]                   o_change, // number of quarters to return
        output logic    [NUM_CHOICES_SIZE-1:0]  o_item,
        output logic                            o_msg_en  // if not enough money is given. Doesn't do anything of 
                                                          // significance in simulation besides flagging
                                                          // can be used to display error msg
    );
    
    localparam  QUARTER = 1,
                DOLLAR = 4,
                MAX_AMT = 16;     // 4 quarters in a dollar
    
    // button/pin mapping and prices of vending machine items
    localparam  REFUND = 4'b0001, 
                ITEM_1 = 4'b0010,
                ITEM_2 = 4'b0100,
                ITEM_3 = 4'b1000,
                ITEM_1_PRICE = 2, // $0.50
                ITEM_2_PRICE = 4, // $1.00
                ITEM_3_PRICE = 6; // $1.50
                
    localparam STATE_SIZE = 4;
    typedef enum logic [STATE_SIZE-1:0] { IDLE, RCV_MONEY, BUTTON_PRESSED, NOT_ENOUGH_MONEY, DISPENSE
    } state_t;
    state_t current_state, next_state;
    
    logic                           count_clr,
                                    quarter_q,      // pass through FF for rising edge detector
                                    dollar_q,       // pass through FF for rising edge detector
                                    quarter_en,
                                    dollar_en,
                                    quarter_latch,  // latch rising edge
                                    dollar_latch,   // latch rising edge
                                    latch_clr;      // one latch clr for all, assuming that quarter and dollar
                                                    // and button will not happen in the same clock cycle
    
    logic [NUM_CHOICES_SIZE-1:0]    button_en,  
                                    button_q,       // pass through FF for rising edge detector
                                    button_latch;   // latch rising edge
                                    
    logic [MAX_AMT_SIZE-1:0]        amt_counted,
                                    amt_spent;

    logic    [NUM_CHOICES_SIZE-1:0]  item_temp;     // output item
    
    logic                           dispense_en;
    
    // 1 clock delay for quarter, dollar, and button inputs 
    // Latch after rising edge detected
    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) begin
            quarter_q       <= '0;
            dollar_q        <= '0;
            button_q        <= '0;
            
            quarter_latch   <= '0;
            dollar_latch    <= '0;
            button_latch    <= '0;
        end
        else if(latch_clr) begin
            quarter_latch   <= '0;
            dollar_latch    <= '0;
            button_latch    <= '0;
        end
        else begin
            quarter_q       <= i_quarter;
            dollar_q        <= i_dollar;
            button_q        <= i_buttons;
                        
            quarter_latch   <= i_quarter & ~quarter_q;
            dollar_latch    <= i_dollar & ~dollar_q;
            button_latch    <= i_buttons & ~button_q;
        end
    end
    
    // state update logic
    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n) 
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // money counting logic. Enable lines controlled by state logic
    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n || count_clr)
            amt_counted <= '0;
        else begin
            if(amt_counted < MAX_AMT) begin
                if(quarter_en)
                    amt_counted <= amt_counted + QUARTER;
                else if(dollar_en)
                    amt_counted <= amt_counted + DOLLAR;
                else
                    amt_counted <= amt_counted; // explicitly stated latch
            end
        end
    end
    
    // dispensing logic. Enable lines controlled by state logic
    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if(!i_rst_n || !dispense_en) begin
            o_change    <= '0;
            o_item      <= '0;
        end
        else begin
            if(dispense_en) begin
                o_change    <= amt_counted - amt_spent;
                o_item      <= item_temp;   // if refund button with no item is pressed, just ignore in xparam file
                                            // depending on how this module is used, might be useful to know refund was issued
            end
        end
    end

    // state and output logic
    always_comb begin
        // default values
        next_state      = current_state;
        latch_clr       = '0;
        item_temp       = '0;
        count_clr       = '0;
        quarter_en      = '0;
        dollar_en       = '0;
        button_en       = '0;
        amt_spent       = '0;
        dispense_en     = '0;
        o_msg_en        = '0;
        
        case(current_state)
            IDLE:   begin   count_clr = '1; 
                            if(quarter_latch) begin
                                                        latch_clr = '1;
                                                        quarter_en = '1;
                                                        next_state = RCV_MONEY;
                            end
                            else if(dollar_latch) begin
                                                        latch_clr = '1;
                                                        dollar_en = '1;
                                                        next_state = RCV_MONEY;
                            end                      
                    end
            RCV_MONEY: begin
                            if(quarter_latch) begin
                                                        latch_clr = '1;
                                                        quarter_en = '1;
                                                        next_state = RCV_MONEY;
                            end
                            else if(dollar_latch) begin
                                                        latch_clr = '1;
                                                        dollar_en = '1;
                                                        next_state = RCV_MONEY;
                            end          
                            else if(button_latch) begin
                                                        latch_clr = '1;
                                                        item_temp = button_latch;
                                                        next_state = BUTTON_PRESSED;
                            end                                
                    end
            BUTTON_PRESSED: begin
                            if(item_temp == ITEM_1 && amt_counted >= ITEM_1_PRICE) begin
                                                        amt_spent = ITEM_1_PRICE;
                                                        next_state = DISPENSE;                           
                            end
                            else if(item_temp == ITEM_2 && amt_counted >= ITEM_2_PRICE) begin
                                                        amt_spent = ITEM_2_PRICE;
                                                        next_state = DISPENSE;                           
                            end
                            else if(item_temp == ITEM_3 && amt_counted >= ITEM_3_PRICE) begin
                                                        amt_spent = ITEM_3_PRICE;
                                                        next_state = DISPENSE;                           
                            end
                            if(item_temp == REFUND) begin
                                                        amt_spent = '0;
                                                        next_state = DISPENSE;
                            end
                            else                        next_state = NOT_ENOUGH_MONEY;
            end
            DISPENSE:       begin
                                                        dispense_en = '1;
                                                        next_state = IDLE;
            end
            NOT_ENOUGH_MONEY: begin
                                                        o_msg_en = '1;
                                                        next_state = RCV_MONEY;
            end
        endcase
    end
    
endmodule
