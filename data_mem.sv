`timescale 1ns / 1ps

`include "define.sv"
`define TB

module data_mem (
    input  logic        clk,
    input  logic        d_wr_en,
    input  logic [31:0] dAddr,
    input  logic [31:0] dWdata,
    input  logic [ 2:0] d_func3,
    output logic [31:0] dRdata

`ifdef TB
    ,output logic [31:0] tb_ram_data
`endif

);

    wire [5:0] ram_addr = dAddr[31:2];
    wire [1:0] ram_line = dAddr[1:0];

    logic [31:0] data_mem[0:1023];

`ifdef TB
    assign tb_ram_data = data_mem[ram_addr];
`endif
`ifdef TB
    initial begin  
        for (int i = 0; i < 64; i++) begin
            data_mem[i][7:0]    = 8'h80 | ((i<<2) + 8'd0);
            data_mem[i][15:8]   = 8'h80 | ((i<<2) + 8'd1);
            data_mem[i][23:16]  = 8'h80 | ((i<<2) + 8'd2);
            data_mem[i][31:24]  = 8'h80 | ((i<<2) + 8'd3);
        end
    end
`endif
    always_ff @(posedge clk) begin
        if (d_wr_en) begin
            case (d_func3)
                `SB: begin
                    case (ram_line)
                        2'b00: data_mem[ram_addr][7:0] <= dWdata[7:0];
                        2'b01: data_mem[ram_addr][15:8] <= dWdata[7:0];
                        2'b10: data_mem[ram_addr][23:16] <= dWdata[7:0];
                        2'b11: data_mem[ram_addr][31:24] <= dWdata[7:0];
                    endcase
                end
                `SH: begin
                    case (ram_line)
                        2'b00:   data_mem[ram_addr][15:0] <= dWdata[15:0];
                        2'b10:   data_mem[ram_addr][31:16] <= dWdata[15:0];
                        default: ;
                    endcase
                end
                `SW: begin
                    if (ram_line == 2'b00) data_mem[ram_addr] <= dWdata;
                    else;
                end
                default: ;
            endcase
        end
    end

    always_comb begin
        case (d_func3)
            `LB: begin
                case (ram_line)
                    2'b00:
                    dRdata = {
                        {24{data_mem[ram_addr][7]}}, data_mem[ram_addr][7:0]
                    };
                    2'b01:
                    dRdata = {
                        {24{data_mem[ram_addr][15]}}, data_mem[ram_addr][15:8]
                    };
                    2'b10:
                    dRdata = {
                        {24{data_mem[ram_addr][23]}}, data_mem[ram_addr][23:16]
                    };
                    2'b11:
                    dRdata = {
                        {24{data_mem[ram_addr][31]}}, data_mem[ram_addr][31:24]
                    };
                endcase
            end
            `LH: begin
                case (ram_line)
                    2'b00:
                    dRdata = {
                        {16{data_mem[ram_addr][15]}}, data_mem[ram_addr][15:0]
                    };
                    2'b10:
                    dRdata = {
                        {16{data_mem[ram_addr][31]}}, data_mem[ram_addr][31:16]
                    };
                    default: dRdata = data_mem[ram_addr];
                endcase
            end
            `LW:
            if (ram_line == 2'b00) dRdata = data_mem[ram_addr];
            else dRdata = data_mem[ram_addr];
            `LBU: begin
                case (ram_line)
                    2'b00: dRdata = {24'b0, data_mem[ram_addr][7:0]};
                    2'b01: dRdata = {24'b0, data_mem[ram_addr][15:8]};
                    2'b10: dRdata = {24'b0, data_mem[ram_addr][23:16]};
                    2'b11: dRdata = {24'b0, data_mem[ram_addr][31:24]};
                endcase
            end
            `LHU: begin
                case (ram_line)
                    2'b00:   dRdata = {16'b0, data_mem[ram_addr][15:0]};
                    2'b10:   dRdata = {16'b0, data_mem[ram_addr][31:16]};
                    default: dRdata = data_mem[ram_addr];
                endcase
            end
            default: dRdata = data_mem[ram_addr];
        endcase
    end

endmodule

//     always_ff @(posedge clk) begin
//     if (d_wr_en) begin
//         case (d_func3)
//             `SB: begin
//                 if (ram_line == 2'b00)
//                     data_mem[ram_addr][7:0] <= dWdata[7:0];
//                 else if (ram_line == 2'b01)
//                     data_mem[ram_addr][15:8] <= dWdata[7:0];
//                 else if (ram_line == 2'b10)
//                     data_mem[ram_addr][23:16] <= dWdata[7:0];
//                 else data_mem[ram_addr][31:24] <= dWdata[7:0];
//             end
//             `SH: begin
//                 if (ram_line == 2'b00)
//                     data_mem[ram_addr][15:0] <= dWdata[15:0];
//                 else if (ram_line == 2'b10)
//                     data_mem[ram_addr][31:16] <= dWdata[15:0];
//                 else data_mem[ram_addr] <= data_mem[ram_addr];

//             end
//             `SW: begin
//                 if (ram_line == 2'b00) data_mem[ram_addr] <= dWdata;
//                 else data_mem[ram_addr] <= data_mem[ram_addr];
//             end
//             // default: data_mem[ram_addr] <= dWdata;
//         endcase
//     end
// end

// always_ff @(posedge clk) begin
//     if (d_wr_en) begin
//         case (d_func3)
//             `SB: begin
//                 if (ram_line == 0) data_mem[ram_addr] <= {data_mem[ram_addr][31:8], dWdata[7:0]};
//                 else if (ram_line == 1) data_mem[ram_addr] <= {data_mem[ram_addr][31:16], dWdata[7:0], data_mem[ram_addr][7:0]};
//                 else if (ram_line == 2) data_mem[ram_addr] <= {data_mem[ram_addr][31:24], dWdata[7:0], data_mem[ram_addr][15:0]};
//                 else data_mem[ram_addr] <= {dWdata[7:0], data_mem[ram_addr][23:0]};
//             end
//             `SH:begin 
//                 if (ram_line == 2'b00) data_mem[ram_addr] <= {data_mem[ram_addr][31:16], dWdata[15:0]};
//                 else if (ram_line == 2'b10) data_mem[ram_addr] <= {dWdata[15:0], data_mem[ram_addr][15:0]};
//                 else data_mem[ram_addr] <= data_mem[ram_addr];

//             end
//             `SW: begin 
//             if (ram_line == 2'b00) data_mem[ram_addr] <= dWdata;
//                 else data_mem[ram_addr] <= data_mem[ram_addr];
//             end 
//             // default: data_mem[ram_addr] <= dWdata;
//         endcase
//     end
// end







// module data_mem (
//     input  logic        clk,
//     input  logic        d_wr_en,
//     input  logic [31:0] dAddr,
//     input  logic [31:0] dWdata,
//     input  logic [ 2:0] d_func3,
//     output logic [31:0] dRdata
// );

//     logic [31:0] data_mem[0:63];

//     initial begin
//         for (int i = 0; i < 16; i++) begin
//             data_mem[i] = i + 32'h8765_4321;
//         end
//         data_mem[14] = 32'b1111_1111_0000_0000_1000_0000_1000_1010;
//     end

//     always_ff @(posedge clk) begin
//         if (d_wr_en) begin
//             case (d_func3)
//                 `SB: data_mem[dAddr] <= {data_mem[dAddr][31:8], dWdata[7:0]};
//                 `SH: data_mem[dAddr] <= {data_mem[dAddr][31:16], dWdata[15:0]};
//                 `SW: data_mem[dAddr] <= dWdata;
//                 default: data_mem[dAddr] <= dWdata;
//             endcase
//         end
//     end

//     always_comb begin
//         case (d_func3)
//             `LB: dRdata = {{24{data_mem[dAddr][7]}}, data_mem[dAddr][7:0]};
//             `LH: dRdata = {{16{data_mem[dAddr][15]}}, data_mem[dAddr][15:0]};
//             `LW: dRdata = data_mem[dAddr];
//             `LBU: dRdata = {24'b0, data_mem[dAddr][7:0]};
//             `LHU: dRdata = {16'b0, data_mem[dAddr][15:0]};
//             default: dRdata = data_mem[dAddr];
//         endcase
//     end

// endmodule
