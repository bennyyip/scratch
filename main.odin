package main
import "core:fmt"
import "core:strings"

println :: fmt.println
printf :: fmt.printf

Input :: struct {
	data: [dynamic; 26]int,
	idx:  int,
}
INPUT := Input{}

Op_Kind :: enum {
	Num,
	Inp,
	Add,
	Sub,
	Mul,
	Div,
	Mod,
	Eql,
}

binop_to_string :: proc(op: Op_Kind) -> string {
	#partial switch op {
	case .Add:
		return "+"
	case .Sub:
		return "-"
	case .Mul:
		return "*"
	case .Div:
		return "/"
	case .Mod:
		return "%"
	case .Eql:
		return "=="
	}
	assert(false, "unreachable")
	return ""
}

Node :: struct {
	op:         Op_Kind,
	lhs, rhs:   ^Node,
	n:          int,
	//
	t:          int,
	has_result: bool,
	result:     int,
	min, max:   int,
}

Program :: [dynamic]^Node
main :: proc() {
	append(&INPUT.data, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4)

	println(compute())
	// println(naive())
}

setnumber :: proc(x: ^Node, val: int) {
	x.op = .Num
	x.n = val
	x.max = val
	x.min = val
}

opt :: proc() {
	for &x in prog {
		l, r := x.lhs, x.rhs
		#partial switch x.op {
		case .Add:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n + r.n)
			case l.op == .Num && l.n == 0:
				x^ = r^
			case r.op == .Num && r.n == 0:
				x^ = l^
			}
		case .Sub:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n - r.n)
			case r.op == .Num && r.n == 0:
				x^ = l^
			}
		case .Mul:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n * r.n)
			case l.op == .Num:
				if l.n == 1 do x^ = r^
				else if l.n == 0 do setnumber(x, 0)
			case r.op == .Num:
				if r.n == 1 do x^ = l^
				else if r.n == 0 do setnumber(x, 0)
			}
		case .Div:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n / r.n)
			case l.op == .Num && l.n == 0:
				setnumber(x, 0)
			case r.op == .Num && r.n == 1:
				x^ = l^
			case l.op == .Add && r.op == .Num:
				// (x * 26 + y) / 26
				if l.rhs.op == .Num && l.rhs.n == r.n {
					x^ = l.rhs^
				}
			}
		case .Mod:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n % r.n)
			case l.op == .Num && l.n == 0:
				setnumber(x, 0)
			case l.op == .Add && r.op == .Num:
				// ((x * 26) + y)  % 26
				if l.lhs.op == .Mul &&
				   l.lhs.rhs.op == .Num &&
				   l.lhs.rhs.n == r.n &&
				   l.rhs.max < r.n {
					// x^ = l.rhs^
				}
			}
		case .Eql:
			switch {
			case l.op == .Num && r.op == .Num:
				setnumber(x, l.n == r.n ? 1 : 0)
			case l.max < r.min || r.max < l.min:
				setnumber(x, 0)
			}
		}

		switch x.op {
		case .Add:
			x.min = l.min + r.min
			x.max = l.max + r.max
		case .Sub:
			x.min = l.min - r.max
			x.max = l.max - r.min
		case .Mul:
			assert(l.min >= 0)
			assert(r.min >= 0)
			x.min = l.min * r.min
			x.max = l.max * r.max
		case .Div:
			assert(l.min >= 0)
			assert(r.min >= 0)
			x.min = l.min / r.max
			x.max = l.max / r.min
		case .Mod:
			assert(r.min > 0)
			x.min = 0
			x.max = r.max - 1
		case .Eql:
			x.min = 0
			x.max = 1
		case .Num:
			x.min = x.n
			x.max = x.n
		case .Inp:
			x.min = 0
			x.max = 9
		}
	}
}

eval :: proc(x: ^Node) -> int {
	// println(node)
	if x.has_result {
		return x.result
	}
	res: int

	switch x.op {
	case .Add:
		res = eval(x.lhs) + eval(x.rhs)
	case .Sub:
		res = eval(x.lhs) - eval(x.rhs)
	case .Mul:
		res = eval(x.lhs) * eval(x.rhs)
	case .Div:
		res = eval(x.lhs) / eval(x.rhs)
	case .Mod:
		res = eval(x.lhs) % eval(x.rhs)
	case .Eql:
		res = int(eval(x.lhs) == eval(x.rhs))
	case .Inp:
		res = x.n
	case .Num:
		res = x.n
	}
	x.has_result = true
	x.result = res
	return res

}

t := 4
prog: Program

dump :: proc() {
	counter := make(map[^Node]int)
	#reverse for x, i in prog {
		if x.op == .Num || x.op == .Inp do continue
		// if counter[x] == 0 && i != len(prog) - 1 do continue
		counter[x.lhs] += 1
		counter[x.rhs] += 1
	}

	seen := make(map[^Node]string)
	for x in prog {
		#partial switch x.op {
		case .Num, .Inp:
			seen[x] = node_to_string(x)
		case:
			str := fmt.aprintf(
				"(%v %v %v)",
				seen[x.lhs],
				binop_to_string(x.op),
				seen[x.rhs],
			)
			if counter[x] >= 2 {
				name := node_name(x)
				fmt.printfln("%v = %v\t\t[%v, %v]", name, str, x.min, x.max)
				str = name
			}
			seen[x] = str
		}
	}

	last := prog[len(prog) - 1]
	fmt.printfln("%v = %v\t\t[%v, %v]", "z", seen[last], last.min, last.max)
}

node_name :: proc(x: ^Node) -> string {
	#partial switch x.op {
	case .Num, .Inp:
		return node_to_string(x)
	case:
		return fmt.aprintf("t%v", x.t)
	}
	assert(false, "unreachalbe")
	return ""
}

node_to_string :: proc(x: ^Node) -> string {
	sb := strings.builder_make()
	#partial switch x.op {
	case .Num:
		fmt.sbprint(&sb, x.n)
	case .Inp:
		fmt.sbprintf(&sb, "m%v", x.t)
	case:
		op_str := binop_to_string(x.op)
		fmt.sbprintf(
			&sb,
			"%v %v %v",
			node_name(x.lhs),
			op_str,
			node_name(x.rhs),
		)
	}
	return strings.to_string(sb)
}

naive :: proc() -> int {
	x, y, z, w: int

	inp :: proc() -> int {
		x := INPUT.data[INPUT.idx]
		INPUT.idx += 1
		return x
	}
	num :: int
	add :: proc(lhs, rhs: int) -> int {return lhs + rhs}
	sub :: proc(lhs, rhs: int) -> int {return lhs - rhs}
	mul :: proc(lhs, rhs: int) -> int {return lhs * rhs}
	div :: proc(lhs, rhs: int) -> int {return lhs / rhs}
	mod :: proc(lhs, rhs: int) -> int {return lhs % rhs}
	eql :: proc(lhs, rhs: int) -> int {return int(lhs == rhs)}

	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(12))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(12))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(15))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(16))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-8))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(5))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-4))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(9))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(15))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(3))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(14))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(2))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(14))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(15))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-13))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(5))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-3))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(11))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-7))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(7))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(10))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-6))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(10))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-8))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(3))
	y = mul(y, x)
	z = add(z, y)
	return z
}

compute :: proc() -> int {
	x, y, z, w: ^Node = &Node{}, &Node{}, &Node{}, &Node{}

	prog = make(Program)
	emit :: proc(node: ^Node) -> ^Node {
		t += 1
		node.t = t
		append(&prog, node)
		return node
	}
	inp :: proc() -> ^Node {
		res := new(Node)
		x := INPUT.data[INPUT.idx]
		INPUT.idx += 1
		emit(res)
		res^ = Node {
			n   = x,
			op  = .Inp,
			min = 1,
			max = 9,
			t   = INPUT.idx - 1,
		}
		return res
	}
	num :: proc(val: int) -> ^Node {
		res := new(Node)
		emit(res)
		setnumber(res, val)
		return res
	}
	binop :: proc(lhs, rhs: ^Node, kind: Op_Kind) -> ^Node {
		res := new(Node)
		res^ = Node {
			lhs = lhs,
			rhs = rhs,
			op  = kind,
		}
		emit(res)
		return res
	}

	add :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Add)
	}
	sub :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Sub)
	}
	mul :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Mul)
	}
	div :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Div)
	}
	mod :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Mod)
	}
	eql :: proc(lhs, rhs: ^Node) -> ^Node {
		return binop(lhs, rhs, .Eql)
	}

	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(12))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(12))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(15))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(16))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-8))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(5))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-4))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(9))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(15))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(3))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(14))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(2))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(14))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(15))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-13))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(5))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-3))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(11))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-7))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(7))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(1))
	x = add(x, num(10))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(1))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-6))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(10))
	y = mul(y, x)
	z = add(z, y)
	w = inp()
	x = mul(x, num(0))
	x = add(x, z)
	x = mod(x, num(26))
	z = div(z, num(26))
	x = add(x, num(-8))
	x = eql(x, w)
	x = eql(x, num(0))
	y = mul(y, num(0))
	y = add(y, num(25))
	y = mul(y, x)
	y = add(y, num(1))
	z = mul(z, y)
	y = mul(y, num(0))
	y = add(y, w)
	y = add(y, num(3))
	y = mul(y, x)
	z = add(z, y)
	opt()
	dump()
	return eval(z)
}

