`timescale 1ns / 1ps

module instr_mem (
    input  logic [31:0] instr_rAddr,
    output logic [31:0] instr_code
);
    logic [31:0] rom[0:127];

    initial begin
        $readmemh("code_20250929_exam0.mem", rom);
    end



    // initial begin
    //     // R-type
    //     rom[0] = 32'h003202B3;  // ADD    x5,  x4, x3   => 7  (4 + 3)      
    //     rom[1] = 32'h40500333;  // SUB    x6,  x0, x5   => -7 (0 - 7)    
    //     rom[2] = 32'h002293B3;  // SLL    x7 , x5, x2   => 28 (7 << 2)    
    //     rom[3] = 32'h0012D433;  // SRL    x8 , x5, x1   => 3  (7 >> 1)    
    //     rom[4] = 32'h402354B3;  // SRA    x9 , x6, x2   => -2 (-7 >>> 2)    
    //     rom[5] = 32'h00532533;  // SLT    x10, x6, x5   => 1  (-7 < 7)     
    //     rom[6] = 32'h005335B3;  // SLTU   x11, x6, x5   => 0  (0xFFFF_FFF9 < 7)       
    //     rom[7] = 32'h0022C633;  // XOR    x12, x5, x2   => 5  (0111 ^ 0010 = 0101)   
    //     rom[8] = 32'h002266B3;  // OR     x13, x4, x2   => 6  (0100 | 0010 = 0110) 
    //     rom[9] = 32'h0063F733;  // AND    x14, x7, x6   => 24 (0001_1100 & 1111_1001 = 0001_1000)  

    //     // // S-type
    //     rom[10] = 32'h00f00623;  // SB x15, 12(x0)      => ram[3] = 0x00_00_00_CC
    //     rom[11] = 32'h00f008a3;  // SB x15, 17(x0)      => ram[4] = 0x00_00_CC_00 
    //     rom[12] = 32'h00f00b23;  // SB x15, 22(x0)      => ram[5] = 0x00_CC_00_00 
    //     rom[13] = 32'h00f00da3;  // SB x15, 27(x0)      => ram[6] = 0xCC_00_00_00 
    //     rom[14] = 32'h00f01e23;  // SH x15, 28(x0)      => ram[7] = 0x00_00_DD_CC 
    //     rom[15] = 32'h02f01123;  // SH x15, 34(x0)      => ram[8] = 0xDD_CC_00_00 
    //     rom[16] = 32'h02f02223;  // SW x15, 36(x0)      => ram[9] = 0xFF_EE_DD_CC 

    //     // // IL-type
    //     rom[17] = 32'h02400783;  // LB    x15, 36(x0)   => FF_FF_FF_CC
    //     rom[18] = 32'h02500803;  // LB    x16, 37(x0)   => FF_FF_FF_DD
    //     rom[19] = 32'h02600883;  // LB    x17, 38(x0)   => FF_FF_FF_EE
    //     rom[20] = 32'h02700903;  // LB    x18, 39(x0)   => FF_FF_FF_FF
    //     rom[21] = 32'h02404783;  // LBU   x15, 36(x0)   => 00_00_00_CC
    //     rom[22] = 32'h02504803;  // LBU   x16, 37(x0)   => 00_00_00_DD
    //     rom[23] = 32'h02604883;  // LBU   x17, 38(x0)   => 00_00_00_EE
    //     rom[24] = 32'h02704903;  // LBU   x18, 39(x0)   => 00_00_00_FF
    //     rom[25] = 32'h02401783;  // LH    x15, 36(x0)   => FF_FF_DD_CC
    //     rom[26] = 32'h02601803;  // LH    x16, 38(x0)   => FF_FF_FF_EE
    //     rom[27] = 32'h02405883;  // LHU   x17, 36(x0)   => 00_00_DD_CC
    //     rom[28] = 32'h02605903;  // LHU   x18, 38(x0)   => 00_00_FF_EE
    //     rom[29] = 32'h02402983;  // LW    x19, 36(x0)   => FF_EE_DD_CC

    //     // I-type
    //     rom[30] = 32'hFF628A13;  // ADDI  x20, x5, -10  => -3
    //     rom[31] = 32'h00229A93;  // SLLI  x21, x5, 2    => 28(7 << 2)
    //     rom[32] = 32'h0022DB13;  // SRLI  x22, x5, 2    => 1 (7 >> 1)
    //     rom[33] = 32'h402A5B93;  // SRAI  x23, x20, 2   => -1(-3 >>> 2)
    //     rom[34] = 32'h0092AC13;  // SLTI  x24, x5, 9    => 1 (7 < 9)
    //     rom[35] = 32'hFF72BC93;  // SLTIU x25, x5, -9   => 1 (7 < 0xFFFF_FFF7)
    //     rom[36] = 32'h00B2CD13;  // XORI  x26, x5, 11   => 12(0111 ^ 1011 = 1100)
    //     rom[37] = 32'h0082ED93;  // ORI   x27, x5, 8    => 15(0111 | 1000 = 1111)
    //     rom[38] = 32'h00E2FE13;  // ANDI  x28, x5, 14   => 6 (0111 & 1110 = 0110)

    //     // B-type
    //     rom[39] = 32'h00210663;  // BEQ   x2, x2, 12    => PC + 12 (2 = 2)
    //     rom[40] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[41] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[42] = 32'h00209663;  // BNE   x1, x2, 12    => PC + 12 (1 != 2)
    //     rom[43] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[44] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[45] = 32'h00534663;  // BLT   x6, x5, 12    => PC + 12 (-7 < 7)
    //     rom[46] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[47] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[48] = 32'h0062D663;  // BGE   x5, x6, 12    => PC + 12 (7 >= -7)
    //     rom[49] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[50] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[51] = 32'h0060E663;  // BLTU  x1, x6, 12    => PC + 12 (1 < 0xFFFF_FFF9(-7))
    //     rom[52] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[53] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[54] = 32'h00137663;  // BGEU  x6, x1, 12    => PC + 12 (0xFFFF_FFF9(-7) >= 1)
    //     rom[55] = 32'h00120213;  // dummy data ADDI x4, x4, 1 => 5
    //     rom[56] = 32'h00220213;  // dummy data ADDI x4, x4, 2 => 7
    //     rom[57] = 32'h00800393;  // ADDI x7, x0, 8      => 8

    //     // U-type
    //     rom[58] = 32'h0ffffeb7;  // LUI   x29, 00_FFFF  => 0FFF_F000 (imm = 00_FFFF)
    //     rom[59] = 32'h0eeeef17;  // AUIPC x30, 00_EEEE  => 0EEE_E0EC (PC = EC, imm = 00_EEEE)

    //     // J-type
    //     rom[60] = 32'h00c00fef;  // JAL    x31, 12       => x31 = pc+4 / pc = pc+imm(rom[63])
    //     rom[61] = 32'h00100f93;  // dummy data ADDI x31, x0, 1 => x31 = 1
    //     rom[62] = 32'h00100f93;  // dummy data ADDI x31, x0, 1 => x31 = 1
    //     rom[63] = 32'h10800fe7;  // JALR   x31, 264(x0)  => x31 = pc+4 / pc = rs1+imm(rom[66])
    //     rom[64] = 32'h00100f93;  // dummy data ADDI x31, x0, 1 => x31 = 1
    //     rom[65] = 32'h00100f93;  // dummy data ADDI x31, x0, 1 => x31 = 1
    //     rom[66] = 32'h00000F93;  // ADDI x31, x0, 0      => x31 = 0



    // end

    assign instr_code = rom[instr_rAddr[31:2]];

endmodule

