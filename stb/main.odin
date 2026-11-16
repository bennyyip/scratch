package main
import "./stb"
import "core:fmt"
import "core:mem"

println :: fmt.println
printf :: fmt.printf
print :: fmt.print

print_token :: proc(lexer: ^stb.lexer) {
	switch token := lexer.token; token {
	case 0 ..= 255:
		{
			printf("%c", token)
		}
	case:
		#partial switch kind := cast(stb.Token_Kind)token; kind {
		case .eof:
			print("<<EOF>>")
		case .parse_error:
			print("<<PARSE ERROR>>")
		case .floatlit:
			print(lexer.real_number)
		case .intlit:
			print(lexer.int_number)
		case .id:
			print(lexer._string)
		case .dqstring, .sqstring, .charlit:
			printf(`"%v"`, lexer._string)
		case .eq:
			print("==")
		case .noteq:
			print("!=")
		}
	}
}

main :: proc() {
	src: string = #load("stb_c_lexer.h")
	lexer := stb.lexer{}
	string_store := make([dynamic]u8, 2048)
	stb.c_lexer_init(
		&lexer,
		raw_data(src[:]),
		mem.ptr_offset(raw_data(src[:]), len(src)),
		raw_data(string_store[:]),
		auto_cast len(string_store) - 1,
	)

	for stb.c_lexer_get_token(&lexer) != 0 {
		print_token(&lexer)
	}
}

