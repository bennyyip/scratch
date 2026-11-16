// stb_c_lexer.h - v0.12 - public domain Sean Barrett 2013
// lexer for making little C-like languages with recursive-descent parsers
//
// This file provides both the interface and the implementation.
// To instantiate the implementation,
//      #define STB_C_LEXER_IMPLEMENTATION
// in *ONE* source file, before #including this file.
//
// The default configuration is fairly close to a C lexer, although
// suffixes on integer constants are not handled (you can override this).
//
// History:
//     0.12 fix compilation bug for NUL support; better support separate inclusion
//     0.11 fix clang static analysis warning
//     0.10 fix warnings
//     0.09 hex floats, no-stdlib fixes
//     0.08 fix bad pointer comparison
//     0.07 fix mishandling of hexadecimal constants parsed by strtol
//     0.06 fix missing next character after ending quote mark (Andreas Fredriksson)
//     0.05 refixed get_location because github version had lost the fix
//     0.04 fix octal parsing bug
//     0.03 added STB_C_LEX_DISCARD_PREPROCESSOR option
//          refactor API to simplify (only one struct instead of two)
//          change literal enum names to have 'lit' at the end
//     0.02 first public release
//
// Status:
//     - haven't tested compiling as C++
//     - haven't tested the float parsing path
//     - haven't tested the non-default-config paths (e.g. non-stdlib)
//     - only tested default-config paths by eyeballing output of self-parse
//
//     - haven't implemented multiline strings
//     - haven't implemented octal/hex character constants
//     - haven't implemented support for unicode CLEX_char
//     - need to expand error reporting so you don't just get "CLEX_parse_error"
//
// Contributors:
//   Arpad Goretity (bugfix)
//   Alan Hickman (hex floats)
//   github:mundusnine (bugfix)
//
// LICENSE
//
//   See end of file for license information.
package pkg

import "core:c"

foreign import lib "stb_c_lexer.lib"
_ :: lib

lexer :: struct {
	// lexer variables
	input_stream:       cstring,
	eof:                cstring,
	parse_point:        cstring,
	string_storage:     cstring,
	string_storage_len: i32,

	// lexer parse location for error messages
	where_firstchar:    cstring,
	where_lastchar:     cstring,

	// lexer token variables
	token:              c.long,
	real_number:        f64,
	int_number:         c.long,
	_string:            cstring,
	string_len:         i32,
}

lex_location :: struct {
	line_number: i32,
	line_offset: i32,
}

@(default_calling_convention = "c", link_prefix = "stb_")
foreign lib {
	// this function initialize the 'lexer' structure
	//   Input:
	//   - input_stream points to the file to parse, loaded into memory
	//   - input_stream_end points to the end of the file, or NULL if you use 0-for-EOF
	//   - string_store is storage the lexer can use for storing parsed strings and identifiers
	//   - store_length is the length of that storage
	c_lexer_init :: proc(lexer: ^lexer, input_stream: [^]u8, input_stream_end: ^u8, string_store: [^]u8, store_length: i32) ---

	// this function returns non-zero if a token is parsed, or 0 if at EOF
	//   Output:
	//   - lexer->token is the token ID, which is unicode code point for a single-char token, < 0 for a multichar or eof or error
	//   - lexer->real_number is a double constant value for CLEX_floatlit, or CLEX_intlit if STB_C_LEX_INTEGERS_AS_DOUBLES
	//   - lexer->int_number is an integer constant for CLEX_intlit if !STB_C_LEX_INTEGERS_AS_DOUBLES, or character for CLEX_charlit
	//   - lexer->string is a 0-terminated string for CLEX_dqstring or CLEX_sqstring or CLEX_identifier
	//   - lexer->string_len is the byte length of lexer->string
	c_lexer_get_token :: proc(lexer: ^lexer) -> i32 ---

	// this inefficient function returns the line number and character offset of a
	// given location in the file as returned by stb_lex_token. Because it's inefficient,
	// you should only call it for errors, not for every token.
	// For error messages of invalid tokens, you typically want the location of the start
	// of the token (which caused the token to be invalid). For bugs involving legit
	// tokens, you can report the first or the range.
	//    Output:
	//    - loc->line_number is the line number in the file, counting from 1, of the location
	//    - loc->line_offset is the char-offset in the line, counting from 0, of the location
	c_lexer_get_location :: proc(lexer: ^lexer, _where: cstring, loc: ^lex_location) ---
}

Token_Kind :: enum {
	eof = 256,
	parse_error,
	intlit,
	floatlit,
	id,
	dqstring,
	sqstring,
	charlit,
	eq,
	noteq,
	lesseq,
	greatereq,
	andand,
	oror,
	shl,
	shr,
	plusplus,
	minusminus,
	pluseq,
	minuseq,
	muleq,
	diveq,
	modeq,
	andeq,
	oreq,
	xoreq,
	arrow,
	eqarrow,
	shleq,
	shreq,
	first_unused_token,
}

