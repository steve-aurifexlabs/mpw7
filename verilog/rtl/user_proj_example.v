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
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out[127:72] = 58'b0;
    // Assuming LA probes [63:32] are for controlling the count register  
    // assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    cpu #() cpu(
        .clk(clk),
        .rst(rst),
        .address(la_data_out[31:0]),
        .dataIn(la_data_in[31:0]),
        .dataOut(la_data_out[63:32]),
        .writeEnable(la_data_out[66]),
        .writeMask(la_data_out[70:67]),
        .transactionBegin(la_data_out[71]),
        .transactionEnd(la_data_in[32])
    );

endmodule


module cpu(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

	input clk,
	input rst,
	output [31:0] address,
	input [31:0] dataIn,
	output [31:0] dataOut,
	output writeEnable,
	output [3:0] writeMask,
	output transactionBegin,
	input transactionEnd,
);

localparam registerImmediateOpcode = 19;
localparam luiOpcode = 55;
localparam auipcOpcode = 23;
localparam registerRegisterOpcode = 51;
localparam jalOpcode = 111;
localparam jalrOpcode = 103;
localparam branchOpcode = 99;
localparam loadOpcode = 3;
localparam storeOpcode = 35;
localparam addFunc3 = 0;
localparam subFunc3 = 0;
localparam sllFunc3 = 1;
localparam sltFunc3 = 2;
localparam sltuFunc3 = 3;
localparam xorFunc3 = 4;
localparam srlFunc3 = 5;
localparam sraFunc3 = 5;
localparam orFunc3 = 6;
localparam andFunc3 = 7;
localparam lwFunc3 = 2;
localparam lhFunc3 = 1;
localparam lbFunc3 = 0;
localparam lhuFunc3 = 5;
localparam lbuFunc3 = 4;
localparam swFunc3 = 2;
localparam shFunc3 = 1;
localparam sbFunc3 = 0;
localparam addFunc7 = 0;
localparam subFunc7 = 16;
localparam srlFunc7 = 0;
localparam sraFunc7 = 16;
localparam beqFunc3 = 0;
localparam bneFunc3 = 1;
localparam bltFunc3 = 4;
localparam bltuFunc3 = 6;
localparam bgeFunc3 = 5;
localparam bgeuFunc3 = 7;
localparam registerFileAddress = 27'h7000000;

reg [5:0] state;
reg [7:0] counter;
reg [31:0] programCounter;
reg [31:0] instruction;
reg [31:0] register1;
reg [31:0] register2;
reg [31:0] address;
reg [31:0] dataOut;
reg writeEnable;
reg [3:0] writeMask;
reg branchBit;
reg transactionBegin;
reg [31:0] aluOut;

reg [5:0] next_state;
reg [7:0] next_counter;
reg [31:0] next_programCounter;
reg [31:0] next_instruction;
reg [31:0] next_register1;
reg [31:0] next_register2;
reg [31:0] next_address;
reg [31:0] next_dataOut;
reg next_writeEnable;
reg [3:0] next_writeMask;
reg next_branchBit;
reg next_transactionBegin;
reg [31:0] next_aluOut;

always @(posedge clk) begin
	if(rst) begin
		state <= 0;
		counter <= 0;
		programCounter <= 0;
		instruction <= 0;
		register1 <= 0;
		register2 <= 0;
		address <= 0;
		dataOut <= 0;
		writeEnable <= 0;
		writeMask <= 0;
		branchBit <= 0;
		transactionBegin <= 0;
		aluOut <= 0;
	end
	else begin
		state <= next_state;
		counter <= next_counter;
		programCounter <= next_programCounter;
		instruction <= next_instruction;
		register1 <= next_register1;
		register2 <= next_register2;
		address <= next_address;
		dataOut <= next_dataOut;
		writeEnable <= next_writeEnable;
		writeMask <= next_writeMask;
		branchBit <= next_branchBit;
		transactionBegin <= next_transactionBegin;
		aluOut <= next_aluOut;
	end
end

wire [6:0] opcode;
wire [2:0] func3;
wire [6:0] func7;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0] immediate;
wire [4:0] shiftAmount;
wire [31:0] upperImmediate;
wire [31:0] jumpOffset;
wire [31:0] branchOffset;
wire [31:0] loadOffset;
wire [31:0] storeOffset;


// Instruction Decode
assign opcode = instruction[6:0];  /// s2.4 p18
assign func3 = instruction[14:12];  /// s2.4 p18
assign func7 = instruction[31:25];  /// s2.4 p18

assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd = instruction[11:7];

/// Tables of Immediate Formats  f2.3 s2.3 p16, f2.4 s2.3 p17
assign immediate = { instruction[31] * 21, instruction[31:20] };  /// I-immediate  s2.4 p18
assign shiftAmount = instruction[24:20];  /// shmt  s2.4 p18
assign upperImmediate = { instruction[31:12], 12'h000 };  /// U-immediate  s2.4 p19
assign jumpOffset = { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0 };  /// J-immediate  s2.5 p21
assign branchOffset = { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0 };  /// B-immediate  s2.5 p22
assign loadOffset = immediate;  /// I-immediate  s2.6 p24
assign storeOffset = { {21{instruction[31]}}, instruction[30:25], instruction[11:8], instruction[7], 1'b0 };  /// S-immediate  s2.6 p24
			
localparam start = 0;
localparam instructionFetch = 1;
localparam instructionFetchWait = 2;
localparam readR1 = 3;
localparam readR1Wait = 4;
localparam readR1AndR2 = 5;
localparam readR1AndR2R1 = 6;
localparam readR1AndR2R1Wait = 7;
localparam readR1AndR2Rest = 8;
localparam readR1AndR2R2 = 9;
localparam readR1AndR2R2Wait = 10;
localparam writeBack = 11;
localparam writeBackWait = 12;
localparam advanceProgramCounter = 13;
localparam instructionDispatch = 14;
localparam instructionDispatchR1 = 15;
localparam instructionDispatchR1AndR2 = 16;
localparam registerImmediateStart = 17;
localparam loadUpperImmediateStart = 18;
localparam addUpperImmediateToPCStart = 19;
localparam registerRegisterStart = 20;
localparam jumpAndLinkStart = 21;
localparam jumpAndLinkRegisterStart = 22;
localparam jumpAndLink = 23;
localparam branchStart = 24;
localparam branchCalculateTarget = 25;
localparam branchSetProgramCounter = 26;
localparam loadStart = 27;
localparam loadMemoryAccess = 28;
localparam loadMemoryAccessWait = 29;
localparam storeStart = 30;
localparam storeMemoryAccess = 31;
localparam storeMemoryAccessWait = 32;

always @(*) begin
	next_state = state;
	next_counter = counter + 1;
	next_programCounter = programCounter;
	next_instruction = instruction;
	next_register1 = register1;
	next_register2 = register2;
	next_address = address;
	next_dataOut = dataOut;
	next_writeEnable = writeEnable;
	next_writeMask = writeMask;
	next_branchBit = branchBit;
	next_transactionBegin = transactionBegin;
			
	case(state)
		'd0 : begin // start
			next_state = instructionFetch;
		end
		'd1 : begin // instructionFetch
			next_address = programCounter;
			next_transactionBegin = 1;
			next_state = instructionFetchWait;
		end
		'd2 : begin // instructionFetchWait
			next_instruction = dataIn;
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = instructionDispatch;
			end
		end
		'd3 : begin // readR1
			if(rs1 == 0) begin
				next_register1 = 0;
				next_state = instructionDispatchR1;
			end
			else begin
				next_address = { registerFileAddress, rs1 };
				next_transactionBegin = 1;
				next_state = readR1Wait;
			end
		end
		'd4 : begin // readR1Wait
			next_register1 = dataIn;
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = instructionDispatchR1;
			end
		end
		'd5 : begin // readR1AndR2
			next_state = readR1AndR2R1;
		end
		'd6 : begin // readR1AndR2R1
			if(rs1 == 0) begin
				next_register1 = 0;
				next_state = readR1AndR2R2;
			end
			else begin
				next_address = { registerFileAddress, rs1 };
				next_transactionBegin = 1;
				next_state = readR1AndR2R1Wait;
			end
		end
		'd7 : begin // readR1AndR2R1Wait
			next_register1 = dataIn;
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = readR1AndR2Rest;
			end
		end
		'd8 : begin // readR1AndR2Rest
			next_state = readR1AndR2R2;
		end
		'd9 : begin // readR1AndR2R2
			if(rs2 == 0) begin
				next_register2 = 0;
				next_state = instructionDispatchR1AndR2;
			end
			else begin
				next_address = { registerFileAddress, rs2 };
				next_transactionBegin = 1;
				next_state = readR1AndR2R2Wait;
			end
		end
		'd10 : begin // readR1AndR2R2Wait
			next_register2 = dataIn;
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = instructionDispatchR1AndR2;
			end
		end
		'd11 : begin // writeBack
			next_address = { registerFileAddress, rd };
			next_dataOut = aluOut;
			next_writeEnable = 1;
			next_transactionBegin = 1;
			next_state = writeBackWait;
		end
		'd12 : begin // writeBackWait
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = advanceProgramCounter;
			end
		end
		'd13 : begin // advanceProgramCounter
			next_programCounter = programCounter + 4;
			next_state = start;
		end
		'd14 : begin // instructionDispatch
			// Register Immediate Instructions
			if(opcode == registerImmediateOpcode) begin
				next_state = readR1;
			end

			// Upper Immediate Instructions
			else if(opcode == luiOpcode) begin
				next_state = loadUpperImmediateStart;
			end
			else if(opcode == auipcOpcode) begin
				next_state = addUpperImmediateToPCStart;
			end

			// Register Register Instructions
			else if(opcode == registerRegisterOpcode) begin
				next_state = readR1AndR2;
			end

			// Unconditional Jump Instructions
			else if(opcode == jalOpcode) begin
				next_state = jumpAndLinkStart;
			end
			else if(opcode == jalrOpcode) begin
				next_state = readR1;
			end

			// Conditional Branch Instructions
			else if(opcode == branchOpcode) begin
				next_state = readR1AndR2;
			end

			// Load Instructions
			else if(opcode == loadOpcode) begin
				next_state = readR1;
			end

			// Store Instructions
			else if(opcode == storeOpcode) begin
				next_state = readR1AndR2;
			end

			else begin
				next_state = start;
			end
		end
		'd15 : begin // instructionDispatchR1
			// Register Immediate Instructions
			if(opcode == registerImmediateOpcode) begin
				next_state = registerImmediateStart;
			end

			// Unconditional Jump Instructions
			else if(opcode == jalrOpcode) begin
				next_state = jumpAndLinkRegisterStart;
			end

			// Load Instructions
			else if(opcode == loadOpcode) begin
				next_state = loadStart;
			end

			else begin
				next_state = start;
			end
		end
		'd16 : begin // instructionDispatchR1AndR2
			// Register Register Instructions
			if(opcode == registerRegisterOpcode) begin
				next_state = registerRegisterStart;
			end

			// Conditional Branch Instructions
			else if(opcode == branchOpcode) begin
				next_state = branchStart;
			end

			// Store Instructions
			else if(opcode == storeOpcode) begin
				next_state = storeStart;
			end

			else begin
				next_state = start;
			end
		end
		'd17 : begin // registerImmediateStart
			if(func3 == addFunc3 && func7 == addFunc7) begin
				next_aluOut = register1 + immediate;
			end
			else if(func3 == sltFunc3) begin
				next_aluOut = register1 < immediate ? 0 : 1;
			end
			else if(func3 == sltuFunc3) begin
				next_aluOut = register1 - immediate < 128 ? 0 : 1;
			end
			else if(func3 == andFunc3) begin
				next_aluOut = register1 & immediate;
			end
			else if(func3 == orFunc3) begin
				next_aluOut = register1 | immediate;
			end
			else if(func3 == xorFunc3) begin
				next_aluOut = register1 ^ immediate;
			end
			//else if(func3 == subFunc3 && func7 == subFunc7) begin
			//	next_aluOut = register1 - immediate;
			//end
			else if(func3 == sllFunc3) begin
				next_aluOut = register1 << shiftAmount;
			end
			else if(func3 == srlFunc3 && func7 == srlFunc7) begin
				next_aluOut = register1 >> shiftAmount;
			end
			else if(func3 == sraFunc3 && func7 == sraFunc7) begin
				next_aluOut = register1 >>> shiftAmount;
			end
			else begin
				next_aluOut = 0;
			end

			next_state = writeBack;
		end
		'd18 : begin // loadUpperImmediateStart
			next_aluOut = upperImmediate;
			next_state = writeBack;
		end
		'd19 : begin // addUpperImmediateToPCStart
			next_aluOut = upperImmediate + programCounter;
			next_state = writeBack;
		end
		'd20 : begin // registerRegisterStart
			if(func3 == addFunc3 && func7 == addFunc7) begin
				next_aluOut = register1 + register2;
			end
			else if(func3 == sltFunc3) begin
				next_aluOut = register1 < register2 ? 0 : 1;
			end
			else if(func3 == sltuFunc3) begin
				next_aluOut = register1 - register2 < 128 ? 0 : 1;
			end
			else if(func3 == andFunc3) begin
				next_aluOut = register1 & register2;
			end
			else if(func3 == orFunc3) begin
				next_aluOut = register1 | register2;
			end
			else if(func3 == xorFunc3) begin
				next_aluOut = register1 ^ register2;
			end
			else if(func3 == subFunc3 && func7 == subFunc7) begin
				next_aluOut = register1 - register2;
			end
			else if(func3 == sllFunc3) begin
				next_aluOut = register1 << register2[4:0];
			end
			else if(func3 == srlFunc3 && func7 == srlFunc7) begin
				next_aluOut = register1 >> register2[4:0];
			end
			else if(func3 == sraFunc3 && func7 == sraFunc7) begin
				next_aluOut = register1 >>> register2[4:0];
			end
			else begin
				next_aluOut = 0;
			end

			next_state = writeBack;
		end
		'd21 : begin // jumpAndLinkStart
			next_aluOut = programCounter + jumpOffset;
			next_state = jumpAndLink;
		end
		'd22 : begin // jumpAndLinkRegisterStart
			next_aluOut = register1 + jumpOffset;
			next_state = jumpAndLink;
		end
		'd23 : begin // jumpAndLink
			next_programCounter = aluOut;
			next_aluOut = programCounter;
			next_state = writeBack;
		end
		'd24 : begin // branchStart
			next_aluOut = register1 - register2;
			next_state = branchCalculateTarget;
		end
		'd25 : begin // branchCalculateTarget
			if(func3 == beqFunc3) begin
				next_branchBit = (aluOut == 0);
			end
			else if(func3 == bneFunc3) begin
				next_branchBit = (aluOut != 0);
			end
			else if(func3 == bltFunc3) begin
				next_branchBit = aluOut[31];
			end
			else if(func3 == bltuFunc3) begin
				next_branchBit = aluOut[31]; // TODO - unsigned
			end
			else if(func3 == bgeFunc3) begin
				next_branchBit = aluOut[31] && (aluOut != 0);
			end
			else if(func3 == bgeuFunc3) begin
				next_branchBit = aluOut[31] && (aluOut != 0);  // TODO - unsigned
			end
			else begin
				next_branchBit = 0;
			end

			next_aluOut = programCounter + branchOffset;
			next_state = branchSetProgramCounter;
		end
		'd26 : begin // branchSetProgramCounter
			next_programCounter = branchBit ? programCounter + 4 : aluOut;
			next_state = start;
		end
		'd27 : begin // loadStart
			next_aluOut = register1 + loadOffset;
			next_state = loadMemoryAccess;
		end
		'd28 : begin // loadMemoryAccess
			next_address = aluOut;
			next_transactionBegin = 1;
			next_state = loadMemoryAccessWait;
		end
		'd29 : begin // loadMemoryAccessWait
			if(func3 == lbFunc3) begin
				next_aluOut = { 24'h000000, dataIn[7:0] };
			end
			else if(func3 == lhFunc3) begin
				next_aluOut = { 16'h0000, dataIn[15:0] };
			end
			else if(func3 == lbuFunc3) begin
				next_aluOut = { {24{dataIn[7]}}, dataIn[7:0] };
			end
			else if(func3 == lhuFunc3) begin
				next_aluOut = { {16{dataIn[15]}}, dataIn[15:0] };
			end
			else if(func3 == lwFunc3) begin
				next_aluOut = dataIn;
			end
			else begin
				next_aluOut = dataIn;
			end

			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = writeBack;
			end
		end
		'd30 : begin // storeStart
			next_aluOut = register1 + storeOffset;
			next_state = storeMemoryAccess;
		end
		'd31 : begin // storeMemoryAccess
			next_address = aluOut;
			next_dataOut = register2;
			next_writeEnable = 1;
			if(func3 == sbFunc3) begin
				next_writeMask = 1;
			end
			else if(func3 == shFunc3) begin
				next_writeMask = 3;
			end
			else if(func3 == swFunc3) begin
				next_writeMask = 15;
			end
			else begin
				next_writeMask = 0;
			end
			next_transactionBegin = 1;
			next_state = storeMemoryAccessWait;
		end
		'd32 : begin // storeMemoryAccessWait
			next_transactionBegin = 0;
			if(transactionEnd == 1) begin
				next_state = advanceProgramCounter;
			end
		end
	endcase
end

endmodule


module counter #(
    parameter BITS = 32
)(
    input clk,
    input reset,
    input valid,
    input [3:0] wstrb,
    input [BITS-1:0] wdata,
    input [BITS-1:0] la_write,
    input [BITS-1:0] la_input,
    output ready,
    output [BITS-1:0] rdata,
    output [BITS-1:0] count
);
    reg ready;
    reg [BITS-1:0] count;
    reg [BITS-1:0] rdata;

    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            ready <= 0;
        end else begin
            ready <= 1'b0;
            if (~|la_write) begin
                count <= count + 1;
            end
            if (valid && !ready) begin
                ready <= 1'b1;
                rdata <= count;
                if (wstrb[0]) count[7:0]   <= wdata[7:0];
                if (wstrb[1]) count[15:8]  <= wdata[15:8];
                if (wstrb[2]) count[23:16] <= wdata[23:16];
                if (wstrb[3]) count[31:24] <= wdata[31:24];
            end else if (|la_write) begin
                count <= la_write & la_input;
            end
        end
    end

endmodule
`default_nettype wire
