/*
 * SPDX-FileCopyrightText: 2022 Steve Goldsmith, Aurifex Labs LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>
#include <string.h>

int clk = 0;

void pass(int value) {
	reg_mprj_datah = 0x00000019;
	reg_mprj_datal = value;
}

void fail(int value) {
	reg_mprj_datah = 0x0000001a;
	reg_mprj_datal = value;
}

void test() {
	const int EBREAK = 0x00100073;
	const int ECALL = 0x00000073;

	const int romSize = 128;
	const int romAddress = 0x00000400;
	int rom[32];

	// addi r1, r0, 65
	rom[0] = 0x02100093;  // addi r1, r0, 65

	// assert r1 == 65
        rom[4] = 0x02100f93;  // addi r31, r0, 65
	rom[8] = 0x001f8463;  // beq r1, r31, 4
	rom[12] = 0x00000f93;  // addi r31, r0, 5000
	rom[16] = EBREAK;  // ebreak

	// end of program
	rom[20] = 0x00000f93;  // addi r31, r0, 2000
	rom[24] = ECALL;  // ecall

	const int ramSize = 128;
	const int ramAddress = 0x00000800;
	int ram[32];

	int address;
	int dataIn;
	int transactionBegin;
	int writeEnable;
	int writeMask;

	int dataOut;
	int transactionEnd;

	int instructionFetch = 0;

        while (1){
		// toggle clk 1 full cycle
		clk = !clk;
		reg_la3_data = (reg_la3_data & 0x3fffffff) | (clk << 31 & 0xc0000000);
		clk = !clk;
		reg_la3_data = (reg_la3_data & 0x3fffffff) | (clk << 31 & 0xc0000000);

		// DELAY
	        int i;
		for (i=0; i<5; i=i+1) {}

		// read signals
		address = reg_la0_data_in;
		dataIn = reg_la1_data_in;
		transactionBegin = reg_la2_data_in & 0x1;
		writeEnable = reg_la2_data_in >> 1 & 0x1;
		writeMask = reg_la2_data_in >> 2 & 0xf;

		if(transactionBegin) {
			instructionFetch = address >= romAddress && address < romAddress + romSize;
			if(instructionFetch) {
				dataOut = rom[address - romAddress];
			}
			else if(address >= ramAddress && address < ramAddress + ramSize) {
				if(writeEnable) {
					ram[address - ramAddress] = (writeMask & 0x8) ? dataIn & 0xff000000 : 0 |
					(writeMask & 0x4) ? dataIn & 0x00ff0000 : 0 |
					(writeMask & 0x2) ? dataIn & 0x0000ff00 : 0 |
					(writeMask & 0x1) ? dataIn & 0x000000ff : 0;
				} else {
					dataOut = ram[address - ramAddress];
				}
			}
			transactionEnd = 1;

			if(instructionFetch && dataOut == EBREAK) {
				fail(address);
	                	break;
			}
			if(instructionFetch && dataOut == ECALL) {
				pass(address);
	                	break;
			}

	                reg_la0_data = dataOut;
	                reg_la1_data = transactionEnd;
		}
        }
}

void boot() {
        reg_spi_enable = 1;

        reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
        reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

        reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
        reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

        // Apply configuration
        reg_mprj_xfer = 1;
        while (reg_mprj_xfer == 1);

	// Configure All LA probes as inputs to the cpu
	reg_la0_oenb = reg_la0_iena = 0x00000000;    // [31:0]
	reg_la1_oenb = reg_la1_iena = 0x00000000;    // [63:32]
	reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]
	reg_la3_oenb = reg_la3_iena = 0x00000000;    // [127:96]

	// Flag start of the test
	reg_mprj_datah = 0x00000018;
	reg_mprj_datal = 0x00000000;

	// Configure LA[126] and LA[127] as outputs from the cpu
	reg_la3_oenb = reg_la3_iena = 0xc0000000;

	// Set clk & reset to one
	reg_la3_data = 0xc0000000;

	// DELAY
	int i;
        for (i=0; i<5; i=i+1) {}

	// Toggle clk & de-assert reset
	for (i=0; i<11; i=i+1) {
		clk = !clk;
		reg_la3_data = 0x00000000 | clk;
	}
}

void main() {
	boot();
	test();
}
