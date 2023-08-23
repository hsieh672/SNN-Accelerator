module sram_512x32b #(       //for activation a
    parameter WordNum  = 3500, // timestep * imag
    parameter BitWidth = 1 // spike = 1 bit
)(
    input                     clk,   //clock input
    input                     csb,   //chip enable (active low)
    input                     wsb,   //write enable (active low)    
    input      [20:0]          waddr, //write address
    input      [BitWidth-1:0] wdata, //write data
    input      [20:0]          raddr, //read address
    output reg [BitWidth-1:0] rdata  //read data
);

reg [BitWidth-1:0] mem [0:WordNum-1];

always @(posedge clk) begin
    if(~csb && ~wsb)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    if(~csb)
        #(1) rdata <= mem[raddr];
end

task load_param(
    input integer        index,
    input [BitWidth-1:0] param_input
);
    mem[index] = param_input;
endtask

endmodule