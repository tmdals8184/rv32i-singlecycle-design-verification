`timescale 1ns / 1ps
`define TB
`include "D:\work\verilog\rv32i_final_ver3\20250924_RV32I.srcs\sources_1\imports\file\define.sv"

interface rv_if;
    logic        clk;
    logic        reset;
    logic [31:0] instr_code;
    logic [31:0] instr_rAddr;
`ifdef TB
    logic tb_we;  //reg write enable
    logic [31:0] tb_alu_a;  // alu input a
    logic [31:0] tb_alu_b;  // alu input b(b or imm)
    logic [31:0] tb_reg_data;  //실제 reg 내부값

    logic [31:0] tb_ram_wdata;  // ram으로 들어가는 data
    logic [31:0] tb_ram_addr;  // ram주소값
    logic [2:0] tb_funct3;  //funct3값
    logic [31:0] tb_ram_data;  //실제 ram 내부값
    logic tb_ram_we;  // ram write enable

    int unsigned tb_r_count[10];  //r-type
    int unsigned tb_i_count[9];  //i-type

    int unsigned tb_sb_count[4];  //s-type
    int unsigned tb_sh_count[2];
    int unsigned tb_sw_count;

    int unsigned tb_lb_count[4];  //il-type
    int unsigned tb_lbu_count[4];
    int unsigned tb_lh_count[2];
    int unsigned tb_lhu_count[2];
    int unsigned tb_lw_count;
    int unsigned tb_misalign_count;

`endif
endinterface  //rv_if

class transaction;

    rand bit [ 4:0] rs1,           rs2, rd;
    rand bit [11:0] imm;

    bit      [ 6:0] opcode;
    bit      [ 6:0] funct7;
    bit      [ 2:0] funct3;
    rand bit [ 3:0] funct_r;
    rand bit [ 3:0] funct_i;

    bit      [31:0] instr_code;
    logic    [31:0] expected_data;
    logic    [31:0] receive_data;

    constraint rd_dist {rd inside {[1 : 31]};}
    // constraint rd_dist {rd inside {5'b01100};}
    // constraint rs1_rs2_dist {
    //     rs1 inside {5'b01100};
    //     rs2 inside {5'b01100};
    // }
    constraint r_dist {
        funct_r inside {`ADD, `SUB, `SLL, `SRL, `SRA, `SLT, `SLTU, `XOR, `OR,
                        `AND};
    }
    constraint i_dist {
        funct_i inside {`ADD, `SLL, `SRL, `SRA, `SLT, `SLTU, `XOR, `OR, `AND};
    }

    function string get_op_name(string op_type, bit [3:0] control);
        if (op_type == "R") begin
            case (control)
                `ADD:    return "ADD";
                `SUB:    return "SUB";
                `SLL:    return "SLL";
                `SRL:    return "SRL";
                `SRA:    return "SRA";
                `SLT:    return "SLT";
                `SLTU:   return "SLTU";
                `XOR:    return "XOR";
                `OR:     return "OR";
                `AND:    return "AND";
                default: return "UNKNOWN";
            endcase
        end else if (op_type == "I") begin
            case ({
                1'b0, control[2:0]
            })
                `ADD:    return "ADDI";
                `SLL:    return "SLLI";
                `SRL: begin
                    if (control[3]) return "SRAI";
                    else return "SRLI";
                end
                `SLT:    return "SLTI";
                `SLTU:   return "SLTIU";
                `XOR:    return "XORI";
                `OR:     return "ORI";
                `AND:    return "ANDI";
                default: return "UNKNOWN";
            endcase
        end
    endfunction

    task display(string name_s);
        if (name_s == "[DRI]") begin
            case (instr_code[6:0])
                `OP_R_TYPE:
                $display(
                    "[DRI] %s x%d, x%d, x%d",
                    get_op_name(
                        "R", funct_r
                    ),
                    rd,
                    rs1,
                    rs2
                );
                `OP_I_TYPE:
                $display(
                    "[DRI] %s x%d, x%d, %d",
                    get_op_name(
                        "I", funct_i
                    ),
                    rd,
                    rs1,
                    imm
                );
            endcase
        end
        $display("%t, [%s] exp : %8h, rcv : h%8h, d%1d", $time, name_s,
                 expected_data, receive_data, $signed(receive_data));
    endtask  //display

endclass  //transaction

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv;

    localparam logic [6:0] OP_R = 7'b0110011;
    localparam logic [6:0] OP_I = 7'b0010011;
    localparam logic [6:0] OP_IL = 7'b0000011;
    localparam logic [6:0] OP_S = 7'b0100011;

    function new(mailbox#(transaction) gen2drv);
        this.gen2drv = gen2drv;

    endfunction  //new()

    task r_run(int count);
        repeat (count) begin
            tr = new();
            assert (tr.randomize())
            else $error("[Gen] randomize() error!!");
            tr.funct7 = tr.funct_r[3] ? 7'b0100000 : 7'b0000000;
            tr.funct3 = tr.funct_r[2:0];
            // tr.rs1 = tr.rd;
            // tr.rs2 = tr.rd;
            tr.instr_code = {tr.funct7, tr.rs2, tr.rs1, tr.funct3, tr.rd, OP_R};
            tr.display("[GEN]");
            gen2drv.put(tr);
        end
    endtask  //r_run

    task i_run(int count);
        repeat (count) begin
            bit funct7_5;
            tr = new();
            assert (tr.randomize())
            else $error("[Gen] randomize() error!!");
            tr.funct3 = tr.funct_i[2:0];
            funct7_5  = tr.funct_i[3];
            if (tr.funct3 == 3'b001) begin
                tr.imm[11:5] = 7'b0000000;
            end else if (tr.funct3 == 3'b101) begin
                tr.imm[11:5] = funct7_5 ? 7'b0100000 : 7'b0000000;
            end
            tr.instr_code = {tr.imm, tr.rs1, tr.funct3, tr.rd, OP_I};
            tr.display("[GEN]");
            gen2drv.put(tr);
        end
    endtask  //i_run

    task s_run(int count, bit [2:0] funct3);
        repeat (count) begin
            tr = new();
            assert (tr.randomize())
            else $error("[Gen] randomize() error!!");
            tr.funct3 = funct3;
            // case (tr.funct3)
            //     3'b000:  ;  // SB
            //     3'b001: begin  // SH
            //         tr.imm[0] = 1'b0;
            //     end
            //     3'b010: begin  // SW
            //         tr.imm[1:0] = 2'b00;
            //     end
            //     default: ;
            // endcase
            tr.instr_code = {
                tr.imm[11:5], tr.rs2, tr.rs1, tr.funct3, tr.imm[4:0], OP_S
            };
            tr.display("[GEN]");
            gen2drv.put(tr);
        end
    endtask  //s_run

    task il_run(int count, bit [2:0] funct3);
        repeat (count) begin
            tr = new();
            assert (tr.randomize())
            else $error("[Gen] randomize() error!!");
            tr.funct3 = funct3;
            if (tr.funct3 == 3'b001) begin  //LH
                tr.imm[0] = 1'b0;
            end else if (tr.funct3 == 3'b101) begin  // LHU
                tr.imm[0] = 1'b0;
            end else if (tr.funct3 == 3'b010) begin  // LW
                tr.imm[1:0] = 2'b00;
            end
            tr.instr_code = {tr.imm, tr.rs1, tr.funct3, tr.rd, OP_IL};
            tr.display("[GEN]");
            gen2drv.put(tr);
        end
    endtask  //il_run



endclass  //generator

class driver;
    virtual rv_if rv_if;
    transaction tr;
    mailbox #(transaction) gen2drv;

    function new(mailbox#(transaction) gen2drv, virtual rv_if rv_if);
        this.gen2drv = gen2drv;
        this.rv_if   = rv_if;
    endfunction  //new()

    task run();
        forever begin
            gen2drv.get(tr);
            @(negedge rv_if.clk);
            rv_if.instr_code = tr.instr_code;
            tr.display("[DRI]");
            @(posedge rv_if.clk);
        end

    endtask  //run

    task il_run();
        forever begin
            gen2drv.get(tr);
            if (tr.instr_code[14:12] == 3'b001 
                || tr.instr_code[14:12] == 3'b101 
                || tr.instr_code[14:12] == 3'b010) begin
                tr.instr_code[19:15] = 5'b0;
            end
            @(negedge rv_if.clk);
            rv_if.instr_code = tr.instr_code;
            tr.display("[DRI]");
            @(posedge rv_if.clk);
        end

    endtask  //run


endclass  //driver

class monitor;
    virtual rv_if rv_if;
    transaction tr;
    mailbox #(transaction) mon2scb;

    localparam logic [6:0] OP_R = 7'b0110011;
    localparam logic [6:0] OP_I = 7'b0010011;
    localparam logic [6:0] OP_IL = 7'b0000011;
    localparam logic [6:0] OP_S = 7'b0100011;

    logic [31:0] alu_a;
    logic [31:0] alu_b;

    function new(mailbox#(transaction) mon2scb, virtual rv_if rv_if);
        this.mon2scb = mon2scb;
        this.rv_if   = rv_if;

    endfunction  //new()

    task get_expr(string op_type, bit [3:0] control);
        $display("[MON] %3d %s %3d = %3d", $signed(alu_a), tr.get_op_name(
                 op_type, control), $signed(alu_b), $signed(
                                                           tr.receive_data));
    endtask  //get_expr

    task run();
        bit          funct7_5;
        bit   [31:0] addr;
        bit   [ 1:0] line;
        bit   [ 2:0] funct3;
        bit   [ 4:0] shamt;
        logic [31:0] prev_ram_data;
        forever begin
            @(posedge rv_if.clk);
            tr = new();
            tr.funct7 = rv_if.instr_code[31:25];
            tr.funct3 = rv_if.instr_code[14:12];
            tr.opcode = rv_if.instr_code[6:0];
            funct7_5 = rv_if.instr_code[30];
            shamt = rv_if.tb_alu_b[4:0];
            alu_a = rv_if.tb_alu_a;
            alu_b = rv_if.tb_alu_b;

            if (tr.opcode == OP_R) begin
                case ({
                    funct7_5, tr.funct3
                })
                    `ADD: begin
                        tr.expected_data = rv_if.tb_alu_a + rv_if.tb_alu_b;
                        rv_if.tb_r_count[0]++;
                    end
                    `SUB: begin
                        tr.expected_data = rv_if.tb_alu_a - rv_if.tb_alu_b;
                        rv_if.tb_r_count[1]++;
                    end
                    `SLL: begin
                        tr.expected_data = rv_if.tb_alu_a << rv_if.tb_alu_b[4:0];
                        rv_if.tb_r_count[2]++;
                    end
                    `SRL: begin
                        tr.expected_data = rv_if.tb_alu_a >> rv_if.tb_alu_b[4:0];
                        rv_if.tb_r_count[3]++;
                    end
                    `SRA: begin
                        tr.expected_data = $signed(rv_if.tb_alu_a) >>>
                            rv_if.tb_alu_b[4:0];
                        rv_if.tb_r_count[4]++;
                    end
                    `SLT: begin
                        tr.expected_data = ($signed(rv_if.tb_alu_a) <
                                            $signed(rv_if.tb_alu_b)) ? 1 : 0;
                        rv_if.tb_r_count[5]++;
                    end
                    `SLTU: begin
                        tr.expected_data = (rv_if.tb_alu_a < rv_if.tb_alu_b) ? 1 : 0;
                        rv_if.tb_r_count[6]++;
                    end
                    `XOR: begin
                        tr.expected_data = (rv_if.tb_alu_a ^ rv_if.tb_alu_b);
                        rv_if.tb_r_count[7]++;
                    end
                    `OR: begin
                        tr.expected_data = (rv_if.tb_alu_a | rv_if.tb_alu_b);
                        rv_if.tb_r_count[8]++;
                    end
                    `AND: begin
                        tr.expected_data = (rv_if.tb_alu_a & rv_if.tb_alu_b);
                        rv_if.tb_r_count[9]++;
                    end
                endcase
                // if (rv_if.instr_code[24:20] == rv_if.instr_code[19:15]) begin
                //     if (tr.expected_data != 0) begin
                //         $display("[MON] | rs1 == rs2");
                //     end
                // end
                if (rv_if.tb_we) begin
                    #1;
                    tr.receive_data = rv_if.tb_reg_data;
                    mon2scb.put(tr);
                    get_expr("R", {funct7_5, tr.funct3});
                    tr.display("[MON]");
                end


            end else if (tr.opcode == OP_I) begin
                tr.instr_code = rv_if.instr_code;
                case (tr.funct3)
                    3'b000: begin
                        tr.expected_data = rv_if.tb_alu_a + rv_if.tb_alu_b;
                        rv_if.tb_i_count[0]++;
                    end
                    3'b001: begin
                        tr.expected_data = rv_if.tb_alu_a << shamt;
                        rv_if.tb_i_count[1]++;

                    end
                    3'b101: begin
                        if (funct7_5 == 0) begin
                            tr.expected_data = $unsigned(rv_if.tb_alu_a) >>
                                shamt;
                            rv_if.tb_i_count[3]++;
                        end else begin
                            tr.expected_data = $signed(rv_if.tb_alu_a) >>>
                                shamt;
                            rv_if.tb_i_count[2]++;
                        end
                    end
                    3'b010: begin
                        tr.expected_data = ($signed(rv_if.tb_alu_a) <
                                            $signed(rv_if.tb_alu_b)) ? 1 : 0;
                        rv_if.tb_i_count[4]++;

                    end
                    3'b011: begin
                        tr.expected_data = (rv_if.tb_alu_a < rv_if.tb_alu_b) ? 1 : 0;
                        rv_if.tb_i_count[5]++;

                    end
                    3'b100: begin
                        tr.expected_data = (rv_if.tb_alu_a ^ rv_if.tb_alu_b);
                        rv_if.tb_i_count[6]++;

                    end
                    3'b110: begin
                        tr.expected_data = (rv_if.tb_alu_a | rv_if.tb_alu_b);
                        rv_if.tb_i_count[7]++;

                    end
                    3'b111: begin
                        tr.expected_data = (rv_if.tb_alu_a & rv_if.tb_alu_b);
                        rv_if.tb_i_count[8]++;

                    end
                endcase
                if (rv_if.tb_we) begin
                    #1;
                    tr.receive_data = rv_if.tb_reg_data;
                    mon2scb.put(tr);
                    if (tr.funct3 == 3'b101) begin
                        get_expr("I", {funct7_5, tr.funct3});
                    end else get_expr("I", {1'b0, tr.funct3});
                    tr.display("[MON]");
                end


            end else if (tr.opcode == OP_S) begin
                bit [31:0] ram_wdata;

                #0;
                // blocking data : expected data
                if (rv_if.tb_ram_we) begin
                    prev_ram_data = rv_if.tb_ram_data;
                    line          = rv_if.tb_ram_addr[1:0];
                    ram_wdata     = rv_if.tb_ram_wdata;
                    funct3        = rv_if.tb_funct3;
                end

                // non-blocking data -> receive data
                if (rv_if.tb_ram_we) begin
                    #1;
                    case (funct3)
                        3'b000: begin
                            case (line)
                                2'b00: begin
                                    prev_ram_data[7:0] = ram_wdata[7:0];
                                    rv_if.tb_sb_count[0]++;
                                end
                                2'b01: begin
                                    prev_ram_data[15:8] = ram_wdata[7:0];
                                    rv_if.tb_sb_count[1]++;
                                end
                                2'b10: begin
                                    prev_ram_data[23:16] = ram_wdata[7:0];
                                    rv_if.tb_sb_count[2]++;
                                end
                                2'b11: begin
                                    prev_ram_data[31:24] = ram_wdata[7:0];
                                    rv_if.tb_sb_count[3]++;
                                end
                            endcase
                        end
                        3'b001: begin
                            case (line)
                                2'b00: begin
                                    prev_ram_data[15:0] = ram_wdata[15:0];
                                    rv_if.tb_sh_count[0]++;
                                end
                                2'b10: begin
                                    prev_ram_data[31:16] = ram_wdata[15:0];
                                    rv_if.tb_sh_count[1]++;
                                end
                                default: begin
                                    prev_ram_data = 32'bx;
                                    rv_if.tb_misalign_count++;
                                end
                            endcase
                        end

                        3'b010: begin
                            if (line == 2'b00) begin
                                prev_ram_data = ram_wdata;
                                rv_if.tb_sw_count++;
                            end else begin
                                prev_ram_data = 32'bx;
                                rv_if.tb_misalign_count++;
                            end
                        end
                        default: begin
                            prev_ram_data = 32'bx;
                            rv_if.tb_misalign_count++;
                        end
                    endcase

                    tr.expected_data = prev_ram_data;
                    tr.receive_data  = rv_if.tb_ram_data;
                    mon2scb.put(tr);
                    tr.display("[MON]");
                end

            end else if (tr.opcode == OP_IL) begin

                bit [31:0] load_ram_data;
                #0;
                load_ram_data = rv_if.tb_ram_data;
                line          = rv_if.tb_ram_addr[1:0];
                funct3        = rv_if.tb_funct3;


                if (rv_if.tb_we) begin
                    #1;
                    case (funct3)
                        3'b000: begin  // LB
                            case (line)
                                2'b00: begin
                                    tr.expected_data = {
                                        {24{load_ram_data[7]}},
                                        load_ram_data[7:0]
                                    };
                                    rv_if.tb_lb_count[0]++;
                                end
                                2'b01: begin
                                    tr.expected_data = {
                                        {24{load_ram_data[15]}},
                                        load_ram_data[15:8]
                                    };
                                    rv_if.tb_lb_count[1]++;
                                end
                                2'b10: begin
                                    tr.expected_data = {
                                        {24{load_ram_data[23]}},
                                        load_ram_data[23:16]
                                    };
                                    rv_if.tb_lb_count[2]++;
                                end
                                2'b11: begin
                                    tr.expected_data = {
                                        {24{load_ram_data[31]}},
                                        load_ram_data[31:24]
                                    };
                                    rv_if.tb_lb_count[3]++;
                                end
                            endcase
                        end

                        3'b001: begin  // LH
                            case (line)
                                2'b00: begin
                                    tr.expected_data = {
                                        {16{load_ram_data[15]}},
                                        load_ram_data[15:0]
                                    };
                                    rv_if.tb_lh_count[0]++;
                                end
                                2'b10: begin
                                    tr.expected_data = {
                                        {16{load_ram_data[31]}},
                                        load_ram_data[31:16]
                                    };
                                    rv_if.tb_lh_count[1]++;
                                end
                                default: begin
                                    tr.expected_data = 32'bx;
                                    rv_if.tb_misalign_count++;
                                end
                            endcase
                        end
                        3'b010: begin  //LW
                            rv_if.tb_lw_count++;
                            tr.expected_data = load_ram_data;
                        end
                        3'b100: begin  // LBU
                            case (line)
                                2'b00: begin
                                    tr.expected_data = {
                                        24'b0, load_ram_data[7:0]
                                    };
                                    rv_if.tb_lbu_count[0]++;
                                end
                                2'b01: begin
                                    tr.expected_data = {
                                        24'b0, load_ram_data[15:8]
                                    };
                                    rv_if.tb_lbu_count[1]++;
                                end
                                2'b10: begin
                                    tr.expected_data = {
                                        24'b0, load_ram_data[23:16]
                                    };
                                    rv_if.tb_lbu_count[2]++;
                                end
                                2'b11: begin
                                    tr.expected_data = {
                                        24'b0, load_ram_data[31:24]
                                    };
                                    rv_if.tb_lbu_count[3]++;
                                end
                            endcase
                        end
                        3'b101: begin  // LHU
                            case (line)
                                2'b00: begin
                                    tr.expected_data = {
                                        16'b0, load_ram_data[15:0]
                                    };
                                    rv_if.tb_lhu_count[0]++;
                                end
                                2'b10: begin
                                    tr.expected_data = {
                                        16'b0, load_ram_data[31:16]
                                    };
                                    rv_if.tb_lhu_count[1]++;
                                end
                                default: begin
                                    tr.expected_data = 32'bx;
                                    rv_if.tb_misalign_count++;
                                end
                            endcase
                        end
                        default: tr.expected_data = 32'bx;
                    endcase

                    tr.receive_data = rv_if.tb_reg_data;
                    mon2scb.put(tr);
                    tr.display("[MON]");
                end

            end else begin
                tr.expected_data = 32'bx;
            end

        end
    endtask  //run


endclass  //monitor

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb;
    event scb2env;

    int pass_count, fail_count = 0;
    int total_count = 0;

    function new(mailbox#(transaction) mon2scb, event scb2env);
        this.mon2scb = mon2scb;
        this.scb2env = scb2env;

    endfunction  //new()

    task run();
        forever begin
            mon2scb.get(tr);
            if (tr.expected_data == tr.receive_data) begin
                pass_count++;
                tr.display("[SCB]");

            end else begin
                fail_count++;
                $error(
                    "[SCB] Mismatch instr_code = 0x%08h, expected_data=0x%08h, receive_data=0x%08h",
                    tr.instr_code, tr.expected_data, tr.receive_data);
            end
            ->scb2env;
        end

    endtask  //run

    function int total();
        return pass_count + fail_count;
    endfunction
endclass  //scoreboard

class environment;

    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    virtual rv_if          rv_if;
    event                  scb2env;
    function new(virtual rv_if rv_if);
        this.rv_if = rv_if;
        gen2drv = new;
        mon2scb = new;
        gen = new(gen2drv);
        drv = new(gen2drv, rv_if);
        mon = new(mon2scb, rv_if);
        scb = new(mon2scb, scb2env);
    endfunction  //new()

    // task r_run(int count);  //r-type
    //     begin
    //         gen.r_run(count);
    //     end
    // endtask  //r_run

    // task r_run(int count);  //r-type
    //     begin
    //         gen.r_run(count, 3'b000, 1'b0);  //ADD
    //         gen.r_run(count, 3'b000, 1'b1);  //SUB
    //         gen.r_run(count, 3'b001, 1'b0);  //SLL
    //         gen.r_run(count, 3'b101, 1'b0);  //SRL
    //         gen.r_run(count, 3'b101, 1'b1);  //SRA
    //         gen.r_run(count, 3'b010, 1'b0);  //SLT
    //         gen.r_run(count, 3'b011, 1'b0);  //SLTU
    //         gen.r_run(count, 3'b100, 1'b0);  //XOR
    //         gen.r_run(count, 3'b110, 1'b0);  //OR
    //         gen.r_run(count, 3'b111, 1'b0);  //AND
    //     end
    // endtask  //r_run

    task i_run();
        fork
            drv.run();
            mon.run();
            scb.run();
            gen.i_run(2000);
        join_none
        wait (scb.total() >= 2000);
        $display("[ENV] DONE ADDI=%0d SLLI=%0d SRLI=%0d SRAI=%0d SLTI=%0d ",
                 rv_if.tb_i_count[0], rv_if.tb_i_count[1], rv_if.tb_i_count[2],
                 rv_if.tb_i_count[3], rv_if.tb_i_count[4]);
        $display(
            "[ENV] DONE SLTIU=%0d XORI=%0d ORI=%0d ANDI=%0d TOTAL=%0d",
            rv_if.tb_i_count[5], rv_if.tb_i_count[6], rv_if.tb_i_count[7],
            rv_if.tb_i_count[8],
            rv_if.tb_i_count[0] + rv_if.tb_i_count[1] + rv_if.tb_i_count[2] + rv_if.tb_i_count[3] + rv_if.tb_i_count[4] + rv_if.tb_i_count[5] + rv_if.tb_i_count[6] + rv_if.tb_i_count[7] + rv_if.tb_i_count[8]);
        $display("[ENV] DONE total=%0d pass=%0d fail=%0d", scb.total(),
                 scb.pass_count, scb.fail_count);
        $finish;

    endtask  //run

    // task i_run(int count);  //r-type
    //     begin
    //         gen.i_run(count, 3'b000, 1'b0);  //ADDI
    //         gen.i_run(count, 3'b001, 1'b0);  //SLLI
    //         gen.i_run(count, 3'b101, 1'b0);  //SRLI
    //         gen.i_run(count, 3'b101, 1'b1);  //SRAI
    //         gen.i_run(count, 3'b010, 1'b0);  //SLTI
    //         gen.i_run(count, 3'b011, 1'b0);  //SLTUI
    //         gen.i_run(count, 3'b100, 1'b0);  //XORI
    //         gen.i_run(count, 3'b110, 1'b0);  //ORI
    //         gen.i_run(count, 3'b111, 1'b0);  //ANDI
    //     end
    // endtask  //i_run

    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none
        wait (scb.total() >= 1000);
        $display("[ENV] DONE total=%0d pass=%0d fail=%0d", scb.total(),
                 scb.pass_count, scb.fail_count);
        $finish;

    endtask  //run

    task r_run();
        fork
            drv.run();
            mon.run();
            scb.run();
            gen.r_run(2000);
        join_none
        wait (scb.total() >= 2000);
        $display("[ENV] DONE ADD=%0d SUB=%0d SLL=%0d SRL=%0d SRA=%0d",
                 rv_if.tb_r_count[0], rv_if.tb_r_count[1], rv_if.tb_r_count[2],
                 rv_if.tb_r_count[3], rv_if.tb_r_count[4]);
        $display(
            "[ENV] DONE SLT=%0d SLTU=%0d XOR=%0d OR=%0d AND=%0d TOTAL=%0d",
            rv_if.tb_r_count[5], rv_if.tb_r_count[6], rv_if.tb_r_count[7],
            rv_if.tb_r_count[8], rv_if.tb_r_count[9],
            rv_if.tb_r_count[0] + rv_if.tb_r_count[1] + rv_if.tb_r_count[2] + rv_if.tb_r_count[3] + rv_if.tb_r_count[4] + rv_if.tb_r_count[5] + rv_if.tb_r_count[6] + rv_if.tb_r_count[7] + rv_if.tb_r_count[8] + rv_if.tb_r_count[9]);
        $display("[ENV] DONE total=%0d pass=%0d fail=%0d", scb.total(),
                 scb.pass_count, scb.fail_count);
        $finish;

    endtask  //run

    task il_run();

        localparam int TARGET = 100;

        rv_if.tb_lb_count  = '{default: 0};
        rv_if.tb_lbu_count = '{default: 0};
        rv_if.tb_lh_count  = '{default: 0};
        rv_if.tb_lhu_count = '{default: 0};
        rv_if.tb_lw_count  = 0;

        fork
            drv.run();
            mon.run();
            scb.run();
        join_none

        // LB
        while (!(rv_if.tb_lb_count[0]  >= TARGET &&
           rv_if.tb_lb_count[1]  >= TARGET &&
           rv_if.tb_lb_count[2]  >= TARGET &&
           rv_if.tb_lb_count[3]  >= TARGET)) begin
            gen.il_run(1, 3'b000);
            @(scb2env);
        end

        // LH
        while (!(rv_if.tb_lh_count[0]  >= TARGET &&
           rv_if.tb_lh_count[1]  >= TARGET)) begin
            gen.il_run(1, 3'b001);
            @(scb2env);
        end

        // LW
        while (rv_if.tb_lw_count < TARGET) begin
            gen.il_run(1, 3'b010);
            @(scb2env);
        end

        // LBU
        while (!(rv_if.tb_lbu_count[0] >= TARGET &&
           rv_if.tb_lbu_count[1] >= TARGET &&
           rv_if.tb_lbu_count[2] >= TARGET &&
           rv_if.tb_lbu_count[3] >= TARGET)) begin
            gen.il_run(1, 3'b100);
            @(scb2env);
        end

        // LHU
        while (!(rv_if.tb_lhu_count[0] >= TARGET &&
           rv_if.tb_lhu_count[1] >= TARGET)) begin
            gen.il_run(1, 3'b101);
            @(scb2env);
        end

        $display("[ENV][IL] DONE  LB:%0d/%0d/%0d/%0d", rv_if.tb_lb_count[0],
                 rv_if.tb_lb_count[1], rv_if.tb_lb_count[2],
                 rv_if.tb_lb_count[3]);
        $display("[ENV][IL] DONE  LBU:%0d/%0d/%0d/%0d", rv_if.tb_lbu_count[0],
                 rv_if.tb_lbu_count[1], rv_if.tb_lbu_count[2],
                 rv_if.tb_lbu_count[3]);
        $display("[ENV][IL] DONE  LH:%0d/%0d  LHU:%0d/%0d",
                 rv_if.tb_lh_count[0], rv_if.tb_lh_count[1],
                 rv_if.tb_lhu_count[0], rv_if.tb_lhu_count[1]);
        $display(
            "[ENV][IL] DONE  LW:%0d TOTAL:%0d", rv_if.tb_lw_count,
            rv_if.tb_lb_count[0] + rv_if.tb_lb_count[1] + rv_if.tb_lb_count[2] + rv_if.tb_lb_count[3] + rv_if.tb_lbu_count[0] + rv_if.tb_lbu_count[1] + rv_if.tb_lbu_count[2] + rv_if.tb_lbu_count[3] + rv_if.tb_lh_count[0] + rv_if.tb_lh_count[1] + rv_if.tb_lhu_count[0] + rv_if.tb_lhu_count[1] + rv_if.tb_lw_count);

        $display("[ENV] PASS=%0d FAIL=%0d MISALIGN=%0d TOTAL=%0d",
                 scb.pass_count, scb.fail_count, rv_if.tb_misalign_count,
                 scb.total());
        $finish;
    endtask  //run

    task s_run();

        localparam int TARGET = 100;

        rv_if.tb_sb_count = '{default: 0};
        rv_if.tb_sh_count = '{default: 0};
        rv_if.tb_sw_count = 0;

        fork
            drv.run();
            mon.run();
            scb.run();
        join_none

        // SB
        while (!(rv_if.tb_sb_count[0] >= TARGET &&
             rv_if.tb_sb_count[1] >= TARGET &&
             rv_if.tb_sb_count[2] >= TARGET &&
             rv_if.tb_sb_count[3] >= TARGET)) 
             begin
            gen.s_run(1, 3'b000);
            @(scb2env);
        end

        // SH
        while (!(rv_if.tb_sh_count[0] >= TARGET &&
             rv_if.tb_sh_count[1] >= TARGET)) begin
            gen.s_run(1, 3'b001);
            @(scb2env);
        end

        // SW
        while (rv_if.tb_sw_count < TARGET) begin
            gen.s_run(1, 3'b010);
            @(scb2env);
        end

        $display(
            "[ENV] DONE  SB: 2'b11 = %0d, 2'b10 =%0d, 2'b01 =%0d, 2'b00 =%0d ",
            rv_if.tb_sb_count[0], rv_if.tb_sb_count[1], rv_if.tb_sb_count[2],
            rv_if.tb_sb_count[3]);
        $display(
            "[ENV] DONE  SH: 2'b10 =%0d 2'b00 =%0d SW: 2'b00 =%0d TOTAL=%d",
            rv_if.tb_sh_count[0], rv_if.tb_sh_count[1], rv_if.tb_sw_count,
            rv_if.tb_sb_count[0] + rv_if.tb_sb_count[1] + rv_if.tb_sb_count[2] + rv_if.tb_sb_count[3] + rv_if.tb_sh_count[0] + rv_if.tb_sh_count[1] + rv_if.tb_sw_count);
        $display("[ENV] PASS=%0d FAIL=%0d MISALIGN=%0d TOTAL=%0d",
                 scb.pass_count, scb.fail_count, rv_if.tb_misalign_count,
                 scb.total());
        $finish;
    endtask  //run

endclass  //environment

module tb_verification ();

    rv_if rv_if ();
    environment env;

    RV32I_VERIFI U_dut (
          .clk         (rv_if.clk),
          .reset       (rv_if.reset),
          .instr_code  (rv_if.instr_code),
          .instr_rAddr (rv_if.instr_rAddr)
`ifdef TB,
          .tb_we       (rv_if.tb_we)
        , .tb_alu_a    (rv_if.tb_alu_a)
        , .tb_alu_b    (rv_if.tb_alu_b)
        , .tb_ram_wdata(rv_if.tb_ram_wdata)
        , .tb_ram_addr (rv_if.tb_ram_addr)
        , .tb_funct3   (rv_if.tb_funct3)
        , .tb_ram_data (rv_if.tb_ram_data)
        , .tb_ram_we   (rv_if.tb_ram_we)
        , .tb_reg_data (rv_if.tb_reg_data)
`endif
    );

    always #5 rv_if.clk = ~rv_if.clk;
    initial begin
        rv_if.clk   = 1'b0;
        rv_if.reset = 1'b1;
        repeat (4) @(posedge rv_if.clk);
        rv_if.reset = 1'b0;
        env = new(rv_if);
        env.i_run();

    end
endmodule
