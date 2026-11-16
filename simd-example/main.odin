package main
import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:simd"
import "core:strings"
import "core:time"

print :: fmt.println
printf :: fmt.printfln

to_upper_simd :: proc(s: []u8) {
	WIDTH :: 512 / 8
	ST :: #simd[WIDTH]i8
	s := s
	for len(s) >= WIDTH {
		chunk_ptr := cast(^ST)raw_data(s)
		s = s[WIDTH:]
		chunk := intrinsics.unaligned_load(chunk_ptr)

		rangeshift := simd.sub(chunk, cast(ST)transmute(i8)cast(u8)('a' + 128))
		nomodify := transmute(ST)simd.lanes_gt(rangeshift, cast(ST)(-128 + 25))
		flip := simd.bit_and_not(cast(ST)(0x20), nomodify)

		intrinsics.unaligned_store(chunk_ptr, simd.bit_xor(chunk, flip))
	}

	for &c in s {
		if c >= 'a' && c <= 'z' {
			c = c ~ 0x20
		}
	}
}

to_upper_scalar :: proc(s: []u8) {
	for &c in s {
		if c >= 'a' && c <= 'z' {
			c = c ~ 0x20
		}
	}
}


benchmark :: proc() {
	{
		sb: strings.Builder
		strings.write_string(&sb, #load("shakespeare.txt"))
		start := time.tick_now()
		to_upper_simd(sb.buf[:])
		elapsed := time.tick_since(start)
		printf("SIMD: %v", elapsed)
	}
	{
		sb: strings.Builder
		strings.write_string(&sb, #load("shakespeare.txt"))
		start := time.tick_now()
		to_upper_scalar(sb.buf[:])
		elapsed := time.tick_since(start)
		printf("SCALAR: %v", elapsed)
	}

}

main :: proc() {
	sb: strings.Builder
	strings.write_string(
		&sb,
		"我能吃下玻璃，他不會傷害我。\nI can eat glasses, it won't hurt me",
	)
	to_upper_scalar(sb.buf[:])
	fmt.println(strings.to_string(sb))

}

