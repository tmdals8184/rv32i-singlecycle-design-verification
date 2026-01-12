`timescale 1ns / 1ps

`include "define.sv"
`define TB

module datapath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr_code,
    input  logic [ 3:0] alu_controls,
    input  logic        reg_wr_en,
    input  logic        aluSrcMuxSel,
    input  logic [ 2:0] RegWdataSel,
    input  logic        branch,
    input  logic [31:0] dRdata,
    input  logic        jal,
    input  logic        jalr,
    output logic [31:0] instr_rAddr,
    output logic [31:0] dAddr,
    output logic [31:0] dWdata
`ifdef TB
    ,output logic        tb_we
    ,output logic [31:0] tb_alu_a
    ,output logic [31:0] tb_alu_b
    ,output logic [31:0] tb_reg_data
`endif
);

    logic [31:0] w_regfile_rd1, w_regfile_rd2, w_alu_result;
    logic [31:0] w_imm_ext, w_alusrcmux_out, w_imm_plus_jarl;
    logic [31:0] w_pc_Next, w_jarl_out, RegWdataOut, w_pc_plus_4;
    logic pc_MuxSel, btaken;

    assign dAddr = w_alu_result;
    assign dWdata = w_regfile_rd2;

    assign pc_MuxSel = jal | (branch & btaken);

`ifdef TB
    assign tb_we    = reg_wr_en;
    assign tb_alu_a = w_regfile_rd1;
    assign tb_alu_b = w_alusrcmux_out;

`endif

    mux_2x1 U_JALR_MUX (
        .sel(jalr),
        .x0 (instr_rAddr),    // 0 : pc
        .x1 (w_regfile_rd1),  // 1 : rs1
        .y  (w_jarl_out)
    );

    adder U_IMM_ADDER (
        .a  (w_jarl_out),
        .b  (w_imm_ext),
        .sum(w_imm_plus_jarl)
    );

    mux_2x1 U_PC_MUX (
        .sel(pc_MuxSel),
        .x0 (w_pc_plus_4),      // 0 : pc + 4
        .x1 (w_imm_plus_jarl),  // 1 : imm + (pc or rs1) 
        .y  (w_pc_Next)
    );

    adder U_PC_ADDER (
        .a  (32'd4),
        .b  (instr_rAddr),
        .sum(w_pc_plus_4)
    );

    program_counter U_PC (
        .clk    (clk),
        .reset  (reset),
        .pc_next(w_pc_Next),
        .pc     (instr_rAddr)
    );

    register_file U_REG_FILE (
        .clk      (clk),
        .RA1      (instr_code[19:15]),  // read address 1
        .RA2      (instr_code[24:20]),  // read address 2
        .WA       (instr_code[11:7]),   // write address
        .reg_wr_en(reg_wr_en),          // write enable
        .WData    (RegWdataOut),        // write data
        .RD1      (w_regfile_rd1),      // read data 1
        .RD2      (w_regfile_rd2)       // read data 2
    `ifdef TB
        ,.tb_reg_data(tb_reg_data)
    `endif
    );

    mux_8x1 U_RegWdataMux (
        .sel(RegWdataSel),
        .x0 (w_alu_result),     // 0: R-type, I-type
        .x1 (dRdata),           // 1: IL-type
        .x2 (w_imm_ext),        // 2: U-type(LUI)
        .x3 (w_imm_plus_jarl),  // 3: U-type(AUIPC)
        .x4 (w_pc_plus_4),      // 4: J-type(JAL/JALR)
        .y  (RegWdataOut)       // to wd
    );

    ALU U_ALU (
        .a           (w_regfile_rd1),
        .b           (w_alusrcmux_out),
        .alu_controls(alu_controls),
        .alu_result  (w_alu_result),
        .btaken      (btaken)

    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (w_regfile_rd2),
        .x1 (w_imm_ext),
        .y  (w_alusrcmux_out)
    );

    extend U_EXTEND (
        .instr_code(instr_code),
        .imm_Ext(w_imm_ext)
    );


endmodule


module program_counter (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc_next,
    output logic [31:0] pc
);

    register U_PC_REG (
        .clk(clk),
        .reset(reset),
        .d(pc_next),
        .q(pc)
    );
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end

endmodule

module register_file (
    input  logic        clk,
    input  logic [ 4:0] RA1,        // read address 1
    input  logic [ 4:0] RA2,        // read address 2
    input  logic [ 4:0] WA,         // write address
    input  logic        reg_wr_en,  // write enable
    input  logic [31:0] WData,      // write data
    output logic [31:0] RD1,        // read data 1
    output logic [31:0] RD2         // read data 2
`ifdef TB
    ,output logic [31:0] tb_reg_data
`endif

);

    logic [31:0] reg_file[0:31];  // 32bit 32개.

// initial begin
//     reg_file[0] = 0;
// end

    initial begin
        foreach (reg_file[i]) begin
            reg_file[i] = i; 
            // reg_file[i] = 0; 
        end
    end

    // initial begin
    //     for (int i = 0; i < 32; i++) begin
    //         reg_file[i] = i;
    //     end
    // end

    always_ff @(posedge clk) begin
        if (reg_wr_en) begin
            reg_file[WA] <= WData;
        end
    end

    // register address = 0 is zero to return
    assign RD1 = (RA1 != 0) ? reg_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? reg_file[RA2] : 0;

 `ifdef TB
    assign tb_reg_data = reg_file[WA];
`endif

endmodule

module ALU (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [ 3:0] alu_controls,
    output logic [31:0] alu_result,
    output logic        btaken
);

    always_comb begin
        case (alu_controls)
            // r-type
            `ADD: alu_result = a + b;
            `SUB: alu_result = a - b;
            `SLL: alu_result = a << b[4:0];
            `SRL: alu_result = a >> b[4:0];  // 0으로 extend
            `SRA: alu_result = $signed(a) >>> b[4:0];  // [31] extend signed bit
            `SLT: alu_result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: alu_result = (a < b) ? 1 : 0;  // unsigned SLT
            `XOR: alu_result = a ^ b;
            `OR: alu_result = a | b;
            `AND: alu_result = a & b;
            default: alu_result = 32'bx;
        endcase
    end

    //branch
    always_comb begin
        case (alu_controls[2:0])
            `BEQ:    btaken = ($signed(a) == $signed(b));
            `BNE:    btaken = ($signed(a) != $signed(b));
            `BLT:    btaken = ($signed(a) < $signed(b));
            `BGE:    btaken = ($signed(a) >= $signed(b));
            `BLTU:   btaken = ($unsigned(a) < $unsigned(b));
            `BGEU:   btaken = ($unsigned(a) >= $unsigned(b));
            default: btaken = 1'b0;
        endcase

    end

endmodule

module extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_Ext
);

    wire [2:0] funct3 = instr_code[14:12];
    wire [6:0] opcode = instr_code[6:0];

    always_comb begin
        case (opcode)
            `OP_R_TYPE: imm_Ext = 32'bx;
            // 20 literal 1b'0, imm[11:5] 7bit, imm[4:0] 5bit
            `OP_S_TYPE:
            imm_Ext = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };
            `OP_IL_TYPE: imm_Ext = {{20{instr_code[31]}}, instr_code[31:20]};
            `OP_I_TYPE: imm_Ext = {{20{instr_code[31]}}, instr_code[31:20]};
            `OP_B_TYPE:
            imm_Ext = {
                {20{instr_code[31]}},
                instr_code[7],
                instr_code[30:25],
                instr_code[11:8],
                1'b0
            };
            `OP_UL_TYPE: imm_Ext = {instr_code[31:12], 12'b0};
            `OP_UA_TYPE: imm_Ext = {instr_code[31:12], 12'b0};
            `OP_J_TYPE:
            imm_Ext = {
                {12{instr_code[31]}},
                instr_code[19:12],
                instr_code[20],
                instr_code[30:21],
                1'b0
            };
            `OP_JL_TYPE: imm_Ext = {{20{instr_code[31]}}, instr_code[31:20]};
            default: imm_Ext = 32'bx;
        endcase
    end

endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,   // 0 : regFile R2
    input  logic [31:0] x1,   // 1: imm [31:0]
    output logic [31:0] y     // to ALU R2
);

    assign y = sel ? x1 : x0;

endmodule

module mux_8x1 (
    input  logic  [2:0] sel,
    input  logic [31:0] x0,   // 0: r-type, i-type
    input  logic [31:0] x1,   // 1: il-type
    input  logic [31:0] x2,   // 2: ul-type
    input  logic [31:0] x3,   // 3: ua-type
    input  logic [31:0] x4,   // 4: j-type
    output logic [31:0] y     // to wd
);

    always_comb begin
        case (sel)
            3'b000:  y = x0;
            3'b001:  y = x1;
            3'b010:  y = x2;
            3'b011:  y = x3;
            3'b100:  y = x4;
            default: y = 32'bx;
        endcase
    end

endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] sum
);

    assign sum = a + b;

endmodule
