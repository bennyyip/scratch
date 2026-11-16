#!/bin/sh
// 2>/dev/null; exec odin run "$0" -file -- "$@"

// invented by @abhinavkrishna2020

package add

import "core:fmt"
import "core:os"
import "core:strconv"

main :: proc() {
	if len(os.args) != 3 {
		fmt.println("Usage: ./add.odin [number1] [number2]")
		os.exit(1)
	}
	num1, ok1 := strconv.parse_int(os.args[1])
	num2, ok2 := strconv.parse_int(os.args[2])
	if !ok1 {
		fmt.println("Failed to parse first number", os.args[1])
	}
	if !ok2 {
		fmt.println("Failed to parse second number", os.args[2])
	}
	fmt.println("result:", num1 + num2)
	return
}

