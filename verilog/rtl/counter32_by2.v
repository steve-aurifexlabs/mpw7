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
 * counter32_by2_module
 *
 * Counts by 2
 *
 *-------------------------------------------------------------
 */

module counter32_by2_module (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input wire clk,
    input wire rst,

    // Logic Analyzer Signals
    input wire [31:0] debugDriver0_i,
    input wire [31:0] debugDriver1_i,
    input wire [31:0] debugDriver2_i,
    
    output wire [31:0] debugProbe0_o,
    output wire [31:0] debugProbe1_o,
    output wire [31:0] debugProbe2_o,
    
    input wire [31:0] debugControl0_i,
    input wire [31:0] debugControl1_i,
    input wire [31:0] debugControl2_i,

    // Add inter-module wires here
    // input [31:0] busAddress_i,
    // output [31:0] busDataOut_o,

    // Add io here and directly in user_project_wrapper
    // input rx_i,
    // output [2:0] rgbLed_o,
);

    counter #(
        .WIDTH(32),
        .INCREMENT_AMOUNT(2)
    ) counter_instance (
        .clk(clk),
        .rst(rst),

        .set_i(debugControl0_i[0]),
        .setValue_i(debugDriver0_i),
        .count_o(debugProbe0_o),
    );

endmodule

`default_nettype wire
