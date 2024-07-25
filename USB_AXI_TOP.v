module USB_AXI_TOP #(parameter ADDR_W = 32, parameter Data_W = 32, parameter usb_mem_W = 6,parameter DSIZE = 8,parameter ASIZE = 5,b_a_w = 2, f_n_w = 4, 
    MEM_ADDR_WIDTH = 6, MEM_NUM_COL=4, MEM_COL_WIDTH=32, MEM_DATA_WIDTH =MEM_COL_WIDTH*MEM_NUM_COL)
(
//Slave IN
    input                   Clk_axi, Rst,
    input                   R_Valid_Address, Read_Ready,
    input [ADDR_W-1:0]      Read_Address_axi,
    input [2:0]              R_Prot,

    input [ADDR_W-1:0]          Write_Address_axi,
    input [2:0]                W_Prot,
    input                              Write_Valid,
    input [Data_W-1:0]          Write_Data_axi,
    input [3:0]                   Write_Strobe,

//USB IN
    input wire        SIE_clk,
    input wire        UTMI_clk,
    input              DP, DM,

//USB OUT
    output          TX_DP,
    output            TX_DM,
    output        TX_en,

//Slave_outputs
    output                      R_Ready_Address, Valid_Data_R,
    output                       R_Error, Write_Ready, W_Error,
    output [Data_W-1:0]      Read_Data_axi

);


wire                         Reg_WrEn;
wire            [MEM_ADDR_WIDTH-1:0]   Reg_Address;
wire            [7:0]  Reg_WrData;
wire                         Reg_RdEn;
wire            [7:0]  Reg_RdData;
wire        En_B;
wire        [MEM_NUM_COL-1:0] w_B,r_B;
wire   [MEM_ADDR_WIDTH-1:0] addrB;
wire   [MEM_COL_WIDTH-1:0] dinB;
wire                       Data_toggle_Mem;
wire   [MEM_COL_WIDTH-1:0] doutB;
wire                       Data_toggle_RF;
wire                       UHCI_clk;


//AXI Inst.
top_module U0_AXI(
.Clk_axi(Clk_axi),
.Rst(Rst),
.Clk_UHCI(UHCI_clk),
.R_Valid_Address(R_Valid_Address),
.Read_Ready(Read_Ready),
.Read_Address_axi(Read_Address_axi),
.R_Prot(R_Prot),
.Write_Address_axi(Write_Address_axi),
.W_Prot(W_Prot),
.Write_Valid(Write_Valid),
.Write_Data_axi(Write_Data_axi),
.Write_Strobe(Write_Strobe),
.r_data_reg(Reg_RdData),
.r_data_mem(doutB),
.data_reg_toggle(Data_toggle_RF),
.data_mem_toggle(Data_toggle_Mem),
.R_Ready_Address(R_Ready_Address),
.Valid_Data_R(Valid_Data_R),
.R_Error(R_Error),
.Write_Ready(Write_Ready),
.W_Error(W_Error),
.Read_Data_axi(Read_Data_axi),
.w_data_b(dinB),
.addr_b(addrB),
.addr_reg(Reg_Address),
.data_reg(Reg_WrData),
.rd_en_mem(r_B),
.wr_en_mem(w_B),
.rd_en_reg(Reg_RdEn),
.wr_en_reg(Reg_WrEn),
.mem_en(En_B)
    );

USB_top U0_USB(
.SIE_clk(SIE_clk),
.UTMI_clk(UTMI_clk),
.reset(Rst),
.DP(DP),
.DM(DM),
.Reg_WrEn(Reg_WrEn),
.Reg_Address(Reg_Address),
.Reg_WrData(Reg_WrData),
.Reg_RdEn(Reg_RdEn),
.Reg_RdData(Reg_RdData),
.TX_DP(TX_DP),
.TX_DM(TX_DM),
.TX_en(TX_en),
.En_B(En_B),
.w_B(w_B),
.r_B(r_B),
.addrB(addrB),
.dinB(dinB),
.Data_toggle_Mem(Data_toggle_Mem),
.doutB(doutB),
.Data_toggle_RF(Data_toggle_RF),
.UHCI_clk(UHCI_clk)
);

endmodule