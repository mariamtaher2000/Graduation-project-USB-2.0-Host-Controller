//ektbo condition el RS eno lazem lw 3awez y3dl fe el td or el memory 3moman yb2a mn el frame el gded msh fe nos el frame.
module transactions_fsm #(parameter b_a_w = 2, f_n_w = 4, MEM_ADDR_WIDTH = 6, MEM_DATA_WIDTH= 128,
FIFO_DATA_WIDTH=8,MEM_NUM_COL=4) //b_a_w base address width
( 
    input wire    clk,rst,
    input wire    SOF,preSOF,
    input wire    [b_a_w-1 :0] base_address,        //MSBs of base address register
    input wire    [f_n_w-1 :0] frame_list_index,    //MSBs of frame number register
    //input from RegFile
    input wire    RS_regfile,
    //error flags from SIE 
    input wire    handshake_error,
    input wire    PID_error,
    input wire    CRC_error,
    input wire    data_toggle_error,
    input wire    timeout_error,
    input wire    NAK_received,
    input wire    stall_recieved,
    input wire    UTMI_error,
    input wire    [5:0] act_length,
    //fifo in 
    input wire    fifo_TX_empty,
    input wire    empty,// empty means that the data from the sie is read and no data availble to read
    input wire    fifo_TX_full,
//    input wire    fifo_RX_full,
    input wire    [FIFO_DATA_WIDTH-1:0] SIE_data,// data from the SIE
    //SIE input  error flags
    input wire    errs_ready,                     //errors are ready
    input wire    handshake_ready,                //nak/stall ....
    input wire    SOF_done,        
    input wire    Idle_ready,
    //memory and TD
    input wire    [MEM_DATA_WIDTH-1:0] memory_data_read ,
    output reg    [7:0]  PID,
    output reg    [6:0]  device_address,
    output reg    [3:0]  endpoint_address,
    output reg    data_toggle,
    output reg    mem_en_port,
    output reg    [MEM_NUM_COL-1:0]    memory_write_enable,
    output reg    [MEM_ADDR_WIDTH-1:0] memory_address,
    output reg    [MEM_DATA_WIDTH-1:0] memory_data_write,
    //SIE output flags
    output reg    max_length_flag,               //flag -----> 1=>32 , 0=>0
    output reg    PID_ready,
    //FIFO OUT
    output reg    [FIFO_DATA_WIDTH-1:0] fifo_TX_data,
    output reg    fifo_TX_enable,
    output reg    send_SOF_packet,
    output reg    information_ready,             // when the TD information is ready (device address,... )
    output reg    fifo_RX_enable,   
    output reg    clear_fifo,                    // one signal that resets FIFO (tx & rx)
    //error logic output
    output reg    HCR_err,
    //output to SOF_gen
    output reg    TD_done,
    //output to RegFile
    output reg    Terminate_reg
);

reg [3:0] current_state,next_state;

localparam [3:0] wait_for_SOF   = 4'b0000;
localparam [3:0] get_frame_list = 4'b0001;
localparam [3:0] fetch_TD       = 4'b0010;
localparam [3:0] read_memory    = 4'b0011;
localparam [3:0] push_fifo      = 4'b0100;
localparam [3:0] pop_fifo       = 4'b0101;
localparam [3:0] write_memory   = 4'b0110;
localparam [3:0] error_checking = 4'b0111;
localparam [3:0] PID_check      = 4'b1000;
localparam [3:0] Status_Update  = 4'b1001;

//indecies of TD status
localparam [5:0] active        = 55;
localparam [5:0] stalled       = 54;
localparam [5:0] toggle_error  = 53;
localparam [5:0] babble        = 52;
localparam [5:0] NAK           = 51;
localparam [5:0] crc_timeout   = 50;
localparam [5:0] rx_error      = 49;
localparam [5:0] SP_err        = 48;  //SHORT PACKET ERROR
localparam [5:0] HS_err        = 47;
localparam [5:0] PID_err       = 46;

//internal signals
reg [5:0] cntr,cntr_comb;
reg cntr_en;
reg [127:0] TD_comb,TD;
reg TD_en,TD_Status_Update;
reg [10:0] max_length;
reg [27:0] link_pointer;
reg terminate_bit ; 
reg [5:0] buffer_pointer; 
reg [127:0] memory_data_1,memory_data_2;                          //data read/written from memory
reg [127:0] memory_data_1_comb,memory_data_2_comb; 
reg [255:0] memory_data_TX,memory_data_RX,memory_data_RX_comb;
reg memory_data_en_1,memory_data_en_2;
reg memory_data_RX_en;
reg [5:0] TD_address_comb,TD_address;
reg TD_address_en;

// sequential registers
always @(posedge clk or negedge rst)
begin
// when reset all flip flops are zero
    if (!rst)
    begin
        current_state       <= wait_for_SOF;
        cntr                <= 0;
        TD                  <= 0;
        TD_address          <= 0;
        memory_data_1       <= 0;
        memory_data_2       <= 0;
        memory_data_TX      <= 0;
        memory_data_RX      <= 0;
        Terminate_reg       <= 0;
    end
    else
    begin
        if (cntr_en) begin
            cntr <= cntr_comb;
        end
        if (TD_en) begin
            TD <= TD_comb;
        end
        else if (TD_Status_Update) begin
        //only load the 32 status bits as I dont want to change the device address,endpoint address,data toggle,.... and the rest of the outputs.           
            TD[63:32] <= TD_comb[63:32];
        end
        if (memory_data_en_1) begin
            memory_data_1 <= memory_data_1_comb;
        end
        if (current_state == Status_Update) begin
            Terminate_reg <= terminate_bit || TD[babble] || TD[stalled];
        end
        if (memory_data_en_2) begin
            memory_data_2 <= memory_data_2_comb;
        end
        if (memory_data_RX_en) begin
            memory_data_RX <= memory_data_RX_comb;
        end
        if (TD_address_en) begin
            TD_address <= TD_address_comb;
        end
        current_state  <= next_state;
        memory_data_TX <= {memory_data_2,memory_data_1};
    end
end

//combinational block
always @(*)
begin
    // Default values of outputs.
    //TD Ouptuts
    PID              = TD[71:64];
    link_pointer     = TD[31:4];
    terminate_bit    = TD[0];
    buffer_pointer   = TD[101:96]; 
    device_address   = TD[78:72];
    endpoint_address = TD[82:79];
    data_toggle      = TD[83];
    max_length       = TD[95:85];
    HCR_err          = 0;
    clear_fifo       = 0;
    //fifo and memory
    max_length_flag          = (max_length == 'h7ff)?0:1;
    memory_write_enable      = 0;
    memory_address           = 0;
    memory_data_write        = 0;
    fifo_TX_data             = 0;
    fifo_TX_enable           = 0;
    send_SOF_packet          = 0;
    information_ready        = 0;
    mem_en_port              = 0;
    fifo_RX_enable           = 0;
    //registers
    TD_comb             = 0;
    TD_address_en       = 0;
    TD_address_comb     = 0;
    memory_data_RX_comb = memory_data_RX;
    memory_data_RX_en   = 0;
    memory_data_en_1    = 0;
    memory_data_en_2    = 0;
    memory_data_1_comb  = 0;
    memory_data_2_comb  = 0;
    TD_en               = 0;
    TD_Status_Update    = 0;
    cntr_comb           = 0;
    cntr_en             = 0;

    TD_done             = 0;
    //next state logic
    case (current_state)
    ///////////////////////////////////////////////////////////
//in wait for SOF the fsm waits entil the SOF signal is 1 and moves to get frame list state 
//and sets send_SOF_packet to 1 for SIE to send the start of frame packet 
    wait_for_SOF:   begin
        TD_done   = 1;
        PID_ready = 0;
        cntr_comb = 0;
        cntr_en   = 1;
        if(SOF) begin
            next_state      = get_frame_list;
            send_SOF_packet = 1;
        end
        else begin
            next_state      = wait_for_SOF;
            send_SOF_packet = 0;
        end
    end
    ///////////////////////////////////////////////////////////
//in this state the FSM gets the frame list from the base address+frame index by reading it from memory
//it checks on the terminate bit if 1 returns to wait for SOF state, otherwise it fetches the first TD
    get_frame_list: begin
        PID_ready           = 0;
        memory_write_enable = 0;
        mem_en_port         = 1;
        TD_done   =1;
        //first cycle
        if (!RS_regfile) begin
            next_state = wait_for_SOF;
        end
        else if (cntr == 0) begin
            memory_address = {base_address,frame_list_index};   //get FLP
            next_state     = get_frame_list;
            cntr_comb      = cntr + 1;
            cntr_en        = 1;
        end
        else if (cntr == 1) begin
            if (memory_data_read[0]) begin      
                next_state = wait_for_SOF;
                cntr_comb  = 0;
                cntr_en    = 1;
            end
            else begin
            //it gets the address of the next TD to be fetched from the frame list pointer (in the memory)
            //it also fetches the first TD and stores it in TD register
            //and moves to the next state PID check
                TD_address_comb = memory_data_read[9:4]; 
                TD_address_en   = 1;
                memory_address  = memory_data_read[9:4];        //get TD
                cntr_comb       = cntr + 1;
                cntr_en         = 1;
                next_state      = get_frame_list;   
            end
        end
        else if(cntr == 2) begin
            TD_comb = memory_data_read;
            TD_en   = 1;
            if (SOF_done) begin
                cntr_comb  = 0;
                cntr_en    = 1;
                next_state = PID_check;
            end else begin
                cntr_comb  = cntr + 1;
                cntr_en    = 1;
                next_state = get_frame_list;
            end
        end else begin
            if (SOF_done) begin
                cntr_comb  = 0;
                cntr_en    = 1;
                next_state = PID_check;
            end else begin
                cntr_comb  =cntr;
                cntr_en    = 1;
                next_state = get_frame_list;
            end
        end
    end
    ///////////////////////////////////////////////////////////
//in this state it decodes the needed info from the TD 
//sets PID ready  and information ready to 1 for SIE 
//according to the PID it moves to the next state
//if the data length is NULL it oves to the error checking state
//in case invalid PID it sets the host controller error to 1 and moves to the wait for SOF state to wait for a new frame 
    PID_check:begin
        //outputs
        if (Idle_ready) begin
            PID_ready = 1;
            information_ready = 1;
                if ((PID == 8'b11100001)  || (PID == 8'b00101101))     //out or setup  token
                    begin
                    if (&(max_length)) begin                           //max_length = 0x7FF ----> Null Packet
                        next_state      = error_checking;
                        end
                    else begin
                        next_state      = read_memory;
                        end
                    end
                else if ((PID == 8'b01101001))                         //IN  token
                    begin

                    if (&(max_length)) begin                           //max_length = 0x7FF ----> Null Packet
                        next_state      = error_checking;
                        end
                    else begin
                        next_state      = pop_fifo;
                        end
                end
                else begin                                             //illegal PID
                    information_ready = 0;
                    HCR_err           = 1;
                    PID_ready         = 0;
                    next_state        = wait_for_SOF;
                end  
        end
        else begin
            PID_ready = 0;
            information_ready = 0;
            next_state        = PID_check;
        end
        
    end
    ///////////////////////////////////////////////////////////
//in case of OUT transaction it reads the data from the memory assdress indicated by the buffer pointer of the TD
//data needs 2 clock cycles to be read from memory
//and then moeves to the push fifo state to put the data in fifo
    read_memory:begin
        PID_ready           = 0;
        information_ready   = 1;
        mem_en_port         = 1;
        memory_write_enable = 0;
        cntr_en             = 0;
        cntr_comb           = 0;
        if (cntr == 0) begin
            memory_address = buffer_pointer[5:0];
            cntr_comb      = cntr + 1;
            cntr_en        = 1;
            next_state     = read_memory;
        end
        else if (cntr == 1) begin
            memory_data_1_comb = memory_data_read;
            memory_address     = buffer_pointer[5:0] + 1;
            memory_data_en_1   = 1;
            cntr_en            = 1;
            cntr_comb          = cntr + 1;
            next_state         = read_memory;
        end
        else begin
            memory_data_2_comb = memory_data_read;
            memory_data_en_2   = 1;
            cntr_en            = 1;
            cntr_comb          = 0;
            next_state         = push_fifo;
        end
    end
    ///////////////////////////////////////////////////////////
//it puts the data in the fifo and sets data out ready to 1 for SIE
    push_fifo:begin
        PID_ready                = 0;
        information_ready        = 1;
        fifo_TX_enable           = 1;
        if (cntr < 31) begin
            fifo_TX_data = memory_data_TX[8*cntr +: 8];
            cntr_comb    = cntr + 1;
            cntr_en      = 1;
            next_state   = push_fifo;
        end
        else begin
            fifo_TX_data = memory_data_TX[8*cntr +: 8];
            cntr_comb    = 0;
            cntr_en      = 1;
            next_state   = error_checking;
        end
    end
    ///////////////////////////////////////////////////////////
//in case of IN transactions it takes the data from fifo when it is ready and stores it in memory_data_RX register
//and moves to the write data in memory state 
    pop_fifo:begin
        PID_ready = 0;
        information_ready = 1;
        //if there is timeout error no data will be poped from the fifo and will update the status in the TD and moves to status update state
        if (errs_ready && timeout_error) begin
            memory_data_RX_comb  = 0;
            fifo_RX_enable       = 0;
            memory_data_RX_en    = 1;
            cntr_comb            = 0;
            cntr_en              = 1;
            //updating td timeout error field.
            TD_Status_Update     = 1;
            TD_comb[crc_timeout] = timeout_error;
            TD_comb [42:32]      = 11'b0;      //actual length will be = 0 since we didnt store any data in the memory
            next_state           = Status_Update;
        end
         else if (errs_ready && PID_error) begin
            memory_data_RX_comb  = 0;
            fifo_RX_enable       = 0;
            memory_data_RX_en    = 1;
            cntr_comb            = 0;
            cntr_en              = 1;
            //updating pid error field
            TD_Status_Update     = 1;
            TD_comb[PID_err] = PID_error;
            TD_comb [42:32]      = 11'b0;      //actual length will be = 0 since we didnt store any data in the memory
            next_state           = Status_Update;
        end
        else if (errs_ready && data_toggle_error) begin
            memory_data_RX_comb  = 0;
            fifo_RX_enable       = 0;
            memory_data_RX_en    = 1;
            cntr_comb            = 0;
            cntr_en              = 1;
            //updating data toggle error field.
            TD_Status_Update      = 1;
            TD_comb[toggle_error] = data_toggle_error;
            TD_comb [42:32]       = 11'b0;      //actual length will be = 0 since we didnt store any data in the memory
            next_state            = Status_Update;
        end
        else if (errs_ready && UTMI_error) begin
            memory_data_RX_comb  = 0;
            fifo_RX_enable       = 0;
            memory_data_RX_en    = 1;
            cntr_comb            = 0;
            cntr_en              = 1;
            //updating td rx_error field.
            TD_Status_Update     = 1;
            TD_comb[rx_error]    = UTMI_error;
            TD_comb [42:32]      = 11'b0;      //actual length will be = 0 since we didnt store any data in the memory
            next_state           = Status_Update;
            end
          else if (errs_ready && (act_length < 'd32) && empty) begin
            memory_data_RX_comb = 'b0;
            fifo_RX_enable       = 0;
            memory_data_RX_en    = 0;
            cntr_comb            = 0;
            cntr_en              = 1;
            next_state           =  write_memory;
            end
        else begin
            if (cntr == 31 && !empty) begin
                memory_data_RX_comb [8*(cntr) +: 8] = SIE_data;
                fifo_RX_enable    = 1;
                memory_data_RX_en = 1;
                cntr_comb         = 0;
                cntr_en           = 1;
                next_state        = write_memory;
            end else if (!empty) begin         
                    memory_data_RX_comb [8*(cntr) +: 8] = SIE_data;
                    fifo_RX_enable    = 1;
                    memory_data_RX_en = 1;
                    cntr_comb         = cntr + 1;
                    cntr_en           = 1;
                    next_state        = pop_fifo;
             end else begin
                memory_data_RX_comb = 0;
                memory_data_RX_en   = 0;
                cntr_comb           = 0;
                cntr_en             = 0;
                next_state          = pop_fifo;
            end
            
        end
        end
    ///////////////////////////////////////////////////////////
//it writes the data stored in the memory_data_RX reg in the memory in the location of the buffer pointer 
    write_memory:begin
        PID_ready = 0;
        information_ready = 1;
        if (cntr == 0) begin
            memory_address      = buffer_pointer[5:0];
            memory_write_enable = 4'b1111;
            memory_data_write   = memory_data_RX[127:0];
            mem_en_port         = 1;
            cntr_comb           = cntr+1;
            cntr_en             = 1;
            next_state          = write_memory;
        end
        else begin
            memory_address      = buffer_pointer[5:0] + 1;
            memory_write_enable = 4'b1111;
            memory_data_write   = memory_data_RX[255:128];
            mem_en_port         = 1;
            cntr_comb           = 0;
            cntr_en             = 1;
            next_state          = error_checking;
        end
        end
    ///////////////////////////////////////////////////////////
    error_checking:begin
        PID_ready = 0;
        //information ready flag will only be 0 when we enter the Status_Update stage to inform SIE that we got the errors.
        information_ready        = 1;
        //if the errors are ready it updates the error bits in the TD and the actual length
        //if the handshake is ready it updates the handshake bits in the TD
        if (errs_ready) begin
            TD_comb[active]       = 0;
            TD_comb[crc_timeout]  = CRC_error | timeout_error;
            TD_comb[rx_error]     = UTMI_error;
            TD_comb[babble]       = (act_length > max_length[5:0]);
            TD_comb[stalled]      = (act_length > max_length[5:0]);
            TD_comb[toggle_error] = 0;
            TD_comb[SP_err]       = (&(max_length))? 0:(act_length < max_length[5:0]);
            TD_Status_Update      = 1;       
            TD_comb [42:32]       = (&(max_length))? 11'h7ff : 11'b0 + act_length;    //actual length
            next_state            = Status_Update;
        end
        else if (handshake_ready) begin 
            TD_comb[active]       = (NAK_received)? 1:0;
            TD_comb[stalled]      = stall_recieved | (act_length > max_length[5:0]);
            TD_comb[crc_timeout]  = timeout_error | stall_recieved;                   //timeout error only 
            TD_comb[NAK]          = NAK_received;
            TD_comb[rx_error]     = UTMI_error;
            TD_comb[toggle_error] = 0;
            TD_Status_Update      = 1;       
            TD_comb [42:32]       = max_length;                                       //actual length
            TD_comb[HS_err]       = handshake_error;
            next_state            = Status_Update;
        end
        else begin
            next_state = error_checking;
        end
        end
    ///////////////////////////////////////////////////////////
//it stores the status un the TD location in the memory
    Status_Update:begin
        PID_ready           = 0;
        clear_fifo          = 1;
        memory_address      = TD_address;
        memory_write_enable = 4'b0010;                                               // to wite 1 word only 
        memory_data_write   = TD;
        mem_en_port         = 1;
        memory_data_RX_en = 'b1;
        memory_data_RX_comb = 'b0;
        TD_done =1;
        if (!RS_regfile) begin
            next_state = wait_for_SOF;
        end
        //next TD
        //if the terminate bite is 1 or presof signal is one it waites for new frame else it fetches new TD
        else if (terminate_bit || preSOF || TD[babble] || TD[stalled]) begin  
        //if run/stop bit is 0 (stop) we complete transaction and then go wait for another SOF
            next_state = wait_for_SOF;
        end
        else begin
            next_state = fetch_TD;
        end
        end
    ///////////////////////////////////////////////////////////
//it fetches the next TD from the link pointer of the previous TD
    fetch_TD: begin
        TD_done   =1;
        PID_ready = 0;
        if (!RS_regfile) begin
            next_state = wait_for_SOF;
        end
        else if (cntr == 0) begin
            TD_address_comb     = link_pointer;
            TD_address_en       = 1;
            memory_address      = link_pointer;
            mem_en_port         = 1;
            memory_write_enable = 0;
            cntr_comb           = cntr + 1;
            cntr_en             = 1;
            next_state          = fetch_TD;
        end
        else begin
            TD_comb    = memory_data_read;
            TD_en      = 1;
            cntr_comb  = 0;
            cntr_en    = 1;
            next_state = PID_check;
        end
    end
    default:begin
        PID_ready  = 0;
        next_state = wait_for_SOF;
    end
    endcase
end

endmodule
