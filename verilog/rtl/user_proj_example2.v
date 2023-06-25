// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 *-------------------------------------------------------------
 */

module user_proj_example2 #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    // IOs
    input  [11:0] io_in,
    output [11:0] io_out,
    output [11:0] io_oeb,
    // irq 
    output irq
);
   
    wire [7:0] seven_seg;
    wire [3:0]  digit_en;
    Clock_part2 Clock_part2(
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .wb_adr_i(wbs_adr_i[3:0]),
        .wb_dat_i(wbs_dat_i),
        .wb_dat_o(wbs_dat_o),
        .wb_sel_i(wbs_sel_i),
        .wb_cyc_i(wbs_cyc_i),
        .wb_stb_i(wbs_stb_i),
        .wb_ack_o(wbs_ack_o),
        .wb_we_i(wbs_we_i),
        .seven_seg(seven_seg),
        .digit_en(digit_en),
        .irq(irq)
    );

    assign io_oeb = 12'b0;
    assign io_out = {seven_seg,digit_en};

endmodule

