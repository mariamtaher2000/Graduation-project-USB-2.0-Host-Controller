module dual_memory_tb();
  
`timescale 1ns/1ps

parameter   NUM_COL    =  4;
parameter   COL_WIDTH  =  32;
parameter   ADDR_WIDTH =  6;
parameter   DATA_WIDTH =  NUM_COL*COL_WIDTH; 

reg clk_tb;
reg rst_n_tb;
reg En_A_tb;
reg [NUM_COL-1:0] w_A_tb;
reg [ADDR_WIDTH-1:0] addrA_tb;
reg [DATA_WIDTH-1:0] dinA_tb;
wire [DATA_WIDTH-1:0] doutA_tb;
reg En_B_tb;
reg [NUM_COL-1:0] w_B_tb;
reg [NUM_COL-1:0] r_B_tb;
reg [ADDR_WIDTH-1:0] addrB_tb;
reg [COL_WIDTH-1:0] dinB_tb;
wire [COL_WIDTH-1:0] doutB_tb;


dual_memory DUT(
.clk(clk_tb),
.rst_n(rst_n_tb),
.En_A(En_A_tb),
.w_A(w_A_tb),
.addrA(addrA_tb),
.dinA(dinA_tb),
.doutA(doutA_tb),
.En_B(En_B_tb),
.w_B(w_B_tb),
.r_B(r_B_tb),
.addrB(addrB_tb),
.dinB(dinB_tb),
.doutB(doutB_tb)
);

always #10 clk_tb = ~clk_tb;


initial 
begin

rst_n_tb = 1;
#1;
rst_n_tb = 0;
#1;
rst_n_tb = 1;

//initial values
{clk_tb,En_A_tb,En_B_tb,w_A_tb,w_B_tb,r_B_tb,addrA_tb,addrB_tb,dinA_tb,dinB_tb} <='b0;

//test cases
@(posedge clk_tb);
$display ("TEST Port A") ;  
Port_A_Write();

@(posedge clk_tb);
$display ("TEST Port B") ;  
Port_B_Write();
//Port_B_read();

#50
$stop ;
end


task Port_A_Write ();
    begin
        En_A_tb= 'b1;
        w_A_tb = 'b0001;
        addrA_tb = 'b0;
        dinA_tb = {32'b1,32'b1,32'b1,32'b1};


        @(posedge clk_tb);
        w_A_tb = 'b0010;

        @(posedge clk_tb);
        w_A_tb = 'b0100;
    
        @(posedge clk_tb);
        w_A_tb = 'b1000;

        @(posedge clk_tb);
        w_A_tb = 'b0000;
        repeat(2) @(posedge clk_tb);
        if(doutA_tb == dinA_tb )
        $display ("writing All DWord Successfully ") ;
        else
        $display ("writing All DWord FAILED ") ;

    end
endtask



task Port_B_Write ();
    begin
        En_B_tb= 'b1;
        addrB_tb = 'b1;
        dinB_tb = 32'b1;
        w_B_tb = 'b0001;
        @(posedge clk_tb);
        r_B_tb = 'b0001;
        repeat(2) @(posedge clk_tb);
        $display ("doutB = %b",doutB_tb);
        if(doutB_tb == dinB_tb )
        $display ("writing/reading 1st DWord Successfully ") ;
        else
        $display ("writing/reading 1st DWord FAILED ") ;
        
        @(posedge clk_tb);
        dinB_tb = 32'b11;
        w_B_tb = 'b0010;
        @(posedge clk_tb);
        r_B_tb = 'b0010;
        repeat(2) @(posedge clk_tb);
        $display ("doutB = %b",doutB_tb);
        if(doutB_tb == dinB_tb )
        $display ("writing/reading 2nd DWord Successfully ") ;
        else
        $display ("writing/reading 2nd DWord FAILED ") ;
       
        @(posedge clk_tb);
        dinB_tb = 32'b111;
        w_B_tb = 'b0100;
        @(posedge clk_tb);
        r_B_tb = 'b0100;
        repeat(2) @(posedge clk_tb);
        $display ("doutB = %b",doutB_tb);
        if(doutB_tb == dinB_tb )
        $display ("writing/reading 3rd DWord Successfully ") ;
        else
        $display ("writing/reading 3rd DWord FAILED ") ;

        @(posedge clk_tb);
        dinB_tb = 32'b1111;
        w_B_tb = 'b1000;
        @(posedge clk_tb);
        r_B_tb = 'b1000;
        repeat(2) @(posedge clk_tb);
        $display ("doutB = %b",doutB_tb);
        if(doutB_tb == dinB_tb )
        $display ("writing/reading 4th DWord Successfully ") ;
        else
        $display ("writing/reading 4th DWord FAILED ") ;

        @(posedge clk_tb);
        En_B_tb= 'b1;
        addrB_tb = 'd2;
        dinB_tb = 32'b1;
        w_B_tb = 'b0001;
        @(posedge clk_tb);
        r_B_tb = 'b0001;
        repeat(2) @(posedge clk_tb);
        $display ("doutB = %b",doutB_tb);
        if(doutB_tb == dinB_tb )
        $display ("writing/reading 1st DWord Successfully ") ;
        else
        $display ("writing/reading 1st DWord FAILED ") ;
       
    

    end
endtask
/*
task Port_B_read ();
    begin
    dinB_tb= {32'b0,32'b1,32'b11,32'b111};
    addrB_tb=6'b111111;
    w_B_tb='b1111;
    @(posedge clk_tb);
    r_B_tb = 'b0001;
    @(posedge clk_tb);
    #2
    if(doutB_tb[31:0] == dinB_tb[31:0] )
    $display ("Reading 1st DWord Successfully" ) ;
    else
    $display ("Reading 1st DWord FAILED"   ) ;

    @(posedge clk_tb);
    r_B_tb = 'b0010;
    @(posedge clk_tb);
    #2
    if(doutB_tb[63:32] == dinB_tb[63:32])                                               //********************************
    $display ("Reading 2nd DWord Successfully ") ;
    else
    $display ("Reading 2nd DWord FAILED"  ) ;

    @(posedge clk_tb);
    r_B_tb = 'b0100;
    @(posedge clk_tb);
    #2
    if(doutB_tb[95:64] == dinB_tb[95:64] )
    $display ("Reading 3rd DWord Successfully ") ;
    else
    $display ("Reading 3rd DWord FAILED"  ) ;
    
    @(posedge clk_tb);
    r_B_tb = 'b1000;
    @(posedge clk_tb);
    #2
    if(doutB_tb[127:96] == dinB_tb[127:96] )
    $display ("Reading 4th DWord Successfully ") ;
    else
    $display ("Reading 4th DWord FAILED"  ) ;

    end
endtask*/

endmodule

  
