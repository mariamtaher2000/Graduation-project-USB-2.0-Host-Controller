module sof_gen(
    input clk, // 12 MHz
    input rst_n,// normal operation
    input RS,
    input TD_done,

    output reg HCR_halt_sof,    //regfile
    output reg sof,
    output reg pre_sof,
    output reg [3:0] f_no,
    output reg [10:0] frame_num_SIE
    );

//________________________regs__________________________//
reg [10:0] frame_cntr_r,frame_cntr_nx;
reg [13:0] sof_cntr_r,sof_cntr_nx;
reg pre_sof_nx;
reg RS_r;

//____________________parameters________________________//

parameter SOF_CNTR_VALUE = 14'd12000;
parameter PRESOF_TIME    = 14'd256;                     //Data Packet time.
parameter FRAME_NO_ADDR  = 3'd3;

//____________________wires________________________//
wire RS_posedge;

//______________sequential always block_________________//
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        frame_cntr_r <= 11'b0;
        sof_cntr_r   <= 14'b0;
        pre_sof      <= 1'b0;
        RS_r         <= 1'b0;
    end
    else begin
        frame_cntr_r <= frame_cntr_nx;
        sof_cntr_r   <= sof_cntr_nx;
        pre_sof      <= pre_sof_nx;
        RS_r         <= RS;
    end
end

//_____________combinational always block________________//
always @(*) begin
    HCR_halt_sof = 1'b0;
    if (!RS && TD_done) begin
        sof = 1'b0;
        HCR_halt_sof = 1'b1;
        frame_cntr_nx   = frame_cntr_r;
        sof_cntr_nx     = sof_cntr_r;
        f_no = frame_cntr_r[3:0];
        frame_num_SIE = frame_cntr_r;
    end
    else if ((sof_cntr_r == SOF_CNTR_VALUE - 14'b1) || RS_posedge) begin
        sof = 1'b1;
        frame_cntr_nx   = frame_cntr_r +11'b1;
        sof_cntr_nx     = 14'b0;
        f_no = frame_cntr_r[3:0];
        frame_num_SIE = frame_cntr_r;
    end
    else begin
        sof = 1'b0;
        sof_cntr_nx     = sof_cntr_r + 14'b1;
        frame_cntr_nx   = frame_cntr_r;
        f_no = frame_cntr_r[3:0];
        frame_num_SIE = frame_cntr_r;
    end

    if (sof_cntr_r < (SOF_CNTR_VALUE - PRESOF_TIME - 14'b1)) begin
        pre_sof_nx = 1'b0;
    end
    else begin
        pre_sof_nx = 1'b1;
    end

end

//____________________assignments________________________//
assign RS_posedge = (RS && !RS_r)? 1:0;
endmodule
