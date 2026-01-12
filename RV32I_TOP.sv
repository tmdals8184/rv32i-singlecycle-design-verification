`timescale 1ns / 1ps
`define TB

module RV32I_TOP (
    input logic clk,
    input logic reset
);
    logic [31:0] instr_code, instr_rAddr, dAddr, dWdata, dRdata;
    logic d_wr_en;
    logic [2:0] d_func3;

    RV32I_Core U_RV32I_CPU (.*);
    instr_mem U_Instr_Mem (.*);
    data_mem U_DATA_MEM (.*);
endmodule

module RV32I_VERIFI (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr_code,
    output logic [31:0] instr_rAddr
`ifdef TB
    ,output logic        tb_we          // r-type, i-type
    ,output logic [31:0] tb_alu_a
    ,output logic [31:0] tb_alu_b
    ,output logic [31:0] tb_reg_data

    ,output logic [31:0] tb_ram_wdata   
    ,output logic [31:0] tb_ram_addr// s-type
    ,output logic [ 2:0] tb_funct3
    ,output logic [31:0] tb_ram_data
    ,output logic tb_ram_we
`endif
);

    logic [31:0] dAddr, dWdata, dRdata;
    logic d_wr_en;
    logic [2:0] d_func3;

`ifdef TB
    assign tb_ram_we = d_wr_en;
    assign tb_ram_wdata = dWdata;
    assign tb_funct3 = d_func3;
    assign tb_ram_addr = dAddr;
`endif 


    RV32I_Core U_RV32I_CORE (
        .clk(clk),
        .reset(reset),
        .instr_code(instr_code),
        .dRdata(dRdata),
        .instr_rAddr(instr_rAddr),
        .d_wr_en(d_wr_en),
        .dAddr(dAddr),
        .d_func3(d_func3),
        .dWdata(dWdata)
`ifdef TB
        ,.tb_we(tb_we)
        ,.tb_alu_a(tb_alu_a)
        ,.tb_alu_b(tb_alu_b)
        ,.tb_reg_data(tb_reg_data)
`endif
    );
    data_mem U_RAM (
        .clk(clk),
        .d_wr_en(d_wr_en),
        .dAddr(dAddr),
        .dWdata(dWdata),
        .d_func3(d_func3),
        .dRdata(dRdata)
`ifdef TB
        ,.tb_ram_data(tb_ram_data)
`endif
    );

endmodule


module RV32I_Core (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr_code,
    input  logic [31:0] dRdata,
    output logic [31:0] instr_rAddr,
    output logic        d_wr_en,
    output logic [31:0] dAddr,
    output logic [ 2:0] d_func3,
    output logic [31:0] dWdata
`ifdef TB
    ,output logic        tb_we
    ,output logic [31:0] tb_alu_a
    ,output logic [31:0] tb_alu_b
    ,output logic [31:0] tb_reg_data
`endif
);

    logic [3:0] alu_controls;
    logic reg_wr_en, aluSrcMuxSel, branch, jal, jalr;
    logic [2:0] RegWdataSel;

    control_unit U_Control_Unit (.*);
    datapath U_Data_Path (.*);

endmodule


