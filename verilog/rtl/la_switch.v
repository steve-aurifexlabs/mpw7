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
 * counter
 *
 *
 * A simple settable counter
 *
 *-------------------------------------------------------------
 */

module la_switch #(
    parameter WIDTH = 128,
)(
    // External Clock and Reset
    input externalClock,
    input externalReset,

    // Manually controlled by caravel cpu - see C tests in verilog/dv (testbenches)
    input testClock,
    input testReset,

    input clockSelect,
);

// Assuming LA probes [65:64] are for controlling the count clk & reset
    assign clockSelect = ~la_oenb[64];
    assign clk = clockSelect ? testRest : externalClock;
    assign rst = la_data_in[65];

    reg [BITS-1:0] count_r;
    assign count_o <= count_r;

    always @(posedge clk) begin
        if (rst) begin
            count_r <= 0;
        end
        
        else begin
            count_r <= next_count;
        end
    end

    always @(*) begin
        if(set) begin
            next_count = setValue_i;
        else begin
            next_count = count_r + INCREMENT_AMOUNT;
        end
    end
endmodule

`default_nettype wire
