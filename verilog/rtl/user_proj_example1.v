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

module user_proj_example1 #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,

    // IOs
    input  [11:0] io_in,
    output [11:0] io_out,
    output [11:0] io_oeb
);
   
    wire [7:0] seven_seg;
    wire [3:0]  digit_en;
    Clock_part1 Clock_part1(
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .seven_seg(seven_seg),
        .digit_en(digit_en)
    );

    assign io_oeb = 12'b0;
    assign io_out = {seven_seg,digit_en};

endmodule

