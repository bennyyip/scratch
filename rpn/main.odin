package main
import "core:fmt"
import "core:os"

println :: fmt.println

INPUT_FILE :: "rpn_expression-5869168714501555882.txt"

main :: proc() {
	stack := make([dynamic]int, 0, 1024)
	input, err := os.read_entire_file(INPUT_FILE, context.temp_allocator)
	assert(err == nil)
	for i := 0; i < len(input); i += 1 {
		switch c := input[i]; c {
		case '0' ..= '9':
			{
				d := input[i] - '0'
				append(&stack, int(d))
			}
		case '+':
			{
				x2 := pop(&stack)
				x1 := pop(&stack)
				append(&stack, x1 + x2)
			}
		case '-':
			{
				x2 := pop(&stack)
				x1 := pop(&stack)
				append(&stack, x1 - x2)
			}
		case '*':
			{
				x2 := pop(&stack)
				x1 := pop(&stack)
				append(&stack, x1 * x2)
			}
		case '/':
			{
				x2 := pop(&stack)
				x1 := pop(&stack)
				append(&stack, x1 / x2)
			}
		}
	}
	println(stack)
}

