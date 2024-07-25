`timescale 1ns/1ps
module USB_top_tb #(parameter DSIZE = 8,parameter ASIZE = 5,b_a_w = 2, f_n_w = 4, 
    MEM_ADDR_WIDTH = 6, MEM_NUM_COL=4, MEM_COL_WIDTH=32, MEM_DATA_WIDTH =MEM_COL_WIDTH*MEM_NUM_COL)
    ();
reg                           SIE_clk_tb;
reg                           UTMI_clk_tb;
reg                           reset_tb;
reg		                        DP_tb; 
reg                           DM_tb;
reg                           Reg_WrEn_tb;
reg      [MEM_ADDR_WIDTH-1:0] Reg_Address_tb;
reg      [7:0]                Reg_WrData_tb;
reg                           Reg_RdEn_tb;
wire     [7:0]                Reg_RdData_tb;
wire        	                TX_DP_tb;
wire                       	  TX_DM_tb;
wire       	                  TX_en_tb;
reg                           UHCI_clk_tb;
reg                           AXI_clk_tb;
reg                           En_B_tb;
reg      [MEM_NUM_COL-1:0]    w_B_tb;
reg      [MEM_NUM_COL-1:0]    r_B_tb;
reg      [MEM_ADDR_WIDTH-1:0] addrB_tb;
reg      [MEM_COL_WIDTH-1:0]  dinB_tb;
wire                          Data_toggle_Mem_tb;
wire     [MEM_COL_WIDTH-1:0]  doutB_tb;
wire                           Data_toggle_RF_tb;

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

parameter FS_Period = 83.3333333;
integer i;
initial 
 begin
   
   $dumpfile("USB_top.vcd") ;       
   $dumpvars; 
   
   // initialization
   initialize();
   reset();
   write_FL('h100,6'b0);
   //to get back to the same TD Number in the next frame.
   write_FL('h100,6'b1);
   //to get back to the TD Number 27 next frame.
   write_FL('h1b0,6'd2);
   /* T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd17;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b0;
    max_length_tb = 'd32;
    buffer_pointer_tb = 32'd32; 
    write_TD(6'd16); 
    T_tb=1'b1;
    pid_tb = 8'b01101001;
    LP_tb = 28'd18;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; 
    write_TD(6'd17); */
  //case1: control read transaction
	//setup transaction TD
	T_tb=1'b0;
	pid_tb = 8'b00101101;
	LP_tb = 28'd17;
	DV_addr_tb = 7'd17;
	EP_addr_tb = 4'd5;
	data_toggle_tb =1'b0;
	max_length_tb = 'h7ff;
	buffer_pointer_tb = 32'd32; // next TD will have buffer pointer @ location 34
	write_TD(6'd16);

// Enabling the host before writing the TD no. 17 which will cause invalid PID Error 
  Enable_Host;
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  #1500
   rx_data_HS();
   EOP();

//Writing The rest of the TDs.
  repeat(10)@(posedge UHCI_clk_tb);
	//in transaction
	T_tb=1'b0;
	pid_tb = 8'b01101001;
	LP_tb = 28'd18;
	DV_addr_tb = 7'd17;
	EP_addr_tb = 4'd5;
	data_toggle_tb =1'b1;
	max_length_tb = 11'd32;
	buffer_pointer_tb = 32'd35; 
	write_TD(6'd17);
	//out transaction
	T_tb=1'b0;
	pid_tb = 8'b11100001;
	LP_tb = 28'd19;
	DV_addr_tb = 7'd17;
	EP_addr_tb = 4'd5;
	data_toggle_tb =1'b1;
	max_length_tb = 'h7ff;
	buffer_pointer_tb = 32'd35; 
	write_TD(6'd18);  
	
	  //setup
	  T_tb=1'b0;
    pid_tb = 8'b00101101;
    LP_tb = 28'd20;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b0;
    max_length_tb = 'h7ff;
    buffer_pointer_tb = 32'd32; // next TD will have buffer pointer @ location 34
    write_TD(6'd19);
    //out transaction
    T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd21;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; //same data that were read by the host 
    write_TD(6'd20);
    //in transaction
    T_tb=1'b0;
    pid_tb = 8'b01101001;
    LP_tb = 28'd22;
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 'h7ff;
    buffer_pointer_tb = 32'd35; 
    write_TD(6'd21);
    
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
    write_TD(6'd22);
    
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
    write_TD(6'd23);
    
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
    write_TD(6'd24); 
    
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
    write_TD(6'd25); 
    
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
    write_TD(6'd26);  
  
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
    write_TD(6'd27);
    
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
    write_TD(6'd28);
    
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
    write_TD(6'd29);
    
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
    write_TD(6'd30);
    
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
    write_TD(6'd31);
    

    
   write_mem(6'd32);
    write_mem(6'd33);
    Enable_Host();
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  @(negedge TX_en_tb)
  #1500
   rx_data_HS();
   EOP();
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

   repeat(4)@(posedge UHCI_clk_tb);
   Enable_Host();
   
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
   //out transaction
    T_tb=1'b0;
    pid_tb = 8'b11100001;
    LP_tb = 28'd28; //to refer to in transaction TD to test babble error
    DV_addr_tb = 7'd17;
    EP_addr_tb = 4'd5;
    data_toggle_tb =1'b1;
    max_length_tb = 11'd32;
    buffer_pointer_tb = 32'd35; 
    write_TD(6'd20);  
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
   #20000 $stop;
 end 


///tasks
task initialize;
  begin
SIE_clk_tb = 1'b0;
reset_tb = 1'b0;
  DP_tb = 1'b1;
  DM_tb = 1'b0;
UHCI_clk_tb = 1'b0;
AXI_clk_tb = 1'b0;
En_B_tb = 1'b0;
w_B_tb = 'b0;
r_B_tb = 'b0;
addrB_tb = 'b0;
dinB_tb= 'b0;

  end
endtask

task reset;
  begin
    reset_tb = 1'b1;
    #5
    reset_tb = 1'b0;
    #5
    reset_tb = 1'b1;
  end
endtask

task Enable_Host;
  begin
    Reg_WrEn_tb = 1;
    Reg_Address_tb = 5;
    Reg_WrData_tb  = 8'b1;
    @(posedge UHCI_clk_tb);
    Reg_Address_tb = 4;
    Reg_WrData_tb  = 8'b10;
    @(posedge UHCI_clk_tb);
    Reg_WrEn_tb = 0;
    @(posedge UHCI_clk_tb);
  end
endtask

task Driver_Stop;
  begin
    Reg_WrEn_tb = 1;
    Reg_Address_tb = 5;
    Reg_WrData_tb  = 8'b0;
  end
endtask



task write_FL (input [MEM_DATA_WIDTH-1:0] w_data , input [MEM_ADDR_WIDTH-1:0] W_addr);
    begin
     En_B_tb = 1;
     dinB_tb = w_data[31:0];
     w_B_tb = 4'b0001;
     addrB_tb = W_addr;
     @(posedge UHCI_clk_tb);
     dinB_tb = w_data[63:32];
     w_B_tb = 4'b0010;
     @(posedge UHCI_clk_tb);
     dinB_tb = w_data[95:64];
     w_B_tb = 4'b0100;
     @(posedge UHCI_clk_tb);
     dinB_tb = w_data[127:96];
     w_B_tb = 4'b1000;
     @(posedge UHCI_clk_tb);
     En_B_tb = 0;
    end
endtask

task write_TD (input [MEM_ADDR_WIDTH-1:0] W_addr);
    begin
     data_tb= {buffer_pointer_tb,max_length_tb,1'b0,data_toggle_tb,EP_addr_tb,DV_addr_tb,pid_tb,8'b0,1'b1,23'b0,LP_tb,3'b0,T_tb};

     En_B_tb = 1;
     dinB_tb = data_tb[31:0];
     w_B_tb = 4'b0001;
     addrB_tb = W_addr;
     @(posedge UHCI_clk_tb);
     dinB_tb = data_tb[63:32];
     w_B_tb = 4'b0010;
     @(posedge UHCI_clk_tb);
     dinB_tb = data_tb[95:64];
     w_B_tb = 4'b0100;
     @(posedge UHCI_clk_tb);
     dinB_tb = data_tb[127:96];
     w_B_tb = 4'b1000;
     @(posedge UHCI_clk_tb);
     En_B_tb = 0;
    end
endtask

task write_mem (input [MEM_ADDR_WIDTH-1:0] W_addr);
	begin
	 En_B_tb = 1;
	 data_in = 128'd3459;
	 addrB_tb = W_addr;
	 @(posedge UHCI_clk_tb);
	 w_B_tb = 4'b0001;
	 dinB_tb = data_in[31:0];
	 @(posedge UHCI_clk_tb);
	 w_B_tb = 4'b0010;
	 dinB_tb = data_in[63:32];
	 @(posedge UHCI_clk_tb);
	 w_B_tb = 4'b0100;
	 dinB_tb = data_in[95:64];
	 @(posedge UHCI_clk_tb);
	 w_B_tb = 4'b1000;
	 dinB_tb = data_in[127:96];
	 addrB_tb = W_addr;
	 @(posedge UHCI_clk_tb);
   En_B_tb = 0;
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

//crc error
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
Driver_Stop();
data(8'b01001011);
Reg_WrEn_tb = 0;
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
///clock generation
always begin
        #41.6
        UHCI_clk_tb = !UHCI_clk_tb ;
        #41.6
        UHCI_clk_tb = !UHCI_clk_tb ;
       end
       

always begin
        #10.4
        SIE_clk_tb = !SIE_clk_tb ;
        #10.4
        SIE_clk_tb = !SIE_clk_tb ;
       end
       
 always begin
        #10.4
        UTMI_clk_tb = !SIE_clk_tb ;
        #10.4
        UTMI_clk_tb = !SIE_clk_tb ;
       end      
///////instantiation////
USB_top U0_USB_top(
.SIE_clk(SIE_clk_tb),
.UTMI_clk(UTMI_clk_tb),
.reset(reset_tb),
.DP(DP_tb), 
.DM(DM_tb),
.TX_DP(TX_DP_tb),
.TX_DM(TX_DM_tb),
.TX_en(TX_en_tb),
.Reg_WrEn(Reg_WrEn_tb),
.Reg_Address(Reg_Address_tb),
.Reg_WrData(Reg_WrData_tb),
.Reg_RdEn(Reg_RdEn_tb),
.Reg_RdData(Reg_RdData_tb),
.En_B(En_B_tb),
.w_B(w_B_tb),
.r_B(r_B_tb),
.addrB(addrB_tb),
.dinB(dinB_tb),
.Data_toggle_Mem(Data_toggle_Mem_tb),
.doutB(doutB_tb),
.Data_toggle_RF(Data_toggle_RF_tb)
);
endmodule