module UHCI_ctrl_top #(parameter DSIZE = 8,parameter ASIZE = 5,b_a_w = 2, f_n_w = 4, 
    MEM_ADDR_WIDTH = 6, MEM_NUM_COL=4, MEM_COL_WIDTH=32, MEM_DATA_WIDTH =MEM_COL_WIDTH*MEM_NUM_COL)
    (
    input wire        UHCI_clk,
    input wire        SIE_clk,
    input wire        rst_n,
    //AXI Slave - RegFile
    input                                   Reg_WrEn,
    input            [MEM_ADDR_WIDTH-1:0]   Reg_Address,
    input            [7:0]                  Reg_WrData,
    input                                   Reg_RdEn,
    output            [7:0]                 Reg_RdData,
    output                                  Data_toggle_RF,
    // sie - rxFIFO
    input wire        [DSIZE-1:0] rx_sie_data,
    input wire        SIE_data_w_en, // write enable from sie means that data is valid
    // sie - txFIFO
    input wire        tx_fifo_r_en,
    output wire       [DSIZE-1:0] tx_sie_data,
    output wire       tx_fifo_empty,
    // mem - AXIslave
    input wire        En_B,
    input wire        [MEM_NUM_COL-1:0] w_B,r_B,
    input wire        [MEM_ADDR_WIDTH-1:0] addrB,
    input wire        [MEM_COL_WIDTH-1:0] dinB,
    output wire       Data_toggle,
    output wire       [MEM_COL_WIDTH-1:0] doutB,
    // fsm - sie
    input wire        SOF_done,
    input wire        Idle_ready,
    input wire        CRC_error,
    input wire        timeout_error,
    input wire        NAK_received,
    input wire        stall_recieved,
    input wire        UTMI_error,
    input wire        data_toggle_error,
    input wire [5:0]  act_length,
    input wire        errs_ready,   
    input wire        handshake_ready,
    input wire        handshake_error,
    input wire        PID_error,  
    output wire [7:0] PID,
    output wire [6:0] device_address,
    output wire [3:0] endpoint_address,
    output wire       data_toggle,
    output wire       max_length_flag,  
    output wire       PID_ready, 
    output wire       send_SOF_packet,
    output wire       information_ready,
    output wire              SIE_r_en, //read data from SIE means that the data is captured
    // SOF - SIE

    output wire [10:0] frame_num_SIE
    );

// fsm -rxFiFO
//wire [DSIZE-1:0]  fifo_rx_data;
//wire              rx_r_en;
wire              clear_fifo;
wire              empty;
wire              Terminate_reg;
//wire              rx_fifo_full;
// fsm - txFIFO
wire [DSIZE-1:0]  fifo_tx_data;
wire              tx_w_en;
wire              tx_fifo_full;
// mem - fsm
wire En_A;
wire [MEM_NUM_COL-1:0]    w_A;
wire [MEM_ADDR_WIDTH-1:0] mem_addr_A;
wire [MEM_DATA_WIDTH-1:0] mem_data_in_A;
wire [MEM_DATA_WIDTH-1:0] mem_data_out_A;
// fsm - SOFgen
wire sof;
wire pre_sof;
wire TD_done;
// fsm - ErrorLogic
wire HCR_err;
// ErrorLogic - RegFile
wire RS_in;
wire HCPR_reg;
wire HCR_halt_err;
wire en;
// SOF - RegFile
wire        HCR_halt_sof;
wire [3:0]  F_no;
wire        RS;
wire [1:0]  base_address;
wire [3:0]  frame_list_index;


empty empty1(
	.write_enable(SIE_data_w_en),
	.read_enable(SIE_r_en),
	.r_clk(UHCI_clk),
	.w_clk(SIE_clk),
	.rst(rst_n),
	. empty(empty)
);

fifo #(DSIZE,ASIZE) fifo_tx_inst(
    .write_data(fifo_tx_data),
    .write_enable(tx_w_en),
    .write_clk(UHCI_clk),
    .write_rst(rst_n),
    .read_enable(tx_fifo_r_en),
    .read_clk(SIE_clk),
    .read_rst(rst_n),
    .read_data(tx_sie_data),
    .full(tx_fifo_full),
    .empty(tx_fifo_empty),
    .clear(clear_fifo)
 );

dual_memory #(MEM_NUM_COL,MEM_COL_WIDTH,MEM_ADDR_WIDTH,MEM_DATA_WIDTH) mem_inst(
    .clk(UHCI_clk),
    .rst_n(rst_n),
    .En_A(En_A),
    .w_A(w_A),
    .addrA(mem_addr_A),
    .dinA(mem_data_in_A),
    .doutA(mem_data_out_A),
    .En_B(En_B),
    .w_B(w_B),
    .r_B(r_B),
    .addrB(addrB),
    .dinB(dinB),
    .Data_toggle(Data_toggle),
    .doutB(doutB)
);

sof_gen SOFgen_inst(
    .clk(UHCI_clk), 
    .rst_n(rst_n),
    .RS(RS),
    .TD_done(TD_done),
    .sof(sof),
    .pre_sof(pre_sof),
    .f_no(F_no),
    .frame_num_SIE(frame_num_SIE),
    .HCR_halt_sof(HCR_halt_sof)
    );

transactions_fsm  #(b_a_w,f_n_w,MEM_ADDR_WIDTH,MEM_DATA_WIDTH,DSIZE,MEM_NUM_COL) fsm_inst(
    .clk(UHCI_clk),
    .rst(rst_n),
    .SOF(sof),
    .preSOF(pre_sof),
    .base_address(base_address),
    .frame_list_index(frame_list_index),
    .RS_regfile(RS),
    .CRC_error(CRC_error),
    .timeout_error(timeout_error),
    .NAK_received(NAK_received),
    .stall_recieved(stall_recieved),
    .UTMI_error(UTMI_error),
    .data_toggle_error(data_toggle_error),
    .act_length(act_length),
    .fifo_TX_empty(tx_fifo_empty),
    .empty(empty),
    .fifo_TX_full(tx_fifo_full),
    .SIE_data(rx_sie_data),
    .SOF_done(SOF_done),
    .Idle_ready(Idle_ready),
    .errs_ready(errs_ready),   
    .handshake_ready(handshake_ready),
    .memory_data_read(mem_data_out_A),
    .PID(PID),
    .device_address(device_address),
    .endpoint_address(endpoint_address),
    .data_toggle(data_toggle),
    .mem_en_port(En_A),
    .memory_write_enable(w_A),
    .memory_address(mem_addr_A),
    .memory_data_write(mem_data_in_A),
    .max_length_flag(max_length_flag),
    .PID_ready(PID_ready),
    .fifo_TX_data(fifo_tx_data),
    .fifo_TX_enable(tx_w_en),
    .send_SOF_packet(send_SOF_packet),
    .information_ready(information_ready),  
	  .fifo_RX_enable(SIE_r_en),
    .clear_fifo(clear_fifo),
    .HCR_err(HCR_err),
    .handshake_error(handshake_error),
    .PID_error(PID_error),
    .TD_done(TD_done),
    .Terminate_reg(Terminate_reg)
);

Error_logic err_logic_inst(
    .clk(UHCI_clk),
    .rst_n(rst_n),
    .HCR_err(HCR_err),     
    .RS(RS_in),
    .en(en),
    .HCR_halt_err(HCR_halt_err),
    .HCPR_reg(HCPR_reg)      
    );

RegFile Reg_File_inst(
    .clk(UHCI_clk),
    .rst_n(rst_n),
    .RS_in(RS_in),
    .Address(Reg_Address),
    .WrData(Reg_WrData),
    .WrEn(Reg_WrEn),
    .RdEn(Reg_RdEn),
    .RdData(Reg_RdData),
    .en(en),
    .HCR_halt_err(HCR_halt_err),
    .HCR_halt_sof(HCR_halt_sof),
    .HCPR_reg(HCPR_reg),
    .Terminate_reg(Terminate_reg),
    .F_no(F_no),
    .RS(RS),
    .FRNUM(frame_list_index),
    .FLBASEADD(base_address),
    .Data_toggle_RF(Data_toggle_RF)
    );

endmodule
