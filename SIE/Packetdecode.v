module packetdecode (
  input wire CLK,RST,
  input wire in_transfer,
  input wire Data_toggle,
  input wire info_Ready,
  input wire maxpacket_length,
  input wire Rx_Valid,Rx_active,Rx_error,
  input wire [7:0] UTMI_Rx_Data,
  input wire eop_detection,
  input wire  enable_pid,
  input wire HS_transfer,
  input wire data_recieved,
  output reg [7:0] Rx_Data_HC,
  output reg [5:0] HC_Data_count,
  output reg write_enable,
  output reg HS_Ready,Error_Ready,
  output reg crc_error,Time_out,
  output reg ack_in,
  output reg nak_o,stall_o,
  output reg data_toggle_error,
  output reg HC_Rx_error,
  output reg HS_corrupted,
  output reg data_corrupted
  );
  
localparam PID_DATA0  = 8'hC3;
localparam PID_DATA1  = 8'h4B;

localparam PID_ACK    = 8'hD2;
localparam PID_NAK    = 8'h5A;
localparam PID_STALL  = 8'h1E;
//states
localparam STATE_IDLE = 4'b0000;
localparam STATE_RX_WAIT = 4'b0001;
localparam STATE_RX_PID = 4'b0010;
localparam STATE_RX_DATA = 4'b0011;
localparam STATE_CRC1 = 4'b0100;
localparam STATE_CRC2 = 4'b0101;
localparam STATE_OVERFLOW = 4'b0110;
localparam STATE_CK_ERROR = 4'b0111;
localparam STATE_EOP_DET_WAIT = 4'b1000;
localparam STATE_RX_ERROR = 4'b1001;
//signals
reg [3:0] current_state,next_state;
reg PID_cks_Err;
reg [5:0] Rx_valid_count;
reg [15:0] edge_count;
reg [15:0] CRC_data;
wire edge_count_done; 
wire [15:0] crc16_out;
reg Enable;
reg crc_Enable;
reg crc_Done;
reg [7:0] Data_in;
reg  edge_count_0;
reg [7:0] PID_reg;
reg in_transfer_reg;
reg HS_transfer_reg;

always@(posedge CLK or negedge RST)
begin
  if(!RST)
    begin
      HS_transfer_reg <= 'b0;
      in_transfer_reg <= 'b0;
    end
  else if(enable_pid)
    begin
      HS_transfer_reg <= HS_transfer;
      in_transfer_reg <= in_transfer; 
    end
  end

// state transtion 
always@(posedge CLK or negedge RST)
  begin
    if(!RST)
      begin
        current_state <= STATE_IDLE;
      end
    else
      begin
        current_state <= next_state;
      end
    end
//next state logic
  always@(*) 
  begin
    case(current_state)
      STATE_IDLE : begin
                    if(in_transfer | HS_transfer)
                      next_state = STATE_RX_WAIT;
                    else
                      next_state = STATE_IDLE;
                    end
      STATE_RX_WAIT : begin
                       if(Rx_error)
                         next_state = STATE_EOP_DET_WAIT;
                       else if(Rx_Valid )
                         next_state = STATE_RX_PID;
                       else if(Time_out && !info_Ready) //wait long time for data to be ready
                         next_state = STATE_IDLE;
                       else 
                         next_state = STATE_RX_WAIT;
                       end
                  
      STATE_RX_PID : begin
                      if((((Data_in == PID_ACK) || (Data_in == PID_NAK) || (Data_in == PID_STALL)) && !info_Ready))
                        next_state = STATE_IDLE;
                      else if((((Data_in == PID_DATA1) && !Data_toggle) || ((Data_in == PID_DATA0 )&& Data_toggle))|| PID_cks_Err)
                         next_state = STATE_EOP_DET_WAIT;
                      else if((Data_in == PID_DATA1) && !maxpacket_length )
                         next_state = STATE_CRC1;
                      else if(((Data_in == PID_DATA1) && Data_toggle) || ((Data_in == PID_DATA0 )&& !Data_toggle))
                         next_state = STATE_RX_DATA;
                      else
                         next_state = STATE_RX_PID;
                      end
      STATE_RX_DATA : begin
                        if(Rx_valid_count == 6'b100001)
                          next_state = STATE_CRC1; 
                       else if(!Rx_active && !Rx_error)
                          next_state = STATE_CK_ERROR;
                       else if(!Rx_active && Rx_error)
                          next_state = STATE_EOP_DET_WAIT; 
                        else 
                          next_state = STATE_RX_DATA;
                      end
      STATE_CRC1 : begin
                    if((Rx_valid_count == 6'b100010) || Rx_Valid)
                      begin
                        next_state = STATE_CRC2;
                      end
                    else if(!Rx_active && !Rx_error)
                        next_state = STATE_CK_ERROR;
                     else if(!Rx_active && Rx_error)
                       begin
                        next_state = STATE_EOP_DET_WAIT;
                      end
                     else
                       begin
                         next_state = STATE_CRC1;
                       end
                     end
      
      STATE_CRC2 : begin 
                     if(!Rx_active && !Rx_error)
                       next_state =  STATE_CK_ERROR;
                     else if(!Rx_active && Rx_error)
                       next_state = STATE_EOP_DET_WAIT;
                     else if(Rx_valid_count > 6'b100010 )
                       next_state = STATE_OVERFLOW;
                     else
                       next_state = STATE_CRC2;
                     end
        
      STATE_OVERFLOW : begin
                     if(!Rx_active && Rx_error)
                       next_state = STATE_EOP_DET_WAIT; 
                     else if(!Rx_active && !Rx_error) 
                       next_state = STATE_CK_ERROR;
                     else 
                       next_state = STATE_OVERFLOW;
                    end
    
     STATE_CK_ERROR : begin
                        if(Rx_error)
                        next_state = STATE_EOP_DET_WAIT;
                       else if(!info_Ready)
                        next_state = STATE_IDLE;
                      else
                        next_state = STATE_CK_ERROR;
                      end
    STATE_EOP_DET_WAIT : begin
                         if(eop_detection)
                           next_state = STATE_RX_ERROR;
                         else 
                           next_state = STATE_EOP_DET_WAIT;
                       end  
     STATE_RX_ERROR : begin
                   if(!info_Ready)
                    next_state = STATE_IDLE;
                   else 
                    next_state = STATE_RX_ERROR; 
                  end
                                                     
                            
       default   : begin
			               next_state = STATE_IDLE ; 
                    end
                  endcase
                end	
                               
                   
 // output logic
   always@(*)
   begin
     Rx_Data_HC = 8'b0;
     HS_Ready = 1'b0;
     Error_Ready = 1'b0;
     crc_error = 1'b0; 
     Time_out = 1'b0;
     nak_o = 1'b0;
     stall_o = 1'b0;
     HC_Data_count = 6'b0;
     Enable = 1'b0;
     data_toggle_error = 1'b0;
     crc_Done = 1'b0;
     HC_Rx_error = 1'b0;
     ack_in = 1'b0;
edge_count_0 = 1'b0;
     HS_corrupted = 1'b0;
     data_corrupted = 'b0;
     case(current_state)
       STATE_IDLE : begin
                     edge_count_0= 1'b1;
                      crc_Done = 1'b1;
                    end
             
       STATE_RX_WAIT : begin
                        if(edge_count_done)
                          begin
                            Time_out = 1'b1;
                            Error_Ready =1'b1;
                          end
                        else
                          begin 
                            Time_out = 1'b0;
                          end
                        end
       STATE_RX_PID : begin
                       if(Data_in == PID_NAK)
                         begin
                           nak_o = 1'b1;
                           HS_Ready=1'b1; 
                         end
                       else if(Data_in == PID_STALL) 
                         begin
                           stall_o = 1'b1; 
                           HS_Ready=1'b1;
                         end  
                       else if(Data_in == PID_ACK)
                         begin
                           stall_o = 1'b0;
                           nak_o = 1'b0;
                           HS_Ready=1'b1;
                         end
                       else
                         begin
                           nak_o = 1'b0;
                           stall_o = 1'b0;
                         end
                        end
       STATE_RX_DATA : begin
                         Rx_Data_HC = Data_in;
                         Enable = 1'b1; 
                        
                       end
       STATE_CRC1 : begin
                      Enable = 1'b1;
                      Error_Ready = 1'b0; 
                    end
                    
       STATE_CRC2 : begin
                      Enable = 1'b1;
                      if(((crc16_out == CRC_data) && !Rx_active) || (Rx_valid_count == 6'b000010))
                        ack_in = 1'b1;
                      else
                        ack_in = 1'b0;  
                    end
        
       STATE_OVERFLOW : begin
                       Enable = 1'b1;
                       end
      STATE_CK_ERROR : begin
                         Enable = 1'b1;
                        if(Rx_error)
                             begin
                              crc_error = 1'b0 ;
                              Error_Ready = 1'b0;
                             end 
                       else if(((crc16_out != CRC_data) && (Rx_valid_count == 6'b100010)) && !Rx_error)
                            begin
                              crc_error = 1'b1 ;
                              Error_Ready = 1'b1;
                            end
                          else if((Rx_valid_count > 6'b100010) && !Rx_error)
                             begin
                              crc_error = 1'b1 ;
                              Error_Ready = 1'b1;
                             end 
                         else if((Rx_valid_count <= 6'b100010) && !Rx_error)
                           begin
                             crc_error = 1'b0;
                             Error_Ready = 1'b1;
                           end
                         else
                            begin
                            crc_error = 1'b0 ;
                            Error_Ready = 1'b0;
                            end
                            
                         
                          if(Rx_valid_count <= 6'b100000)
                            HC_Data_count = Rx_valid_count;
                          else if(Rx_valid_count == 6'b100001)
                            HC_Data_count = Rx_valid_count - 2'b01;
                          else if(Rx_valid_count >= 6'b100010)
                            HC_Data_count = Rx_valid_count - 2'b10;
                          else
                            HC_Data_count = 6'b10;
                     end
       STATE_RX_ERROR : begin
                         if (PID_cks_Err)
                           begin
                             if (in_transfer_reg)
                            begin
                              data_corrupted = 'b1;
                              Error_Ready = 1'b1;
                             end
                           else if (HS_transfer_reg)
                             begin
                               HS_corrupted = 1'b1;
                               HS_Ready = 1'b1;
                             end
                           end
                      else if (((PID_reg == PID_DATA1) && !Data_toggle) || ((PID_reg == PID_DATA0 )&& Data_toggle))
                        begin
                          data_toggle_error =1'b1;
                          Error_Ready = 1'b1;
                        end
                  
                      else
                        begin
                          data_toggle_error =1'b0;
                          HC_Rx_error = 1'b1;
                          Error_Ready = 1'b1;
                        end
                        end 
       default : begin
                   HS_corrupted = 1'b0;
                   data_corrupted = 'b0;
                   Rx_Data_HC = 8'b0;
                   HS_Ready = 1'b0;
                   Error_Ready = 1'b0;
                   crc_error = 1'b0;
                   Time_out = 1'b0;
                   nak_o = 1'b0;
                   stall_o = 1'b0;
                   Enable = 1'b0;
                   HC_Data_count = 6'b0;
                   data_toggle_error = 1'b0;
                   crc_Done = 1'b0;
                   HC_Rx_error = 1'b0;
                   ack_in = 1'b0;
                   edge_count_0 = 1'b0;
                  end 
                endcase
              end
    
always @ (posedge CLK or negedge RST)
 begin
  if(!RST)
   begin
     Data_in = 8'b0;
   end
 else if(Rx_Valid)
   begin
     Data_in = UTMI_Rx_Data;
   end
 else
   begin
     Data_in = Data_in;
   end
 end
   
   //save pid to check toggle
   always @ (posedge CLK or negedge RST)
 begin
  if(!RST)
   begin
     PID_reg <= 8'b0;
   end
 else if(current_state == STATE_RX_PID)
   begin
     PID_reg <= UTMI_Rx_Data;
   end
 end 
  
    // write in fifo  and check crc//
    always@(posedge CLK or negedge RST)
   begin
     if(!RST)
       begin     
         write_enable <= 1'b0; 
         crc_Enable <= 1'b0;
       end
     else if(Rx_valid_count == 6'b100000)
       begin
         write_enable <= 1'b0; 
         crc_Enable <= 1'b0; 
       end
     else if(current_state == STATE_RX_DATA)
       begin
         if(Rx_Valid)
           begin
             write_enable <= 1'b1; 
              crc_Enable <= 1'b1;
            end
         else if (data_recieved)
           begin   
             write_enable <= 1'b0; 
             crc_Enable <= 1'b0; 
           end  
       else 
           begin   
            // write_enable <= 1'b0; 
             crc_Enable <= 1'b0; 
           end
         end
       end
                       
          
   //crc field
   always@(posedge CLK or negedge RST)
   begin
     if(!RST)
       begin
         CRC_data <= 16'b0;
       end
     else if(!Rx_Valid &&(Rx_valid_count == 6'b100001))
           begin
             CRC_data[7:0] <= Data_in; 
           end
         else if(!Rx_Valid &&(Rx_valid_count == 6'b100010))
           begin
             CRC_data[15:8] <= Data_in;
           end 
       end 
             
   
                 
  crc16 u0_crc16 (
  .clk(CLK),
  .reset(RST),
  .crc_done(crc_Done),
  .crc_enable(crc_Enable),
  .data_in(Data_in),
  .crc_out(crc16_out) 
 );                  
  
//Data Counter
always @ (posedge CLK or negedge RST)
 begin
   if(!RST)
     Rx_valid_count <= 6'b0;
   else if(Enable)
     begin
     if(Rx_Valid && !Rx_error )
	    begin
        Rx_valid_count <= Rx_valid_count + 1'b1 ;
	    end	
    
    else
      begin 
        Rx_valid_count <= Rx_valid_count;
      end
    end
  else 
   begin
    Rx_valid_count <= 6'b0; 
   end
 end
 

 //Timeout Counter
 always @ (posedge CLK or negedge RST)
 begin
  if(!RST)
   begin
    edge_count <= 7'b0 ;
   end
  else if(current_state == STATE_RX_WAIT)
   begin
    if (edge_count_done)
	 begin
      edge_count <=  edge_count;
	 end
	else
	 begin
      edge_count <= edge_count + 16'b1 ;
	 end	
   end 
 else if(edge_count_0)
   begin
   edge_count <= 16'b0;
 end
  else
   begin
    edge_count <= edge_count ;
   end   
 end
 
assign edge_count_done = (edge_count == 24038) ? 1'b1 : 1'b0 ; 



//pid check error

always@(posedge CLK or negedge RST)
    begin
      if(!RST)
        begin
          PID_cks_Err <= 1'b0;
        end
      else if(next_state == STATE_RX_PID) 
        begin
          if(Data_in[3:0] != ~Data_in[7:4])
            begin
              PID_cks_Err <= 1'b1;
            end
          else
            begin
              PID_cks_Err <= 1'b0;
            end
          end
        else if (next_state == STATE_IDLE)
          begin
            PID_cks_Err <= 1'b0;
          end
        end
  
endmodule

