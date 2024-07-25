module UTMI_TX_FSM (
  input               Clk,Rst,
  input               TX_Valid,
  input               sync_done,
  input               TX_hold_empty,
  input               EOP_done,
  output  reg         TX_Ready,
  output  reg         sync_enable,
  output  reg         load_data_enable,
  output  reg [1:0]   bit_stuff_en,
  output  reg         edge_cnt_enable,
  output  reg         EOP_enable 
  );
  
  reg [2:0] current_state,next_state;

  parameter TX_Wait = 3'b000,
            SEND_sync = 3'b001,
            TX_data_load = 3'b010,
            TX_data_wait = 3'b011,
            SEND_EOP = 3'b100;
            
  parameter NO_OP = 2'b00,
            STUFF_OFF = 2'b01,
            STUFF_ON = 2'b10;
            
  always @(posedge Clk or negedge Rst)
  begin
    if (!Rst) 
      current_state <= TX_Wait;
    else 
      current_state <= next_state;
    end
    
  always @(*)
  begin
    case(current_state)
      
      TX_Wait:
      begin
        if ( !TX_Valid )
          begin
          next_state = TX_Wait;
          end
        else 
          begin
          next_state = SEND_sync;
        end
      end
      
      SEND_sync:
      begin
        if(sync_done)
          next_state = TX_data_load;
        else
          next_state = SEND_sync;
      end
      
      TX_data_load:
      begin
        if( TX_Valid && !TX_hold_empty )
          next_state = TX_data_wait;
        else if ( !TX_Valid && TX_hold_empty)
          next_state = SEND_EOP;
        else
          next_state = TX_data_load;
      end
      
      TX_data_wait:
      begin
        if (TX_hold_empty && TX_Valid)
          next_state = TX_data_load;
        else if(TX_hold_empty && !TX_Valid)
          next_state = SEND_EOP;
        else
          next_state = TX_data_wait; 
        end
        
      SEND_EOP:
      begin
        if(EOP_done)
          next_state = TX_Wait;
        else
          next_state = SEND_EOP;
      end
      
      default:
      begin
        next_state = TX_Wait;
      end
        
    endcase
  end
  
  always @(*)
  begin
    TX_Ready = 1'b0;
    sync_enable = 1'b0;
    load_data_enable = 1'b0;
    bit_stuff_en = NO_OP;
    edge_cnt_enable = 1'b0;
    EOP_enable = 1'b0;
    
    case ( current_state )
      
      TX_Wait:
      begin
        TX_Ready = 1'b0;
        sync_enable = 1'b0;
        load_data_enable = 1'b0;
        bit_stuff_en = NO_OP;
        edge_cnt_enable = 1'b0;
        EOP_enable = 1'b0;
      end
      
      SEND_sync:
      begin
        TX_Ready = 1'b0;
        sync_enable = 1'b1;
        load_data_enable = 1'b0;
        edge_cnt_enable = 1'b1;
        bit_stuff_en = STUFF_OFF;
        EOP_enable = 1'b0;
        
      end
      
      TX_data_load:
      begin
        TX_Ready = 1'b1;
        sync_enable = 1'b0;
        load_data_enable = 1'b1;
        edge_cnt_enable = 1'b1;
        bit_stuff_en = STUFF_ON;
        EOP_enable = 1'b0;
      end
      
      TX_data_wait:
      begin
        TX_Ready = 1'b0;
        sync_enable = 1'b0;
        load_data_enable = 1'b0;
        edge_cnt_enable = 1'b1;
        bit_stuff_en = STUFF_ON;
        EOP_enable = 1'b0;
      end
      
      SEND_EOP:
      begin
        TX_Ready = 1'b0;
        sync_enable = 1'b0;
        load_data_enable = 1'b0;
        edge_cnt_enable = 1'b1;
        bit_stuff_en = STUFF_ON;
        EOP_enable = 1'b1;
      end
      
      default:
      begin
        TX_Ready = 1'b0;
        sync_enable = 1'b0;
        load_data_enable = 1'b0;
        bit_stuff_en = NO_OP;
        edge_cnt_enable = 1'b0;
        EOP_enable = 1'b0;
      end
      
 endcase   
end

endmodule