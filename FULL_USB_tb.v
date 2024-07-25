`timescale 1ns/1ps
module FULL_USB_tb #(parameter ADDR_W = 32, parameter Data_W = 32, parameter usb_mem_W = 6,parameter DSIZE = 8,parameter ASIZE = 5,b_a_w = 2, f_n_w = 4, 
    MEM_ADDR_WIDTH = 6, MEM_NUM_COL=4, MEM_COL_WIDTH=32, MEM_DATA_WIDTH =MEM_COL_WIDTH*MEM_NUM_COL)
    ();
    
 reg                   Clk_axi_tb;
 reg                   Rst_tb;
 reg                   R_Valid_Address_tb; 
 reg                   Read_Ready_tb;
 reg [ADDR_W-1:0]      Read_Address_axi_tb;
 reg [2:0]             R_Prot_tb;

 reg [ADDR_W-1:0]      Write_Address_axi_tb;
 reg [2:0]             W_Prot_tb;
 reg                   Write_Valid_tb;
 reg [Data_W-1:0]      Write_Data_axi_tb;
 reg [3:0]             Write_Strobe_tb;


 reg                   SIE_clk_tb;
 reg                   UTMI_clk_tb;
 reg                   reset_tb;
 reg                   DP_tb, DM_tb;

wire                     TX_DP_tb;
wire                     TX_DM_tb;
wire                     TX_en_tb;


wire                     R_Ready_Address_tb, Valid_Data_R_tb;
wire                     R_Error_tb, Write_Ready_tb, W_Error_tb;
wire [Data_W-1:0]        Read_Data_axi_tb;

//signals for test
reg [127:0] data_in;
reg [127:0]  data_tb;
reg [31:0] buffer_pointer_tb;
reg [10:0] max_length_tb;
reg data_toggle_tb;
reg [3:0] EP_addr_tb;
reg [6:0] DV_addr_tb;
reg [7:0] pid_tb;
reg [27:0] LP_tb;
reg T_tb;
reg halt;
reg terminate;
parameter FS_Period = 83.3333333;
parameter AXI_Period = 38.4615385;  //26 MHZ
integer i;

initial 
 begin
   
   $dumpfile("USB_top.vcd") ;       
   $dumpvars; 
   
   // initialization
   initialize();
   
   reset();
   
   write_FL('h100, 32'b00000000000000100000000000000000);
   //to get back to the same TD Number in the next frame.
   write_FL('h100, 32'b00000000000000100000000000000100);
   //to get back to the TD Number 27 next frame.
   write_FL('h1b0, 32'b00000000000000100000000000001000);
   //to get back to the TD Number 28 next frame.
   write_FL('h1c0, 32'b00000000000000100000000000001100);
   
  //case1: invalid PID
  T_tb=1'b0;
  pid_tb = 8'b00101101;
  LP_tb = 28'd17;
  DV_addr_tb = 7'd17;
  EP_addr_tb = 4'd5;
  data_toggle_tb =1'b0;
  max_length_tb = 'h7ff;
  buffer_pointer_tb = 32'd32; // next TD will have buffer pointer @ location 34
  write_TD ( 32'b00000000000000100000000001000000);
   
  //write_reg to enable host
  write_reg(32'd1, 32'd131333);
        Write_Valid_tb = 1'b0;
    @(negedge TX_en_tb)
    @(negedge TX_en_tb)
    @(negedge TX_en_tb)
    #1500
    rx_data_HS();
    EOP();
  //halt wait condition
  while(halt == 1'b0) begin
    read_reg(32'd131332);
    @(posedge Valid_Data_R_tb)
    halt = Read_Data_axi_tb[1];
    @(posedge R_Ready_Address_tb);
  end
  halt = 1'b0;
  R_Valid_Address_tb = 1'b0;

  //in transaction
  T_tb=1'b0;
  pid_tb = 8'b01101001;
  LP_tb = 28'd18;
  DV_addr_tb = 7'd17;
  EP_addr_tb = 4'd5;
  data_toggle_tb =1'b1;
  max_length_tb = 11'd32;
  buffer_pointer_tb = 32'd35; 
  write_TD(32'b00000000000000100000000001000100);

  ///////////////////////////////////////////////////////////////////////////////////////////////////////
//out transaction
  T_tb=1'b0;
  pid_tb = 8'b11100001;
  LP_tb = 28'd19;
  DV_addr_tb = 7'd17;
  EP_addr_tb = 4'd5;
  data_toggle_tb =1'b1;
  max_length_tb = 'h7ff;
  buffer_pointer_tb = 32'd35; 
  write_TD(32'b00000000000000100000000001001000);  
  
    //setup
   T_tb=1'b0;
     pid_tb = 8'b00101101;
     LP_tb = 28'd20;
     DV_addr_tb = 7'd17;
     EP_addr_tb = 4'd5;
     data_toggle_tb =1'b0;
     max_length_tb = 'h7ff;
       buffer_pointer_tb = 32'd32; // next TD will have buffer pointer @ location 34
     write_TD(32'b00000000000000100000000001001100);
    //out transaction
    T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd21;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; //same data that were read by the host 
    write_TD(32'b00000000000000100000000001010000);
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd22;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'h7ff;
    buffer_pointer_tb = 32'd35; 
    write_TD(32'b00000000000000100000000001010100);
    
    ///testing errors
    //sync error
    //in transaction
     T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd23;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd37; 
    write_TD(32'b00000000000000100000000001011000);
    
    //framing error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd24;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd37; 
    write_TD(32'b00000000000000100000000001011100);
    
    //bit stuff error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd25;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd37; 
    write_TD(32'b00000000000000100000000001100000); 
    
    //sie errors
    //timeout error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd26;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd37; 
    write_TD(32'b00000000000000100000000001100100); 
    
    //crc error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd27;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b0;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd37; 
    write_TD(32'b00000000000000100000000001101000);  
  
    //short packet
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd28;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd39; 
    write_TD(32'b00000000000000100000000001101100);
    
    //toggle error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd29;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd41; 
    write_TD(32'b00000000000000100000000001110000);
    
    //PID error
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd30;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b0;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd41; 
    write_TD(32'b00000000000000100000000001110100);
    
    //ack corrupted
    //out transaction
    T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd31;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; //same data that were read by the host 
    write_TD(32'b00000000000000100000000001111000);
    
    //Nak received
    //out transaction
    T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd20;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; //same data that were read by the host 
    write_TD(32'b00000000000000100000000001111100);

    //enable host
    write_reg(32'd2, 32'd131332);  //clear error bit
    write_reg(32'd1, 32'd131333);  //set RS
    Write_Valid_tb = 1'b0;
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  #1500
   rx_data_HS();
   EOP();
  //////////////////////////////////////////////////////////////////////////////////////////////////////////
@(negedge TX_en_tb)
  
  rx_data();
  EOP();
  #1500
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
    #1500
   rx_data_HS();
   EOP();
   
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  #1500
   rx_data_HS();
   EOP();
   

  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  #1500
   rx_data_HS();
   EOP();
   
   @(negedge TX_en_tb)
   #1500
   null_data();
   EOP();
   
  @(negedge TX_en_tb)
   #1500
   SYNC_error();
   EOP();

   @(negedge TX_en_tb)
   #1500
   framing_error();
   EOP();
   

   @(negedge TX_en_tb)
   #1500
   bit_stuff_error();
   EOP();
   
   @(negedge TX_en_tb)
   #1500
   time_out_chk();
   
  @(negedge TX_en_tb)
   #1500 
   crc_error_and_Driver_stop();
   EOP();
   while(halt == 1'b0) begin
    read_reg(32'd131332);
    @(posedge Valid_Data_R_tb)
    halt = Read_Data_axi_tb[1];
    @(posedge R_Ready_Address_tb);
   end
   halt = 1'b0;
   R_Valid_Address_tb = 1'b0;

   //out transaction
   T_tb=1'b0;
   pid_tb = 8'b11100001;
   LP_tb = 28'd28; //to refer to in transaction TD to test babble error
   DV_addr_tb = 7'd17;
   EP_addr_tb = 4'd5;
   data_toggle_tb =1'b1;
   max_length_tb = 11'd32;
   buffer_pointer_tb = 32'd35; 
   write_TD(32'b00000000000000100000000001010000);  

   repeat(4)#FS_Period;
   //enable_host
 @(posedge Write_Ready_tb)
   write_reg(32'd1, 32'd131333);
   Write_Valid_tb = 1'b0;
   
  @(negedge TX_en_tb)
   #1500    
   shortpacket();
   EOP();
   
   @(negedge TX_en_tb)
   #1500    
   toggle_error();
   EOP();
   

  @(negedge TX_en_tb)
   #1500    
   pid_error();
   EOP();
   
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
   #1500  
  
   ack_corr();
   EOP(); 
   
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
   #1500    
   NAK();
   EOP();
   
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
   #1500    
   stall();
   EOP();
 
   @(negedge TX_en_tb)
   #1500    
   babble_error();
   EOP();

   while(terminate == 1'b0) begin
    read_reg(32'd131332);
    @(posedge Valid_Data_R_tb)
    terminate = Read_Data_axi_tb[2];
    @(posedge R_Ready_Address_tb);
   end
   terminate = 1'b0;
   R_Valid_Address_tb = 1'b0;
   #AXI_Period
   read_mem(32'b00000000000000100000000010001100);

   #200

   write_reg(32'd2, 32'd131328);
   Write_Valid_tb = 1'b0;
   #AXI_Period
   read_reg(32'd131329);
   R_Valid_Address_tb = 1'b0;
   #20000
$stop;
 end 


//tasks

/*task reset;
  begin
    reset_tb = 1'b1;
    #AXI_Period
    reset_tb = 1'b0;
    #AXI_Period
    reset_tb = 1'b1;
  end
endtask

task Driver_Stop;
  begin
    Reg_WrEn_tb = 1;
    Reg_Address_tb = 5;
    Reg_WrData_tb  = 8'b0;
  end
endtask
*/
task stop_mode;
  begin  
     //force in stop mode 
       Write_Valid_tb = 1'b1; 
       Write_Address_axi_tb = 32'b00000000000000100000000100000101;
       Write_Data_axi_tb = 'h0;
       Write_Strobe_tb = 4'b1111;
end    
endtask

task write_reg(input [32:0] w_data , input [32:0] W_addr);
  begin  
     //force in stop mode 
        Write_Valid_tb = 1'b1; 
        Write_Address_axi_tb = W_addr;
        Write_Data_axi_tb = w_data;
        Write_Strobe_tb = 4'b1111;
  @(posedge Write_Ready_tb);
end    
endtask

task read_reg(input [31:0] W_addr);
  begin
    R_Valid_Address_tb = 1'b1;
    Read_Address_axi_tb = W_addr;
    Read_Ready_tb = 1'b1;
    
    @(posedge Valid_Data_R_tb)
    #AXI_Period;
  end
endtask

task read_mem ( input [31:0] R_addr ) ;
  begin
    
    R_Valid_Address_tb = 1'b1;
    Read_Ready_tb = 1'b1;
    Read_Address_axi_tb = R_addr;
    @(posedge Valid_Data_R_tb)
    #AXI_Period
    Read_Address_axi_tb = R_addr + 1;
    @(posedge Valid_Data_R_tb)
    #AXI_Period
    Read_Address_axi_tb = R_addr + 2;
    @(posedge Valid_Data_R_tb)
    #AXI_Period
    Read_Address_axi_tb = R_addr + 3;
    @(posedge Valid_Data_R_tb)
    R_Valid_Address_tb = 1'b0;
    
  end
endtask

task write_FL(input [128:0] w_data , input [31:0] W_addr);
  begin
    
       Write_Valid_tb = 1'b1;
       Write_Address_axi_tb = W_addr;
       Write_Data_axi_tb = w_data[31:0];
       Write_Strobe_tb = 4'b1111;
       
       //first frame list
       @(posedge Write_Ready_tb)
       Write_Valid_tb = 1'b1;
       Write_Address_axi_tb = W_addr + 1;
       Write_Data_axi_tb = w_data[63:32];
       Write_Strobe_tb = 4'b1111;
       
      @(posedge Write_Ready_tb)
       Write_Address_axi_tb = W_addr + 2;
       Write_Data_axi_tb = w_data[95:64];
       Write_Strobe_tb = 4'b1111;
      
      @(posedge Write_Ready_tb)
       Write_Address_axi_tb = W_addr+3;
       Write_Data_axi_tb = w_data[127:96];
       Write_Strobe_tb = 4'b1111;
      @(posedge Write_Ready_tb);
      
  end    
endtask 

task write_TD (input [31:0] W_addr);
    begin
      
       Write_Valid_tb = 1'b1;
       Write_Address_axi_tb = W_addr;
       Write_Data_axi_tb = {LP_tb,3'b0,T_tb};
       Write_Strobe_tb = 4'b1111;
       
       //first frame list
       @(posedge Write_Ready_tb)
       Write_Address_axi_tb = W_addr + 1;
       Write_Data_axi_tb = {8'b0 , 1'b1 ,23'b0};
       Write_Strobe_tb = 4'b1111;
       
      @(posedge Write_Ready_tb)
       Write_Address_axi_tb = W_addr + 2;
       Write_Data_axi_tb = {max_length_tb,1'b0,data_toggle_tb,EP_addr_tb,DV_addr_tb,pid_tb};
       Write_Strobe_tb = 4'b1111;
      
      @(posedge Write_Ready_tb)
       Write_Address_axi_tb = W_addr+3;
       Write_Data_axi_tb = {buffer_pointer_tb};
       Write_Strobe_tb = 4'b1111;
      @(posedge Write_Ready_tb);
       
     
    end
endtask

//ack received
task rx_data_HS;
  begin

SYNC();
data(8'b11010010);
end
endtask
//ack corrupted

task ack_corr;
  begin
SYNC();
data(8'b11101011);
end
endtask
//Nak received
task NAK;
  begin
SYNC();
data(8'b01011010);
end
endtask
//stall received
task stall;
  begin
SYNC();
data(8'b00011110);
end
endtask
// SEND SYNC PATTERN //
task SYNC;
  begin
  @(negedge UTMI_clk_tb)
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period
  
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period

  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period
  
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  end
endtask

// SEND EOP PATTERN //
task EOP;
  begin
  #FS_Period
  DP_tb = 1'b0;
  DM_tb = 1'b0;//SE0
  #FS_Period
  DP_tb = 1'b0;
  DM_tb = 1'b0;//SE0
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  end
endtask

// DATA IN //
task data;
input [7:0] data;
begin
i = 1'b0;
for (i=0; i<8 ;i = i+1) begin
#FS_Period
DP_tb = data[i] ? DP_tb: ~DP_tb;
DM_tb = ~DP_tb;
end
end
endtask

task rx_data;
  begin
SYNC();
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
data(8'b10100100);
end
endtask

//crc error and driver stop
task crc_error_and_Driver_stop;
  begin
SYNC();
data(8'b11000011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
write_reg(32'd0, 32'd131333);
Write_Valid_tb = 1'b0;
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b10001011);
data(8'b11101010);
end
endtask

task time_out_chk;
  begin

#500000;
end
endtask


task null_data;
  begin
SYNC();

data(8'b01001011);
data(8'b10111111);
data(8'b11011111);
#FS_Period
DP_tb = 1'b0;
DM_tb = 1'b1;
#FS_Period
DP_tb = 1'b0;
DM_tb = 1'b1;
end
endtask

//sync error
task SYNC_error;
  begin
  @(negedge UTMI_clk_tb)
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period
  
  DP_tb = 1'b1;
  DM_tb = 1'b0;//k  error
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period

  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b1;
  DM_tb = 1'b0;//j
  #FS_Period
  
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  #FS_Period
  DP_tb = 1'b0;
  DM_tb = 1'b1;//k
  end
endtask
//babble error
task babble_error;
  begin
SYNC();
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
data(8'b10100100);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
end
endtask


//framing error
task framing_error;
  begin
SYNC();
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
error('b100100);
end
endtask

task bit_stuff_error;
  begin
SYNC();
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b11111111); //bit stuff error
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
data(8'b10100100);
end
endtask
//toggle error
task toggle_error;
  begin
SYNC();
data(8'b11000011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
data(8'b10100100);
end
endtask
//short packet
task shortpacket();
  begin
SYNC();
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
end
endtask
//pid error
task pid_error;
  begin
SYNC();
data(8'b10111011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b00110101);
data(8'b11001010);
data(8'b01001011);
data(8'b10010101);
data(8'b00110110);
data(8'b10111100);
data(8'b10110101);
data(8'b11011100);
data(8'b10100100);
end
endtask

task error;
input [5:0] data;
begin
i = 1'b0;
for (i=0; i<6 ;i = i+1) begin
#FS_Period
DP_tb = data[i] ? DP_tb: ~DP_tb;
DM_tb = ~DP_tb;
end
end
endtask

task initialize;
  begin
 Clk_axi_tb=0;
 Rst_tb=0;
 R_Valid_Address_tb=0; 
 Read_Ready_tb=0;
 Read_Address_axi_tb=0;
 R_Prot_tb=0;
 Write_Address_axi_tb=0;
 W_Prot_tb=0;
 Write_Valid_tb=0;
 Write_Data_axi_tb=0;
 Write_Strobe_tb=0;
 SIE_clk_tb=1'b0;
 UTMI_clk_tb=1'b0;
 reset_tb=1'b0;
 DP_tb=1'b0; 
 DM_tb=1'b0;
 halt=1'b0;
 
 end
endtask

task reset;
  begin
    Rst_tb = 1'b1;
    #2
    Rst_tb = 1'b0;
    #2
    Rst_tb = 1'b1;
  end
endtask



///clock generation
always begin
        #10.4
        SIE_clk_tb = !SIE_clk_tb ;
       end
 
 initial begin  
      UTMI_clk_tb = 1'b0;
       #1    
      forever begin
        #10.4
        UTMI_clk_tb = !UTMI_clk_tb ;
       end 
 end    
       
 always begin
        #(AXI_Period/2)
        Clk_axi_tb = !Clk_axi_tb ;
      end
        
///////instantiation////
USB_AXI_TOP DUT(
.Clk_axi(Clk_axi_tb), 
.Rst(Rst_tb),
.R_Valid_Address(R_Valid_Address_tb), 
.Read_Ready(Read_Ready_tb),
.Read_Address_axi(Read_Address_axi_tb),
.R_Prot(R_Prot_tb),
.Write_Address_axi(Write_Address_axi_tb),
.W_Prot(W_Prot_tb),
.Write_Valid(Write_Valid_tb),
.Write_Data_axi(Write_Data_axi_tb),
.Write_Strobe(Write_Strobe_tb),
.SIE_clk(SIE_clk_tb),
.UTMI_clk(UTMI_clk_tb),
.DP(DP_tb), 
.DM(DM_tb),
.TX_DP(TX_DP_tb),
.TX_DM(TX_DM_tb),
.TX_en(TX_en_tb),
.R_Ready_Address(R_Ready_Address_tb), 
.Valid_Data_R(Valid_Data_R_tb),
.R_Error(R_Error_tb), 
.Write_Ready(Write_Ready_tb), 
.W_Error(W_Error_tb),
.Read_Data_axi(Read_Data_axi_tb)
);
endmodule
