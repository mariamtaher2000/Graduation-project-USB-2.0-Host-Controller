module PacketEncode_USB (
  input wire       clk,
  input wire       reset,
  //UHCI interface
  input wire [6:0] Address,
  input wire [3:0] Endpoint_address,
  input wire [7:0] PID,
  input wire [10:0] frame_no,
  input wire       sof,
  input wire       data_toggle,
  input wire       maxpacket_length,
  input wire       info_valid,
  input wire       Token_valid,
  output reg       sof_done,
  output reg        IDLE_ready,
  // FIFO
  input wire       fifo_empty,
  input wire [7:0] Tx_data_HC,
  output reg       read_enable,
  //UTMI
  input wire        tx_ready,
  input wire [1:0]  line_state,
  output reg        tx_valid,
  output reg [7:0]  tx_data_utmi,
  
  //packet Decode
  input wire        Ack,
  output  reg       HS_transfer,
  output reg         enable,
  output reg        in_transfer,
  output reg        bus_enable
  );
  
//PID 
localparam
PID_OUT          = 8'b11100001,
PID_IN           = 8'b01101001,
PID_SOF          = 8'b10100101,
PID_SETUP        = 8'b00101101,

PID_DATA0        = 8'b11000011,
PID_DATA1        = 8'b01001011,

PID_ACK          = 8'b11010010;

//states
localparam
IDLE             = 4'b0000,
Tx_Token1        = 4'b0001,
Tx_Token2        = 4'b0011,
Tx_Token3        = 4'b0010,
EOP_detection    = 4'b0110,
TX_PID           = 4'b0111,
TX_Data          = 4'b0101,
Tx_crc1          = 4'b0100,
Tx_crc2          = 4'b1100,
Tx_Ack           = 4'b1101;

//state transitions
reg      [3:0]      current_state ,next_state ;
reg      [10:0]     Token_q; //register the frame number in case of start of frame or the device address and endpoint address in case of token packet
//nternal connections
reg [4:0] counter;//counter to count 32 byte of data
reg [7:0]  tx_data_utmi_reg;
reg tx_valid_reg;
reg sof_flag; // this flag is used to return to idle state from the third token byte(Tx_Token3) if the sof flag is asserted (as sof is asserted for one clock cycle (12MHZ))
reg sof_done_r;
//crc5
wire [4:0] crc5_out;
wire [4:0] crc5_data;
//crc16
reg crc_enable;
wire [15:0] crc16_out;
reg crc_done;
reg  [15:0] crc_save;
//datasync
reg bus_enable_reg;

 //linestate
reg [1:0] prev_linestate;
reg se0_detect;
wire se0_w;
wire eop_detect;

always @ (posedge clk or negedge reset)
begin
if (!reset)
  begin
    crc_save <= 16'b0;
  end
else if(counter == 'd31)
  begin
   crc_save <= crc16_out; 
  end
  else if(!maxpacket_length)
    begin
      crc_save <= 16'hffff;
      end
end

always @ (posedge clk or negedge reset)
begin
if (!reset)
  begin
    Token_q     <= 11'd0;
    sof_flag    <= 1'b0;
    end
else if (sof)
  begin
   Token_q         <= frame_no;
   sof_flag        <= 1'b1;
   end
else if (Token_valid & info_valid)
  begin
   Token_q    <= {Address, Endpoint_address};
   sof_flag    <= 1'b0;
   end
   end
  // flag to inform HC that sof transfer is done
  always @ (posedge clk or negedge reset)
begin
if (!reset)
  begin
    sof_done    <= 1'b0;
    end
else if (sof_flag && !Token_valid && (current_state == EOP_detection))
  begin
    sof_done    <= sof_done_r;
   end
 else if(Token_valid)
   begin
     sof_done    <= 1'b0;
   end
   end 
//counter
always @(posedge clk or negedge reset)
 begin
    if (!reset) begin
        counter <= 0;
    end 
    else if ((current_state == TX_Data) && tx_ready && (counter <= 5'd31)&& (!fifo_empty))  
    begin
        counter <= counter + 1;
    end
    else if (((current_state == TX_Data) && !tx_ready && (counter <= 5'd31)&& !fifo_empty) ||((current_state == TX_Data) && (counter <= 5'd31) && fifo_empty) ) //||  
      begin
        counter <= counter;
        end
    else if ((counter == 5'd31)&& !tx_ready)
      begin
      counter <= 0;
      
      end
      else
        begin
          counter<= 0;
          end
end


//state transition
always @ (posedge clk or negedge reset)
 begin
  if(!reset)
   begin
    current_state <= IDLE ;
   end
  else
   begin
    current_state <= next_state ;
   end
 end
 
 //next state logic
 always@(*)
 begin
	next_state = IDLE;
   case(current_state)
     IDLE:
     begin
       if((sof | (Token_valid & info_valid)) )
         begin
           next_state = Tx_Token1;
         end
       else if (Ack)
         begin
           next_state = Tx_Ack;
         end
       else
         begin
           next_state = IDLE;
         end
       end
         
      Tx_Token1:
      begin
        if (tx_ready)
          begin
            next_state = Tx_Token2;
          end
        else
          begin
            next_state = Tx_Token1; 
          end
      end
      
      Tx_Token2:
      begin
        if(tx_ready)
          begin
            next_state = Tx_Token3;
          end
        else
          begin
            next_state = Tx_Token2; 
          end
      end 
      
      Tx_Token3:
      begin
        if
          (tx_ready)
          begin
            next_state = EOP_detection;
          end
        else
          begin
           next_state = Tx_Token3; 
          end
        end
      
     EOP_detection:
      begin
        if(eop_detect)
          begin
            if (sof_flag | (PID == PID_IN))
              begin
              next_state = IDLE;
            end
            else //if (maxpacket_length)
              begin
               next_state = TX_PID; 
              end
            end
        else
          begin
          next_state = EOP_detection;
      end
    end
      
      TX_PID: 
       begin
        if(tx_ready && maxpacket_length)
          begin
            next_state = TX_Data;
          end
        else if (tx_ready && !maxpacket_length)
          begin
            next_state = Tx_crc1; 
          end
        else
          begin
          next_state = TX_PID;
        end
      end
      
      TX_Data: 
       begin
        if(tx_ready & (counter == 5'd31))
          begin
            next_state = Tx_crc1;
          end
        else if (fifo_empty & (counter!= 5'd31))
          begin
            next_state = TX_Data; 
          end
        else
          begin
            next_state = TX_Data;
          end
      end   
      
      Tx_crc1: 
       begin
        if(tx_ready)
          begin
            next_state = Tx_crc2;
          end
        else
          begin
            next_state = Tx_crc1; 
          end
      end 
      
       Tx_crc2: 
          begin
            if(tx_ready)
              begin
            next_state = IDLE;
          end
        else
        begin
        next_state = Tx_crc2;
      end 
           end
          
        Tx_Ack:
              begin
                if(tx_ready)
                  begin
            next_state = IDLE;
          end
        else
        begin
        next_state = Tx_Ack; 
           end
         end
        
        default:begin
            next_state = IDLE; 
          end    
endcase
end

//output logic
always@(*)
 begin
  //initialize outputs
  IDLE_ready = 1'b0;
  bus_enable_reg = 1'b0;
  sof_done_r = 1'b0;
  tx_valid_reg    = 1'b0;
  read_enable = 1'b0;
  in_transfer = 1'b0;
  crc_enable = 1'b0;
  crc_done = 1'b0; 
  HS_transfer = 1'b0;
  enable = 1'b0;
  case(current_state)
    IDLE: 
    begin
  HS_transfer = 1'b0;
  IDLE_ready = 1'b1;
  tx_valid_reg   = 1'b0;
  read_enable = 1'b0;
  in_transfer = 1'b0;
  enable = 1'b0; 
  crc_enable = 1'b0;
   tx_data_utmi_reg = 8'b0;
   if((sof | (Token_valid & info_valid)) )
         begin
          bus_enable_reg = 1'b1;
         end
       else if (Ack)
         begin
           bus_enable_reg = 1'b1;
         end
       else
         begin
           bus_enable_reg = 1'b0;
         end
    end
    
    Tx_Token1:
    begin 
      if(sof_flag)
        begin
          tx_data_utmi_reg = PID_SOF;
        end
      else
     begin   
   tx_data_utmi_reg = PID; 
    end
    
    if(tx_ready)
      begin
        bus_enable_reg = 1'b1;
      end
    else
      begin
        bus_enable_reg = 1'b0;
      end
  in_transfer = 1'b0;
  enable = 1'b0;
  tx_valid_reg    = 1'b1;
  read_enable = 1'b0;
  crc_enable = 1'b0;
  IDLE_ready = 1'b0;
    end
   
     
   Tx_Token2: 
   begin
  in_transfer = 1'b0;
  tx_valid_reg    = 1'b1;
  read_enable = 1'b0;
  tx_data_utmi_reg = Token_q[10:3]; 
  crc_enable = 1'b0;
  IDLE_ready = 1'b0;
      if(tx_ready)
      begin
        bus_enable_reg = 1'b1;
      end
    else
      begin
        bus_enable_reg = 1'b0;
      end
   end
      
    Tx_Token3: 
    begin
  crc_enable = 1'b0;
  tx_valid_reg    = 1'b1;
  read_enable = 1'b0;
  IDLE_ready = 1'b0;
  tx_data_utmi_reg = {Token_q[2:0], crc5_data};
        if(tx_ready)
      begin
        bus_enable_reg = 1'b1;
      end
    else
      begin
        bus_enable_reg = 1'b0;
      end
    end
    
      EOP_detection:
      begin
  crc_enable = 1'b0;
  tx_valid_reg    = 1'b0;
  read_enable = 1'b0;
  in_transfer = 1'b0;
  tx_data_utmi_reg = {Token_q[2:0], crc5_data};
  IDLE_ready = 1'b0;
  if(eop_detect)
    begin
       bus_enable_reg = 1'b1;
      if(PID == PID_IN)
        begin
          enable = 1'b1;
      in_transfer = 1'b1;
    end
  else
    begin
      in_transfer = 1'b0;
    end
  end
  else
    begin
    bus_enable_reg = 1'b0;
  end
    
 
  if(eop_detect && sof_flag)
    begin
      sof_done_r = 1'b1;
    end
  else
    begin
      sof_done_r = 1'b0;
    end
      end
    
    TX_PID:
    begin
  crc_enable = 1'b0;
  tx_valid_reg    = 1'b1;
  IDLE_ready = 1'b0;
  read_enable = 1'b0;
  tx_data_utmi_reg = data_toggle ? PID_DATA1 : PID_DATA0;
  in_transfer = 1'b0; 
        if(tx_ready)
      begin
        bus_enable_reg = 1'b1;
      end
    else
      begin
        bus_enable_reg = 1'b0;
      end 
   end
   
    TX_Data: 
    begin
  in_transfer = 1'b0;
tx_valid_reg    = 1'b1;
tx_data_utmi_reg = Tx_data_HC;
IDLE_ready = 1'b0;
  if (tx_ready)
    begin
      bus_enable_reg = 1'b1;
      if(!fifo_empty)
        begin
      read_enable = 1'b1;
      crc_enable = 1'b1;
         end
          else
            begin
               read_enable = 1'b0;
               crc_enable = 1'b0;    
          end
          end
    else if (fifo_empty & (counter!= 5'd31))
        begin
        bus_enable_reg = 1'b1;
      end  
      else
  begin
    read_enable = 1'b0;
    crc_enable = 1'b0;
    bus_enable_reg = 1'b0;
  end
  end 
    Tx_crc1: 
    begin   
        IDLE_ready = 1'b0;
  	tx_valid_reg    = 1'b1;
  	read_enable = 1'b0;
  	tx_data_utmi_reg = crc_save[7:0];
  	in_transfer = 1'b0;
  	if(tx_ready)
     	 begin
        	bus_enable_reg = 1'b1;
      	end
    	else
     	 begin
       		 bus_enable_reg = 1'b0;
      	 end 
   	end
    
    Tx_crc2: 
    begin
      IDLE_ready = 1'b0;
  tx_valid_reg    = 1'b1;
  read_enable = 1'b0;
  tx_data_utmi_reg = crc_save[15:8];
  HS_transfer = 1'b1;
  enable = 1'b1;
  crc_done = 1'b1;
  if(tx_ready)
      begin
        bus_enable_reg = 1'b1;
      end
    else
      begin
        bus_enable_reg = 1'b0;
      end   
    end 
    
    Tx_Ack:
  begin
    IDLE_ready = 1'b0;
  tx_valid_reg    = 1'b1;
  read_enable = 1'b0;
  tx_data_utmi_reg = PID_ACK;
  in_transfer = 1'b0; 
    end 
    
    default:
    begin
      IDLE_ready = 1'b0;
   bus_enable_reg = 1'b0;
  tx_valid_reg    = 1'b0;
  read_enable = 1'b0;
  in_transfer = 1'b0;
  tx_data_utmi_reg = 8'h00;
    end
  endcase
end


USB_crc16 U0_USB_crc16 (
  .clk(clk),
  .reset(reset),
  .crc_done(crc_done),
  .crc_enable(crc_enable),
  .data_in(Tx_data_HC),
  .crc_out(crc16_out) 
); 


//crc5 used for token and start-of-frame
USB_crc5 U0_USB_crc5 (
.data_in(Token_q),
.crc_in(5'h1f),
.crc_out(crc5_out) 
);
assign crc5_data = crc5_out;

 //end of packet detection
 always @(posedge clk or negedge reset)
  begin
    if (!reset)
      begin
        prev_linestate <= 2'b00;
        end
        else
          begin
    prev_linestate <= line_state;
    end
    end
    
assign se0_w = (prev_linestate == 2'b00 && line_state == 2'b00);
// detecting line state is in Se0 for 2 clock cycles
always @(posedge clk or negedge reset)
  begin
    if (!reset)
      begin
        se0_detect <= 1'b0;
        end
        else
          begin
            se0_detect <= se0_w;
            end
            end
  //detecting that end of packet is sent 
assign eop_detect = se0_detect & (line_state == 2'b01);

always@(posedge clk or negedge reset)
begin
if(!reset)
  begin
  tx_data_utmi <= 8'b00000000;
  end
  else
    begin
      tx_data_utmi <= tx_data_utmi_reg;
      end
      end
always@(posedge clk or negedge reset)
begin
if(!reset)
  begin
  tx_valid <= 1'b0;
  end
  else
    begin
      tx_valid <= tx_valid_reg;
      end
      end

always@(posedge clk or negedge reset)
begin
if(!reset)
  begin
  bus_enable <= 1'b0;
  end
  else
    begin
      bus_enable <= bus_enable_reg;
      end
      end
endmodule


