module snn_top #(
parameter ACT_PER_ADDR = 1,
parameter BW_PER_ACT = 1
)
(
    input                  clk,          // clock input
    input                  srstn,        // synchronous reset (active low)
    input                  encode_input, // encode input
    input                  en_compute_FC1, // finaish load input data
    input                  en_compute_FC2, // start compute layer2


    //write enable for SRAM A,B (active low)
    output reg sram_wen_a,  
    output reg sram_wen_b,
      
    // read/write address from SRAM A,B (read=1, write=0)
    output reg [20:0] sram_addr_a,  
    output reg [9:0] sram_addr_b,
    
    // read data from SRAM A,B
    input [ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a, 
    input [ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b,
    
    // write data to SRAM A,B
    output reg [ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
    output reg [ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b,


    input [17:0]                              sram_raddr_weight, //read address from SRAM weight  
    input [7:0]                               sram_rdata_weight, //read data from SRAM weight
    output reg                                en_compute_FC1_finish,
    output reg                                en_compute_FC2_finish 

);

reg spike;
wire spike_t0;
wire spike_t1;

reg spike_l2;
wire spike_t0_l2;
wire spike_t1_l2;

reg en_spike;
reg en_spike_l2;

wire signed [20:0] pastmem;
reg signed [20:0] pastmem_t1;
wire signed [20:0] pastmem_now;
reg signed [20:0] pastmem_timestep [0:3499];

wire signed [20:0] pastmem_l2;
reg signed [20:0] pastmem_t1_l2;
wire signed [20:0] pastmem_now_l2;
reg signed [20:0] pastmem_timestep_l2 [0:349];

reg [10:0] count_en_spike = 0; // 0-783
reg [10:0] count_en_spike_l2 = 0; // 0-99

reg [10:0] count_pastmem = 0; // 0-99
reg [10:0] count_pastmem_l2 = 0; // 0-9

reg [5:0] timestep_layer1 = 0; // 0-34
reg [5:0] timestep_layer2 = 0; // 0-34

reg [20:0] count_timestep = 0; // 0-78399 in each timestep
reg [20:0] count_timestep_l2 = 0; // 0-3499 in each timestep

reg [20:0] count_addr_A = 0; // 0-3499 for 100 images
reg [20:0] count_addr_B = 0; // 0-314 for 100 images
reg [20:0] count_addr_A_for_B = 1;

reg [20:0] count_addr_A_check_ans = 1;
reg [20:0] count_addr_B_check_ans = 1;
 
FC1 fc1(.clk(clk),
        .count_addr_A(count_addr_A),
        .encode_input(encode_input),
        .sram_rdata_weight(sram_rdata_weight),
        .spike(spike_t0),
        .pastmem(pastmem));

FC1_t1 fc1_t1(.clk(clk),
              .count_addr_A(count_addr_A),
              .encode_input(encode_input),
              .sram_rdata_weight(sram_rdata_weight),
              .pastmem(pastmem_t1),
              .spike(spike_t1),
              .pastmem_now(pastmem_now));

FC2 fc2(.clk(clk),
        .en_compute_FC2(en_compute_FC2),
        .count_addr_B(count_addr_B),
        .sram_rdata_a(sram_rdata_a),
        .sram_rdata_weight(sram_rdata_weight),
        .spike_l2(spike_t0_l2),
        .pastmem_l2(pastmem_l2));

FC2_t1 fc2_t1(.clk(clk),
              .en_compute_FC2(en_compute_FC2),
              .count_addr_B(count_addr_B),
              .sram_rdata_a(sram_rdata_a),
              .sram_rdata_weight(sram_rdata_weight),
              .pastmem_l2(pastmem_t1_l2),
              .spike_l2(spike_t1_l2),
              .pastmem_now_l2(pastmem_now_l2));

always @(count_timestep)
begin
    if(timestep_layer1 == 0 && en_compute_FC1)
        spike = spike_t0;
    else
        spike = spike_t1;    
end

always @(count_timestep_l2)
begin
    if(timestep_layer2 == 0 && en_compute_FC2)
        spike_l2 = spike_t0_l2;
    else
        spike_l2 = spike_t1_l2;    
end

always @(*)
begin
    if(count_en_spike == 783)
        en_spike = 1;
    else
        en_spike = 0;
end

always @(*)
begin
    if(count_en_spike_l2 == 99)
        en_spike_l2 = 1;
    else
        en_spike_l2 = 0;
end

always @(*)
begin
    if(en_spike && timestep_layer1 == 0)
    begin
        pastmem_timestep[count_addr_A] = pastmem;
    end
    else if(en_spike && timestep_layer1 != 0)
    begin
        pastmem_t1 = pastmem_timestep[count_addr_A - 100];
        pastmem_timestep[count_addr_A] = pastmem_now;
    end
end

always @(*)
begin
    if(en_spike_l2 && timestep_layer2 == 0)
    begin
        pastmem_timestep_l2[count_addr_B] = pastmem_l2;
    end
    else if(en_spike_l2 && timestep_layer2 != 0)
    begin
        pastmem_t1_l2 = pastmem_timestep_l2[count_addr_B - 10];
        pastmem_timestep_l2[count_addr_B] = pastmem_now_l2;
    end
end

always @(posedge clk) // 0-99
begin
    if(en_spike)
    begin
        if(count_pastmem == 99)
            #(1) count_pastmem <= 0;
        else
            #(1) count_pastmem <= count_pastmem + 1;
    end
end

always @(posedge clk) // 0-9
begin
    if(en_spike_l2)
    begin
        if(count_pastmem_l2 == 9)
            #(1) count_pastmem_l2 <= 0;
        else
            #(1) count_pastmem_l2 <= count_pastmem_l2 + 1;
    end
end

always @(posedge clk) // 0-783
begin
    if(en_compute_FC1 && !en_compute_FC1_finish)
    begin
        if(count_en_spike < 783)
            #(1) count_en_spike <= count_en_spike + 1;
        else
            #(1) count_en_spike <= 0;
    end
end

always @(posedge clk) // 0-99
begin
    if(en_compute_FC2 && !en_compute_FC2_finish)
    begin
        if(count_en_spike_l2 < 99)
            #(1) count_en_spike_l2 <= count_en_spike_l2 + 1;
        else
            #(1) count_en_spike_l2 <= 0;
    end
end

always @(posedge clk) // 0-78399 in each timestep (784*100 - 1)
begin
    if(en_compute_FC1 && !en_compute_FC1_finish)
    begin
        if(count_timestep < 78399 + 784)
            #(1) count_timestep <= count_timestep + 1;
        else
            #(1) count_timestep <= 0;
    end
end

always @(posedge clk) // 0-999 in each timestep (100*10 - 1)
begin
    if(en_compute_FC2 && !en_compute_FC2_finish)
    begin
        if(count_timestep_l2 < 999 + 100)
            #(1) count_timestep_l2 <= count_timestep_l2 + 1;
        else
            #(1) count_timestep_l2 <= 0;
    end
end

always @(posedge clk) // 0-34
begin
    if(count_timestep == 78399 + 784)
    begin
        if(timestep_layer1 < 35)
            #(1) timestep_layer1 <= timestep_layer1 + 1;
        else 
            #(1) timestep_layer1 <= 0;
    end
end

always @(posedge clk) // 0-34
begin
    if(count_timestep_l2 == 999 + 100)
    begin
        if(timestep_layer2 < 35)
            #(1) timestep_layer2 <= timestep_layer2 + 1;
        else 
            #(1) timestep_layer2 <= 0;
    end
end


always @(posedge clk) // 0-3499
begin
    if(en_spike)
    begin
        if(count_addr_A == 100)
            #(1) count_addr_A <= count_addr_A + 1;
        else
            #(1) count_addr_A <= count_addr_A + 1;
    end
end

always @(posedge clk)
begin
    if(en_compute_FC2)
    begin
        if(timestep_layer2 == 0)
        begin
            if(count_addr_A_for_B == 101)
                #(1) count_addr_A_for_B <= 2;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 1)
        begin
            if(count_addr_A_for_B == 201)
                #(1) count_addr_A_for_B <= 102;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 2)
        begin
            if(count_addr_A_for_B == 301)
                #(1) count_addr_A_for_B <= 202;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 3)
        begin
            if(count_addr_A_for_B == 401)
                #(1) count_addr_A_for_B <= 302;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 4)
        begin
            if(count_addr_A_for_B == 501)
                #(1) count_addr_A_for_B <= 402;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 5)
        begin
            if(count_addr_A_for_B == 601)
                #(1) count_addr_A_for_B <= 502;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 6)
        begin
            if(count_addr_A_for_B == 701)
                #(1) count_addr_A_for_B <= 602;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 7)
        begin
            if(count_addr_A_for_B == 801)
                #(1) count_addr_A_for_B <= 702;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 8)
        begin
            if(count_addr_A_for_B == 901)
                #(1) count_addr_A_for_B <= 802;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 9)
        begin
            if(count_addr_A_for_B == 1001)
                #(1) count_addr_A_for_B <= 902;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 10)
        begin
            if(count_addr_A_for_B == 1101)
                #(1) count_addr_A_for_B <= 1002;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 11)
        begin
            if(count_addr_A_for_B == 1201)
                #(1) count_addr_A_for_B <= 1102;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 12)
        begin
            if(count_addr_A_for_B == 1301)
                #(1) count_addr_A_for_B <= 1202;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 13)
        begin
            if(count_addr_A_for_B == 1401)
                #(1) count_addr_A_for_B <= 1302;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 14)
        begin
            if(count_addr_A_for_B == 1501)
                #(1) count_addr_A_for_B <= 1402;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 15)
        begin
            if(count_addr_A_for_B == 1601)
                #(1) count_addr_A_for_B <= 1502;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 16)
        begin
            if(count_addr_A_for_B == 1701)
                #(1) count_addr_A_for_B <= 1602;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 17)
        begin
            if(count_addr_A_for_B == 1801)
                #(1) count_addr_A_for_B <= 1702;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 18)
        begin
            if(count_addr_A_for_B == 1901)
                #(1) count_addr_A_for_B <= 1802;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 19)
        begin
            if(count_addr_A_for_B == 2001)
                #(1) count_addr_A_for_B <= 1902;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 20)
        begin
            if(count_addr_A_for_B == 2101)
                #(1) count_addr_A_for_B <= 2002;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 21)
        begin
            if(count_addr_A_for_B == 2201)
                #(1) count_addr_A_for_B <= 2102;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 22)
        begin
            if(count_addr_A_for_B == 2301)
                #(1) count_addr_A_for_B <= 2202;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 23)
        begin
            if(count_addr_A_for_B == 2401)
                #(1) count_addr_A_for_B <= 2302;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 24)
        begin
            if(count_addr_A_for_B == 2501)
                #(1) count_addr_A_for_B <= 2402;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 25)
        begin
            if(count_addr_A_for_B == 2601)
                #(1) count_addr_A_for_B <= 2502;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 26)
        begin
            if(count_addr_A_for_B == 2701)
                #(1) count_addr_A_for_B <= 2602;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 27)
        begin
            if(count_addr_A_for_B == 2801)
                #(1) count_addr_A_for_B <= 2702;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 28)
        begin
            if(count_addr_A_for_B == 2901)
                #(1) count_addr_A_for_B <= 2802;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 29)
        begin
            if(count_addr_A_for_B == 3001)
                #(1) count_addr_A_for_B <= 2902;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 30)
        begin
            if(count_addr_A_for_B == 3101)
                #(1) count_addr_A_for_B <= 3002;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 31)
        begin
            if(count_addr_A_for_B == 3201)
                #(1) count_addr_A_for_B <= 3102;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 32)
        begin
            if(count_addr_A_for_B == 3301)
                #(1) count_addr_A_for_B <= 3202;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 33)
        begin
            if(count_addr_A_for_B == 3401)
                #(1) count_addr_A_for_B <= 3302;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
        else if(timestep_layer2 == 34)
        begin
            if(count_addr_A_for_B == 3501)
                #(1) count_addr_A_for_B <= 3402;
            else
                #(1) count_addr_A_for_B <= count_addr_A_for_B + 1;
        end
    end
end

always @(posedge clk) // 0-349
begin
    if(en_spike_l2)
    begin
        if(count_addr_B == 9)
            #(1) count_addr_B <= count_addr_B + 1;
        else
            #(1) count_addr_B <= count_addr_B + 1;
    end
end

always @(*) // finish compute FC1
begin
    if(count_addr_A > 3500 + 1)
        en_compute_FC1_finish = 1;
    else
        en_compute_FC1_finish = 0;    
end

always @(*) // finish compute FC2
begin
    if(count_addr_B > 350 + 1)
        en_compute_FC2_finish = 1;
    else
        en_compute_FC2_finish = 0;    
end

always @(posedge clk) // start check answer
begin
    if(en_compute_FC1_finish)
        count_addr_A_check_ans <= count_addr_A_check_ans + 1;
end

always @(posedge clk) // start check answer
begin
    if(en_compute_FC2_finish)
        count_addr_B_check_ans <= count_addr_B_check_ans + 1;
end

always @(*)
begin
    if(!en_compute_FC1_finish && !en_compute_FC2_finish && !en_compute_FC2)
    begin
        sram_wen_a = 0;
        sram_addr_a = count_addr_A;
        sram_wdata_a = spike;
    end
    else if(en_compute_FC1_finish && !en_compute_FC2_finish && !en_compute_FC2)
    begin
        sram_wen_a = 1;
        sram_addr_a = count_addr_A_check_ans;
    end
    else if(en_compute_FC1_finish && !en_compute_FC2_finish && en_compute_FC2)
    begin
        sram_wen_a = 1;
        sram_wen_b = 0;
        sram_addr_a = count_addr_A_for_B;
        sram_addr_b = count_addr_B;
        sram_wdata_b = spike_l2;
    end
    else if(en_compute_FC1_finish && en_compute_FC2_finish && en_compute_FC2)
    begin
        sram_wen_b = 1;
        sram_addr_b = count_addr_B_check_ans;
    end
end


endmodule


// Layer 1 timestep 0
// 一次輸出一個sipke的值，在同一個timestep內(相同encode input)，根據不同的權重，總共要做100次(0-78399)
module FC1
(
    input clk,
    input [20:0] count_addr_A,
    input encode_input,
    input signed [7:0] sram_rdata_weight,
    output reg spike,
    output reg signed [20:0] pastmem
);


// counter for load encode_input
reg [10:0] counter;
always @(posedge clk)
begin
    if(count_addr_A <= 100 && counter < 783)
        #(1) counter <= counter + 1;
    else
        #(1) counter <= 0;
end

// Get membrance
reg signed [20:0] sum_mem;
reg signed [20:0] sum_mem_past;
reg signed [7:0] mem;
wire signed [20:0] half_sum_mem;
reg signed [20:0] v_th = 21'd68;
integer i;
integer j;
assign half_sum_mem = sum_mem >>> 1;

always @(posedge clk)
begin
    if(count_addr_A <= 100 )
        #(1) sum_mem_past <= sum_mem;
end

always @(*)
begin
    if(count_addr_A <= 100 )
    begin
        if(encode_input == 1)
            mem = sram_rdata_weight;
        else
            mem = 0;
    end        
end

always @(*)
begin
    if(count_addr_A <= 100 )
    begin
        if(counter == 0)
            sum_mem = mem;
        else
            sum_mem = sum_mem_past + mem;
    end
end

always @(*)
begin
    if(count_addr_A <= 100 )
    begin
        if(counter == 783)
        begin
            if(half_sum_mem >= v_th)
                spike = 1;
            else
                spike = 0;
    end
    end
end

always @(*)
begin
    if(count_addr_A <= 100 )
    begin
        if(counter == 783)
        begin
            if(half_sum_mem >= v_th)
                pastmem = v_th;
            else if(half_sum_mem <= 0)
                pastmem = 0;
            else
                pastmem = half_sum_mem;
    end
    end
end 

endmodule

// Layer 1 timestep 0
// 一次輸出一個sipke的值，在同一個timestep內(相同encode input)，根據不同的權重，總共要做100次(0-78399)
module FC1_t1
(
    input clk,
    input [20:0] count_addr_A,
    input encode_input,
    input signed [7:0] sram_rdata_weight,
    input signed [20:0] pastmem,
    output reg spike,
    output reg signed [20:0] pastmem_now
);


// counter for load encode_input
reg [10:0] counter;
always @(posedge clk)
begin
    if(count_addr_A >= 100  && counter < 783)
        #(1) counter <= counter + 1;
    else
        #(1) counter <= 0;
end

// Get membrance
reg signed [20:0] sum_mem;
reg signed [20:0] sum_mem_past;
reg signed [7:0] mem;
wire signed [20:0] half_sum_mem;
reg signed [20:0] v_th = 21'd68;
integer i;
integer j;
assign half_sum_mem = (pastmem + sum_mem) >>> 1;

always @(posedge clk)
begin
    if(count_addr_A >= 100 )
        #(1) sum_mem_past <= sum_mem;
end

always @(*)
begin
    if(count_addr_A >= 100 )
    begin
        if(encode_input == 1)
            mem = sram_rdata_weight;
        else
            mem = 0;
    end        
end

always @(*)
begin
    if(count_addr_A >= 100 )
    begin
        if(counter == 0)
            sum_mem = mem;
        else
            sum_mem = sum_mem_past + mem;
    end
end

always @(*)
begin
    if(count_addr_A >= 100)
    begin
        if(counter == 783)
        begin
            if(half_sum_mem >= v_th)
                spike = 1;
            else
                spike = 0;
    end
    end
end

always @(*)
begin
    if(count_addr_A >= 100 )
    begin
        if(counter == 783)
        begin
            if(half_sum_mem >= v_th)
                pastmem_now = v_th;
            else if(half_sum_mem <= 0)
                pastmem_now = 0;
            else
                pastmem_now = half_sum_mem;
    end
    end
end 

endmodule

// Layer 2 timestep 0
// 一次輸出一個sipke的值，在同一個timestep內(相同encode input)，根據不同的權重，總共要做10次(0-999)
module FC2
(
    input clk,
    input en_compute_FC2,
    input [20:0] count_addr_B,
    input sram_rdata_a,
    input signed [7:0] sram_rdata_weight,
    output reg spike_l2,
    output reg signed [20:0] pastmem_l2
);


// counter for load encode_input
reg [10:0] counter_l2;
always @(posedge clk)
begin
    if(count_addr_B <= 10 && counter_l2 < 99 && en_compute_FC2)
        #(1) counter_l2 <= counter_l2 + 1;
    else
        #(1) counter_l2 <= 0;
end

// Get membrance
reg signed [20:0] sum_mem;
reg signed [20:0] sum_mem_past;
reg signed [7:0] mem;
wire signed [20:0] half_sum_mem;
reg signed [20:0] v_th = 21'd91;
integer i;
integer j;
assign half_sum_mem = sum_mem >>> 1;

always @(posedge clk)
begin
    if(count_addr_B <= 10 && en_compute_FC2)
        #(1) sum_mem_past <= sum_mem;
end

always @(*)
begin
    if(count_addr_B <= 10 && en_compute_FC2)
    begin
        if(sram_rdata_a == 1)
            mem = sram_rdata_weight;
        else
            mem = 0;
    end        
end

always @(*)
begin
    if(count_addr_B <= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 0)
            sum_mem = mem;
        else
            sum_mem = sum_mem_past + mem;
    end
end

always @(*)
begin
    if(count_addr_B <= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 99)
        begin
            if(half_sum_mem >= v_th)
                spike_l2 = 1;
            else
                spike_l2 = 0;
    end
    end
end

always @(*)
begin
    if(count_addr_B <= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 99)
        begin
            if(half_sum_mem >= v_th)
                pastmem_l2 = v_th;
            else if(half_sum_mem <= 0)
                pastmem_l2 = 0;
            else
                pastmem_l2 = half_sum_mem;
    end
    end
end 

endmodule

// Layer 2 timestep 1-99
// 一次輸出一個sipke的值，在同一個timestep內(相同encode input)，根據不同的權重，總共要做10次(0-999)
module FC2_t1
(
    input clk,
    input en_compute_FC2,
    input [20:0] count_addr_B,
    input sram_rdata_a,
    input signed [7:0] sram_rdata_weight,
    input signed [20:0] pastmem_l2,
    output reg spike_l2,
    output reg signed [20:0] pastmem_now_l2
);


// counter for load encode_input
reg [10:0] counter_l2;
always @(posedge clk)
begin
    if(count_addr_B >= 10  && counter_l2 < 99 && en_compute_FC2)
        #(1) counter_l2 <= counter_l2 + 1;
    else
        #(1) counter_l2 <= 0;
end

// Get membrance
reg signed [20:0] sum_mem;
reg signed [20:0] sum_mem_past;
reg signed [7:0] mem;
wire signed [20:0] half_sum_mem;
reg signed [20:0] v_th = 21'd91;
integer i;
integer j;
assign half_sum_mem = (pastmem_l2 + sum_mem) >>> 1;

always @(posedge clk)
begin
    if(count_addr_B >= 10 && en_compute_FC2)
        #(1) sum_mem_past <= sum_mem;
end

always @(*)
begin
    if(count_addr_B >= 10 && en_compute_FC2)
    begin
        if(sram_rdata_a == 1)
            mem = sram_rdata_weight;
        else
            mem = 0;
    end        
end

always @(*)
begin
    if(count_addr_B >= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 0)
            sum_mem = mem;
        else
            sum_mem = sum_mem_past + mem;
    end
end

always @(*)
begin
    if(count_addr_B >= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 99)
        begin
            if(half_sum_mem >= v_th)
                spike_l2 = 1;
            else
                spike_l2 = 0;
    end
    end
end

always @(*)
begin
    if(count_addr_B >= 10 && en_compute_FC2)
    begin
        if(counter_l2 == 99)
        begin
            if(half_sum_mem >= v_th)
                pastmem_now_l2 = v_th;
            else if(half_sum_mem <= 0)
                pastmem_now_l2 = 0;
            else
                pastmem_now_l2 = half_sum_mem;
    end
    end
end 

endmodule