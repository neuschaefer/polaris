`timescale 1ns / 1ps

// This module verifies correct register file behavior.

module test_alu();
	reg clk_o;
	reg reset_o;
	reg [15:0] story_o;
	reg [63:0] inA_o, inB_o;
	reg cflag_o;
	wire [63:0] out_i;
	wire nflag_i, vflag_i, zflag_i, cflag_i;
	reg sum_en_o;
	reg and_en_o;
	reg xor_en_o;
	reg invB_en_o;

	alu a(
		.inA_i(inA_o),
		.inB_i(inB_o),
		.cflag_i(cflag_o),
		.out_o(out_i),
		.vflag_o(vflag_i),
		.cflag_o(cflag_i),
		.zflag_o(zflag_i),
		.sum_en_i(sum_en_o),
		.and_en_i(and_en_o),
		.xor_en_i(xor_en_o),
		.invB_en_i(invB_en_o)
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		@(posedge clk_o);
		@(negedge clk_o);
	end
	endtask

	task assert_out;
	input [63:0] expected;
	begin
		if(expected !== out_i) begin
			$display("@E %04X OUT_O Expected $%016X, got $%016X", story_o, expected, out_i);
			$stop;
		end
	end
	endtask

	task assert_v;
	input expected;
	begin
		if(expected !== vflag_i) begin
			$display("@E %04X VFLAG_O Expected %d, got %d", story_o, expected, vflag_i);
			$stop;
		end
	end
	endtask

	task assert_c;
	input expected;
	begin
		if(expected !== cflag_i) begin
			$display("@E %04X CFLAG_O Expected %d, got %d", story_o, expected, cflag_i);
			$stop;
		end
	end
	endtask

	task assert_z;
	input expected;
	begin
		if(expected !== zflag_i) begin
			$display("@E %04X ZFLAG_O Expected %d, got %d", story_o, expected, zflag_i);
			$stop;
		end
	end
	endtask

	task check_sum_bit;
	input [15:0] story;
	input [63:0] base;
	input cin;
	input carry;
	input overflow;
	input zero;
	begin
		inA_o <= base;
		inB_o <= base;
		cflag_o <= cin;
		invB_en_o <= 0;
		sum_en_o <= 1;
		and_en_o <= 0;
		xor_en_o <= 0;
		tick(story);
		assert_out({base[62:0], cin});
		assert_c(carry);
		assert_v(overflow);
		assert_z(zero);
	end
	endtask

	task check_diff_bit;
	input [15:0] story;
	input [63:0] base;
	input carry;
	input overflow;
	input zero;
	begin
		inA_o <= base;
		inB_o <= base;
		cflag_o <= 1;
		invB_en_o <= 1;
		sum_en_o <= 1;
		and_en_o <= 0;
		xor_en_o <= 0;
		tick(story);
		assert_out(0);
		assert_c(carry);
		assert_v(overflow);
		assert_z(zero);
	end
	endtask

	task check_and;
	input [15:0] story;
	input [63:0] base;
	begin
		inA_o <= 64'hFFFF_FFFF_FFFF_FFFF;
		inB_o <= base;
		sum_en_o <= 0;
		and_en_o <= 1;
		xor_en_o <= 0;
		tick(story);
		assert_out(base);
	end
	endtask

	task check_xor;
	input [15:0] story;
	input [63:0] base;
	begin
		inA_o <= 64'h0000_0000_0000_0000;
		inB_o <= base;
		sum_en_o <= 0;
		and_en_o <= 0;
		xor_en_o <= 1;
		tick(story);
		assert_out(base);

		inA_o <= base;
		inB_o <= base;
		sum_en_o <= 0;
		and_en_o <= 0;
		xor_en_o <= 1;
		tick(story | 16'h8000);
		assert_out(0);
	end
	endtask

	task check_or;
	input [15:0] story;
	input [63:0] base;
	begin
		inA_o <= 64'h0000_0000_0000_0000;
		inB_o <= base;
		sum_en_o <= 0;
		and_en_o <= 1;
		xor_en_o <= 1;
		tick(story);
		assert_out(base);

		inA_o <= 64'hFFFF_FFFF_FFFF_FFFF;
		inB_o <= base;
		sum_en_o <= 0;
		and_en_o <= 1;
		xor_en_o <= 1;
		tick(story | 16'h8000);
		assert_out(64'hFFFF_FFFF_FFFF_FFFF);
	end
	endtask

	initial begin
		clk_o <= 0;

		// We expect the ALU to add two 64-bit numbers, and a carry bit.

		check_sum_bit(16'h0000, 64'h0000_0000_0000_0001, 0, 0, 0, 0);
		check_sum_bit(16'h0001, 64'h0000_0000_0000_0002, 0, 0, 0, 0);
		check_sum_bit(16'h0002, 64'h0000_0000_0000_0004, 0, 0, 0, 0);
		check_sum_bit(16'h0003, 64'h0000_0000_0000_0008, 0, 0, 0, 0);

		check_sum_bit(16'h0004, 64'h0000_0000_0000_0010, 0, 0, 0, 0);
		check_sum_bit(16'h0005, 64'h0000_0000_0000_0020, 0, 0, 0, 0);
		check_sum_bit(16'h0006, 64'h0000_0000_0000_0040, 0, 0, 0, 0);
		check_sum_bit(16'h0007, 64'h0000_0000_0000_0080, 0, 0, 0, 0);

		check_sum_bit(16'h0008, 64'h0000_0000_0000_0100, 0, 0, 0, 0);
		check_sum_bit(16'h0009, 64'h0000_0000_0000_0200, 0, 0, 0, 0);
		check_sum_bit(16'h000A, 64'h0000_0000_0000_0400, 0, 0, 0, 0);
		check_sum_bit(16'h000B, 64'h0000_0000_0000_0800, 0, 0, 0, 0);

		check_sum_bit(16'h000C, 64'h0000_0000_0000_1000, 0, 0, 0, 0);
		check_sum_bit(16'h000D, 64'h0000_0000_0000_2000, 0, 0, 0, 0);
		check_sum_bit(16'h000E, 64'h0000_0000_0000_4000, 0, 0, 0, 0);
		check_sum_bit(16'h000F, 64'h0000_0000_0000_8000, 0, 0, 0, 0);

		check_sum_bit(16'h0010, 64'h0000_0000_0001_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0011, 64'h0000_0000_0002_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0012, 64'h0000_0000_0004_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0013, 64'h0000_0000_0008_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0014, 64'h0000_0000_0010_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0015, 64'h0000_0000_0020_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0016, 64'h0000_0000_0040_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0017, 64'h0000_0000_0080_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0018, 64'h0000_0000_0100_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0019, 64'h0000_0000_0200_0000, 0, 0, 0, 0);
		check_sum_bit(16'h001A, 64'h0000_0000_0400_0000, 0, 0, 0, 0);
		check_sum_bit(16'h001B, 64'h0000_0000_0800_0000, 0, 0, 0, 0);

		check_sum_bit(16'h001C, 64'h0000_0000_1000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h001D, 64'h0000_0000_2000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h001E, 64'h0000_0000_4000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h001F, 64'h0000_0000_8000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0020, 64'h0000_0001_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0021, 64'h0000_0002_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0022, 64'h0000_0004_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0023, 64'h0000_0008_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0024, 64'h0000_0010_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0025, 64'h0000_0020_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0026, 64'h0000_0040_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0027, 64'h0000_0080_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0028, 64'h0000_0100_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0029, 64'h0000_0200_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h002A, 64'h0000_0400_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h002B, 64'h0000_0800_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h002C, 64'h0000_1000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h002D, 64'h0000_2000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h002E, 64'h0000_4000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h002F, 64'h0000_8000_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0030, 64'h0001_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0031, 64'h0002_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0032, 64'h0004_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0033, 64'h0008_0000_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0034, 64'h0010_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0035, 64'h0020_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0036, 64'h0040_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0037, 64'h0080_0000_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h0038, 64'h0100_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h0039, 64'h0200_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h003A, 64'h0400_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h003B, 64'h0800_0000_0000_0000, 0, 0, 0, 0);

		check_sum_bit(16'h003C, 64'h1000_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h003D, 64'h2000_0000_0000_0000, 0, 0, 0, 0);
		check_sum_bit(16'h003E, 64'h4000_0000_0000_0000, 0, 0, 1, 0);
		check_sum_bit(16'h003F, 64'h8000_0000_0000_0000, 0, 1, 1, 1);

		check_sum_bit(16'h0100, 64'h0000_0000_0000_0001, 1, 0, 0, 0);
		check_sum_bit(16'h0101, 64'h0000_0000_0000_0002, 1, 0, 0, 0);
		check_sum_bit(16'h0102, 64'h0000_0000_0000_0004, 1, 0, 0, 0);
		check_sum_bit(16'h0103, 64'h0000_0000_0000_0008, 1, 0, 0, 0);

		check_sum_bit(16'h0104, 64'h0000_0000_0000_0010, 1, 0, 0, 0);
		check_sum_bit(16'h0105, 64'h0000_0000_0000_0020, 1, 0, 0, 0);
		check_sum_bit(16'h0106, 64'h0000_0000_0000_0040, 1, 0, 0, 0);
		check_sum_bit(16'h0107, 64'h0000_0000_0000_0080, 1, 0, 0, 0);

		check_sum_bit(16'h0108, 64'h0000_0000_0000_0100, 1, 0, 0, 0);
		check_sum_bit(16'h0109, 64'h0000_0000_0000_0200, 1, 0, 0, 0);
		check_sum_bit(16'h010A, 64'h0000_0000_0000_0400, 1, 0, 0, 0);
		check_sum_bit(16'h010B, 64'h0000_0000_0000_0800, 1, 0, 0, 0);

		check_sum_bit(16'h010C, 64'h0000_0000_0000_1000, 1, 0, 0, 0);
		check_sum_bit(16'h010D, 64'h0000_0000_0000_2000, 1, 0, 0, 0);
		check_sum_bit(16'h010E, 64'h0000_0000_0000_4000, 1, 0, 0, 0);
		check_sum_bit(16'h010F, 64'h0000_0000_0000_8000, 1, 0, 0, 0);

		check_sum_bit(16'h0110, 64'h0000_0000_0001_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0111, 64'h0000_0000_0002_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0112, 64'h0000_0000_0004_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0113, 64'h0000_0000_0008_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0114, 64'h0000_0000_0010_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0115, 64'h0000_0000_0020_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0116, 64'h0000_0000_0040_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0117, 64'h0000_0000_0080_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0118, 64'h0000_0000_0100_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0119, 64'h0000_0000_0200_0000, 1, 0, 0, 0);
		check_sum_bit(16'h011A, 64'h0000_0000_0400_0000, 1, 0, 0, 0);
		check_sum_bit(16'h011B, 64'h0000_0000_0800_0000, 1, 0, 0, 0);

		check_sum_bit(16'h011C, 64'h0000_0000_1000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h011D, 64'h0000_0000_2000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h011E, 64'h0000_0000_4000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h011F, 64'h0000_0000_8000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0120, 64'h0000_0001_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0121, 64'h0000_0002_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0122, 64'h0000_0004_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0123, 64'h0000_0008_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0124, 64'h0000_0010_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0125, 64'h0000_0020_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0126, 64'h0000_0040_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0127, 64'h0000_0080_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0128, 64'h0000_0100_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0129, 64'h0000_0200_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h012A, 64'h0000_0400_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h012B, 64'h0000_0800_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h012C, 64'h0000_1000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h012D, 64'h0000_2000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h012E, 64'h0000_4000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h012F, 64'h0000_8000_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0130, 64'h0001_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0131, 64'h0002_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0132, 64'h0004_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0133, 64'h0008_0000_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0134, 64'h0010_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0135, 64'h0020_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0136, 64'h0040_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0137, 64'h0080_0000_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h0138, 64'h0100_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h0139, 64'h0200_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h013A, 64'h0400_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h013B, 64'h0800_0000_0000_0000, 1, 0, 0, 0);

		check_sum_bit(16'h013C, 64'h1000_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h013D, 64'h2000_0000_0000_0000, 1, 0, 0, 0);
		check_sum_bit(16'h013E, 64'h4000_0000_0000_0000, 1, 0, 1, 0);
		check_sum_bit(16'h013F, 64'h8000_0000_0000_0000, 1, 1, 1, 0);

		// We also expect our ALU to perform bitwise operations as well.

		check_and(16'h0200, 64'h0000_0000_0000_0001);
		check_and(16'h0201, 64'h0000_0000_0000_0002);
		check_and(16'h0202, 64'h0000_0000_0000_0004);
		check_and(16'h0203, 64'h0000_0000_0000_0008);

		check_and(16'h0204, 64'h0000_0000_0000_0010);
		check_and(16'h0205, 64'h0000_0000_0000_0020);
		check_and(16'h0206, 64'h0000_0000_0000_0040);
		check_and(16'h0207, 64'h0000_0000_0000_0080);

		check_and(16'h0208, 64'h0000_0000_0000_0100);
		check_and(16'h0209, 64'h0000_0000_0000_0200);
		check_and(16'h020A, 64'h0000_0000_0000_0400);
		check_and(16'h020B, 64'h0000_0000_0000_0800);

		check_and(16'h020C, 64'h0000_0000_0000_1000);
		check_and(16'h020D, 64'h0000_0000_0000_2000);
		check_and(16'h020E, 64'h0000_0000_0000_4000);
		check_and(16'h020F, 64'h0000_0000_0000_8000);

		check_and(16'h0210, 64'h0000_0000_0001_0000);
		check_and(16'h0211, 64'h0000_0000_0002_0000);
		check_and(16'h0212, 64'h0000_0000_0004_0000);
		check_and(16'h0213, 64'h0000_0000_0008_0000);

		check_and(16'h0214, 64'h0000_0000_0010_0000);
		check_and(16'h0215, 64'h0000_0000_0020_0000);
		check_and(16'h0216, 64'h0000_0000_0040_0000);
		check_and(16'h0217, 64'h0000_0000_0080_0000);

		check_and(16'h0218, 64'h0000_0000_0100_0000);
		check_and(16'h0219, 64'h0000_0000_0200_0000);
		check_and(16'h021A, 64'h0000_0000_0400_0000);
		check_and(16'h021B, 64'h0000_0000_0800_0000);

		check_and(16'h021C, 64'h0000_0000_1000_0000);
		check_and(16'h021D, 64'h0000_0000_2000_0000);
		check_and(16'h021E, 64'h0000_0000_4000_0000);
		check_and(16'h021F, 64'h0000_0000_8000_0000);

		check_and(16'h0220, 64'h0000_0001_0000_0000);
		check_and(16'h0221, 64'h0000_0002_0000_0000);
		check_and(16'h0222, 64'h0000_0004_0000_0000);
		check_and(16'h0223, 64'h0000_0008_0000_0000);

		check_and(16'h0224, 64'h0000_0010_0000_0000);
		check_and(16'h0225, 64'h0000_0020_0000_0000);
		check_and(16'h0226, 64'h0000_0040_0000_0000);
		check_and(16'h0227, 64'h0000_0080_0000_0000);

		check_and(16'h0228, 64'h0000_0100_0000_0000);
		check_and(16'h0229, 64'h0000_0200_0000_0000);
		check_and(16'h022A, 64'h0000_0400_0000_0000);
		check_and(16'h022B, 64'h0000_0800_0000_0000);

		check_and(16'h022C, 64'h0000_1000_0000_0000);
		check_and(16'h022D, 64'h0000_2000_0000_0000);
		check_and(16'h022E, 64'h0000_4000_0000_0000);
		check_and(16'h022F, 64'h0000_8000_0000_0000);

		check_and(16'h0230, 64'h0001_0000_0000_0000);
		check_and(16'h0231, 64'h0002_0000_0000_0000);
		check_and(16'h0232, 64'h0004_0000_0000_0000);
		check_and(16'h0233, 64'h0008_0000_0000_0000);

		check_and(16'h0234, 64'h0010_0000_0000_0000);
		check_and(16'h0235, 64'h0020_0000_0000_0000);
		check_and(16'h0236, 64'h0040_0000_0000_0000);
		check_and(16'h0237, 64'h0080_0000_0000_0000);

		check_and(16'h0238, 64'h0100_0000_0000_0000);
		check_and(16'h0239, 64'h0200_0000_0000_0000);
		check_and(16'h023A, 64'h0400_0000_0000_0000);
		check_and(16'h023B, 64'h0800_0000_0000_0000);

		check_and(16'h023C, 64'h1000_0000_0000_0000);
		check_and(16'h023D, 64'h2000_0000_0000_0000);
		check_and(16'h023E, 64'h4000_0000_0000_0000);
		check_and(16'h023F, 64'h8000_0000_0000_0000);

		check_xor(16'h0300, 64'h0000_0000_0000_0001);
		check_xor(16'h0301, 64'h0000_0000_0000_0002);
		check_xor(16'h0302, 64'h0000_0000_0000_0004);
		check_xor(16'h0303, 64'h0000_0000_0000_0008);

		check_xor(16'h0304, 64'h0000_0000_0000_0010);
		check_xor(16'h0305, 64'h0000_0000_0000_0020);
		check_xor(16'h0306, 64'h0000_0000_0000_0040);
		check_xor(16'h0307, 64'h0000_0000_0000_0080);

		check_xor(16'h0308, 64'h0000_0000_0000_0100);
		check_xor(16'h0309, 64'h0000_0000_0000_0200);
		check_xor(16'h030A, 64'h0000_0000_0000_0400);
		check_xor(16'h030B, 64'h0000_0000_0000_0800);

		check_xor(16'h030C, 64'h0000_0000_0000_1000);
		check_xor(16'h030D, 64'h0000_0000_0000_2000);
		check_xor(16'h030E, 64'h0000_0000_0000_4000);
		check_xor(16'h030F, 64'h0000_0000_0000_8000);

		check_xor(16'h0310, 64'h0000_0000_0001_0000);
		check_xor(16'h0311, 64'h0000_0000_0002_0000);
		check_xor(16'h0312, 64'h0000_0000_0004_0000);
		check_xor(16'h0313, 64'h0000_0000_0008_0000);

		check_xor(16'h0314, 64'h0000_0000_0010_0000);
		check_xor(16'h0315, 64'h0000_0000_0020_0000);
		check_xor(16'h0316, 64'h0000_0000_0040_0000);
		check_xor(16'h0317, 64'h0000_0000_0080_0000);

		check_xor(16'h0318, 64'h0000_0000_0100_0000);
		check_xor(16'h0319, 64'h0000_0000_0200_0000);
		check_xor(16'h031A, 64'h0000_0000_0400_0000);
		check_xor(16'h031B, 64'h0000_0000_0800_0000);

		check_xor(16'h031C, 64'h0000_0000_1000_0000);
		check_xor(16'h031D, 64'h0000_0000_2000_0000);
		check_xor(16'h031E, 64'h0000_0000_4000_0000);
		check_xor(16'h031F, 64'h0000_0000_8000_0000);

		check_xor(16'h0320, 64'h0000_0001_0000_0000);
		check_xor(16'h0321, 64'h0000_0002_0000_0000);
		check_xor(16'h0322, 64'h0000_0004_0000_0000);
		check_xor(16'h0323, 64'h0000_0008_0000_0000);

		check_xor(16'h0324, 64'h0000_0010_0000_0000);
		check_xor(16'h0325, 64'h0000_0020_0000_0000);
		check_xor(16'h0326, 64'h0000_0040_0000_0000);
		check_xor(16'h0327, 64'h0000_0080_0000_0000);

		check_xor(16'h0328, 64'h0000_0100_0000_0000);
		check_xor(16'h0329, 64'h0000_0200_0000_0000);
		check_xor(16'h032A, 64'h0000_0400_0000_0000);
		check_xor(16'h032B, 64'h0000_0800_0000_0000);

		check_xor(16'h032C, 64'h0000_1000_0000_0000);
		check_xor(16'h032D, 64'h0000_2000_0000_0000);
		check_xor(16'h032E, 64'h0000_4000_0000_0000);
		check_xor(16'h032F, 64'h0000_8000_0000_0000);

		check_xor(16'h0330, 64'h0001_0000_0000_0000);
		check_xor(16'h0331, 64'h0002_0000_0000_0000);
		check_xor(16'h0332, 64'h0004_0000_0000_0000);
		check_xor(16'h0333, 64'h0008_0000_0000_0000);

		check_xor(16'h0334, 64'h0010_0000_0000_0000);
		check_xor(16'h0335, 64'h0020_0000_0000_0000);
		check_xor(16'h0336, 64'h0040_0000_0000_0000);
		check_xor(16'h0337, 64'h0080_0000_0000_0000);

		check_xor(16'h0338, 64'h0100_0000_0000_0000);
		check_xor(16'h0339, 64'h0300_0000_0000_0000);
		check_xor(16'h033A, 64'h0400_0000_0000_0000);
		check_xor(16'h033B, 64'h0800_0000_0000_0000);

		check_xor(16'h033C, 64'h1000_0000_0000_0000);
		check_xor(16'h033D, 64'h2000_0000_0000_0000);
		check_xor(16'h033E, 64'h4000_0000_0000_0000);
		check_xor(16'h033F, 64'h8000_0000_0000_0000);

		check_or(16'h0400, 64'h0000_0000_0000_0001);
		check_or(16'h0401, 64'h0000_0000_0000_0002);
		check_or(16'h0402, 64'h0000_0000_0000_0004);
		check_or(16'h0403, 64'h0000_0000_0000_0008);

		check_or(16'h0404, 64'h0000_0000_0000_0010);
		check_or(16'h0405, 64'h0000_0000_0000_0020);
		check_or(16'h0406, 64'h0000_0000_0000_0040);
		check_or(16'h0407, 64'h0000_0000_0000_0080);

		check_or(16'h0408, 64'h0000_0000_0000_0100);
		check_or(16'h0409, 64'h0000_0000_0000_0200);
		check_or(16'h040A, 64'h0000_0000_0000_0400);
		check_or(16'h040B, 64'h0000_0000_0000_0800);

		check_or(16'h040C, 64'h0000_0000_0000_1000);
		check_or(16'h040D, 64'h0000_0000_0000_2000);
		check_or(16'h040E, 64'h0000_0000_0000_4000);
		check_or(16'h040F, 64'h0000_0000_0000_8000);

		check_or(16'h0410, 64'h0000_0000_0001_0000);
		check_or(16'h0411, 64'h0000_0000_0002_0000);
		check_or(16'h0412, 64'h0000_0000_0004_0000);
		check_or(16'h0413, 64'h0000_0000_0008_0000);

		check_or(16'h0414, 64'h0000_0000_0010_0000);
		check_or(16'h0415, 64'h0000_0000_0020_0000);
		check_or(16'h0416, 64'h0000_0000_0040_0000);
		check_or(16'h0417, 64'h0000_0000_0080_0000);

		check_or(16'h0418, 64'h0000_0000_0100_0000);
		check_or(16'h0419, 64'h0000_0000_0200_0000);
		check_or(16'h041A, 64'h0000_0000_0400_0000);
		check_or(16'h041B, 64'h0000_0000_0800_0000);

		check_or(16'h041C, 64'h0000_0000_1000_0000);
		check_or(16'h041D, 64'h0000_0000_2000_0000);
		check_or(16'h041E, 64'h0000_0000_4000_0000);
		check_or(16'h041F, 64'h0000_0000_8000_0000);

		check_or(16'h0420, 64'h0000_0001_0000_0000);
		check_or(16'h0421, 64'h0000_0002_0000_0000);
		check_or(16'h0422, 64'h0000_0004_0000_0000);
		check_or(16'h0423, 64'h0000_0008_0000_0000);

		check_or(16'h0424, 64'h0000_0010_0000_0000);
		check_or(16'h0425, 64'h0000_0020_0000_0000);
		check_or(16'h0426, 64'h0000_0040_0000_0000);
		check_or(16'h0427, 64'h0000_0080_0000_0000);

		check_or(16'h0428, 64'h0000_0100_0000_0000);
		check_or(16'h0429, 64'h0000_0200_0000_0000);
		check_or(16'h042A, 64'h0000_0400_0000_0000);
		check_or(16'h042B, 64'h0000_0800_0000_0000);

		check_or(16'h042C, 64'h0000_1000_0000_0000);
		check_or(16'h042D, 64'h0000_2000_0000_0000);
		check_or(16'h042E, 64'h0000_4000_0000_0000);
		check_or(16'h042F, 64'h0000_8000_0000_0000);

		check_or(16'h0430, 64'h0001_0000_0000_0000);
		check_or(16'h0431, 64'h0002_0000_0000_0000);
		check_or(16'h0432, 64'h0004_0000_0000_0000);
		check_or(16'h0433, 64'h0008_0000_0000_0000);

		check_or(16'h0434, 64'h0010_0000_0000_0000);
		check_or(16'h0435, 64'h0020_0000_0000_0000);
		check_or(16'h0436, 64'h0040_0000_0000_0000);
		check_or(16'h0437, 64'h0080_0000_0000_0000);

		check_or(16'h0438, 64'h0100_0000_0000_0000);
		check_or(16'h0439, 64'h0400_0000_0000_0000);
		check_or(16'h043A, 64'h0400_0000_0000_0000);
		check_or(16'h043B, 64'h0800_0000_0000_0000);

		check_or(16'h043C, 64'h1000_0000_0000_0000);
		check_or(16'h043D, 64'h2000_0000_0000_0000);
		check_or(16'h043E, 64'h4000_0000_0000_0000);
		check_or(16'h043F, 64'h8000_0000_0000_0000);

		check_diff_bit(16'h0500, 64'h0000_0000_0000_0001, 1, 0, 1);
		check_diff_bit(16'h0501, 64'h0000_0000_0000_0002, 1, 0, 1);
		check_diff_bit(16'h0502, 64'h0000_0000_0000_0004, 1, 0, 1);
		check_diff_bit(16'h0503, 64'h0000_0000_0000_0008, 1, 0, 1);

		check_diff_bit(16'h0504, 64'h0000_0000_0000_0010, 1, 0, 1);
		check_diff_bit(16'h0505, 64'h0000_0000_0000_0020, 1, 0, 1);
		check_diff_bit(16'h0506, 64'h0000_0000_0000_0040, 1, 0, 1);
		check_diff_bit(16'h0507, 64'h0000_0000_0000_0080, 1, 0, 1);

		check_diff_bit(16'h0508, 64'h0000_0000_0000_0100, 1, 0, 1);
		check_diff_bit(16'h0509, 64'h0000_0000_0000_0200, 1, 0, 1);
		check_diff_bit(16'h050A, 64'h0000_0000_0000_0400, 1, 0, 1);
		check_diff_bit(16'h050B, 64'h0000_0000_0000_0800, 1, 0, 1);

		check_diff_bit(16'h050C, 64'h0000_0000_0000_1000, 1, 0, 1);
		check_diff_bit(16'h050D, 64'h0000_0000_0000_2000, 1, 0, 1);
		check_diff_bit(16'h050E, 64'h0000_0000_0000_4000, 1, 0, 1);
		check_diff_bit(16'h050F, 64'h0000_0000_0000_8000, 1, 0, 1);

		check_diff_bit(16'h0510, 64'h0000_0000_0001_0000, 1, 0, 1);
		check_diff_bit(16'h0511, 64'h0000_0000_0002_0000, 1, 0, 1);
		check_diff_bit(16'h0512, 64'h0000_0000_0004_0000, 1, 0, 1);
		check_diff_bit(16'h0513, 64'h0000_0000_0008_0000, 1, 0, 1);

		check_diff_bit(16'h0514, 64'h0000_0000_0010_0000, 1, 0, 1);
		check_diff_bit(16'h0515, 64'h0000_0000_0020_0000, 1, 0, 1);
		check_diff_bit(16'h0516, 64'h0000_0000_0040_0000, 1, 0, 1);
		check_diff_bit(16'h0517, 64'h0000_0000_0080_0000, 1, 0, 1);

		check_diff_bit(16'h0518, 64'h0000_0000_0100_0000, 1, 0, 1);
		check_diff_bit(16'h0519, 64'h0000_0000_0200_0000, 1, 0, 1);
		check_diff_bit(16'h051A, 64'h0000_0000_0400_0000, 1, 0, 1);
		check_diff_bit(16'h051B, 64'h0000_0000_0800_0000, 1, 0, 1);

		check_diff_bit(16'h051C, 64'h0000_0000_1000_0000, 1, 0, 1);
		check_diff_bit(16'h051D, 64'h0000_0000_2000_0000, 1, 0, 1);
		check_diff_bit(16'h051E, 64'h0000_0000_4000_0000, 1, 0, 1);
		check_diff_bit(16'h051F, 64'h0000_0000_8000_0000, 1, 0, 1);

		check_diff_bit(16'h0520, 64'h0000_0001_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0521, 64'h0000_0002_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0522, 64'h0000_0004_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0523, 64'h0000_0008_0000_0000, 1, 0, 1);

		check_diff_bit(16'h0524, 64'h0000_0010_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0525, 64'h0000_0020_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0526, 64'h0000_0040_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0527, 64'h0000_0080_0000_0000, 1, 0, 1);

		check_diff_bit(16'h0528, 64'h0000_0100_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0529, 64'h0000_0200_0000_0000, 1, 0, 1);
		check_diff_bit(16'h052A, 64'h0000_0400_0000_0000, 1, 0, 1);
		check_diff_bit(16'h052B, 64'h0000_0800_0000_0000, 1, 0, 1);

		check_diff_bit(16'h052C, 64'h0000_1000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h052D, 64'h0000_2000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h052E, 64'h0000_4000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h052F, 64'h0000_8000_0000_0000, 1, 0, 1);

		check_diff_bit(16'h0530, 64'h0001_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0531, 64'h0002_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0532, 64'h0004_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0533, 64'h0008_0000_0000_0000, 1, 0, 1);

		check_diff_bit(16'h0534, 64'h0010_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0535, 64'h0020_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0536, 64'h0040_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0537, 64'h0080_0000_0000_0000, 1, 0, 1);

		check_diff_bit(16'h0538, 64'h0100_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h0539, 64'h0200_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h053A, 64'h0400_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h053B, 64'h0800_0000_0000_0000, 1, 0, 1);

		check_diff_bit(16'h053C, 64'h1000_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h053D, 64'h2000_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h053E, 64'h4000_0000_0000_0000, 1, 0, 1);
		check_diff_bit(16'h053F, 64'h8000_0000_0000_0000, 1, 0, 1);

		$display("@DONE");
		$stop;
	end
endmodule
