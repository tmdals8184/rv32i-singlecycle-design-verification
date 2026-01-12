`timescale 1ns / 1ps

`include "define.sv"


module control_unit (
    input  logic [31:0] instr_code,
    output logic [ 3:0] alu_controls,
    output logic        reg_wr_en,
    output logic        d_wr_en,
    output logic        aluSrcMuxSel,
    output logic [ 2:0] RegWdataSel,
    output logic        branch,
    output logic [ 2:0] d_func3,
    output logic        jal,
    output logic        jalr
);

    //    rom [0] = 32'h004182B3; //32'b0000_0000_0100_0001_1000_0010_1011_0011; // add x5, x3, x4
    wire  [6:0] funct7 = instr_code[31:25];
    wire  [6:0] opcode = instr_code[6:0];
    wire  [2:0] funct3 = instr_code[14:12];
    logic [8:0] controls;

    assign {jal, jalr, branch, RegWdataSel, aluSrcMuxSel, reg_wr_en, d_wr_en} = controls;

    always_comb begin
        case (opcode)
            // jal, jalr, branch, RegWdataSel, aluSrcMuxSel, reg_wr_en, d_wr_en
            `OP_R_TYPE:  controls = 9'b000_000_010;
            `OP_S_TYPE:  controls = 9'b000_000_101;
            `OP_IL_TYPE: controls = 9'b000_001_110;
            `OP_I_TYPE:  controls = 9'b000_000_110;
            `OP_B_TYPE:  controls = 9'b001_000_000;
            `OP_UL_TYPE: controls = 9'b000_010_010;
            `OP_UA_TYPE: controls = 9'b000_011_010;
            `OP_J_TYPE:  controls = 9'b100_100_010;
            `OP_JL_TYPE: controls = 9'b110_100_010;
            default:     controls = 9'b000_000_000;
        endcase
    end

    always_comb begin
        case (opcode)
            // [function[5], function3[2:0]]
            `OP_R_TYPE: alu_controls = {funct7[5], funct3};  // R-type
            `OP_S_TYPE: alu_controls = `ADD;  // S-type
            `OP_IL_TYPE: alu_controls = `ADD;  // IL-type
            `OP_I_TYPE: begin
                if ({funct7[5], funct3} == 4'b1101)
                    alu_controls = {1'b1, funct3};
                else alu_controls = {1'b0, funct3};  // I-type
            end
            `OP_B_TYPE: alu_controls = {1'b0, funct3};  // B-type
            default: alu_controls = 4'bx;
        endcase
    end

    always_comb begin
        case (opcode)
            `OP_S_TYPE:  d_func3 = funct3;
            `OP_IL_TYPE: d_func3 = funct3;
            default:     d_func3 = 3'b000;
        endcase
    end




endmodule
