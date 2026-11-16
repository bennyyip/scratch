package main
import "core:fmt"
import "core:strings"

println :: fmt.println
printf :: fmt.printf

Input :: struct {
	data: [dynamic; 26]int,
	idx: int,
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
	Force,
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
	case .Force:
		return "force"
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
	m2 := 1
	m3 := 9
	m1 := 4
	m4 := 1
	m7 := 1
	m8 := 3
	m6 := 2
	m9 := 1
	m5 := 5
	m10 := 1
	m11 := 6
	m12 := 1
	m0 := 8
	m13 := 1


	// 99196997985942

	append(
		&INPUT.data,
		m0,
		m1,
		m2,
		m3,
		m4,
		m5,
		m6,
		m7,
		m8,
		m9,
		m10,
		m11,
		m12,
		m13,
	)

	for x in INPUT.data {
		fmt.print(x)
	}
	println()

	// INPUT.data[

	println(compute())
	// println(naive())
}

getconst :: proc(x: ^Node) -> (res: int, ok: bool) {
	if x == nil do return -1, false
	if x.op == .Num do return x.n, true
	if x.op != .Inp && x.min == x.max do return x.min, true
	return -1, false
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

		lc, lcok := getconst(l)
		rc, rcok := getconst(r)

		#partial switch x.op {
		case .Add:
			switch {
			case lcok && rcok:
				setnumber(x, lc + rc)
			case lcok && lc == 0:
				x^ = r^
			case rcok && rc == 0:
				x^ = l^
			case rcok && l.op == .Add && l.rhs.op == .Num:
				// (x + 2) + 3
				sum := l.rhs.n + rc
				x.lhs^ = l.lhs^
				setnumber(x.rhs, sum)
			}
		case .Sub:
			switch {
			case lcok && rcok:
				setnumber(x, lc - rc)
			case rcok && rc == 0:
				x^ = l^
			}
		case .Mul:
			switch {
			case lcok && rcok:
				setnumber(x, lc * rc)
			case lcok:
				if lc == 1 do x^ = r^
				else if lc == 0 do setnumber(x, 0)
			case rcok:
				if rc == 1 do x^ = l^
				else if rc == 0 do setnumber(x, 0)
			}
		case .Div:
			switch {
			case lcok && rcok:
				setnumber(x, lc / rc)
			case lcok && lc == 0:
				setnumber(x, 0)
			case rcok && rc == 1:
				x^ = l^
			case l.op == .Add && rcok:
				// ((x * 26) + y) / 26
				if l.lhs.op == .Mul &&
				   l.lhs.rhs.op == .Num &&
				   l.lhs.rhs.n == rc &&
				   l.rhs.max < rc {
					x^ = l.lhs.lhs^
				}
			case:
			}
		case .Mod:
			switch {
			case lcok && rcok:
				setnumber(x, lc % rc)
			case lcok && lc == 0:
				setnumber(x, 0)
			case l.op == .Add && rcok:
				// ((x * 26) + y)  % 26
				if l.lhs.op == .Mul &&
				   l.lhs.rhs.op == .Num &&
				   l.lhs.rhs.n == rc &&
				   l.rhs.max < rc {
					x^ = l.rhs^
				}
			case rcok && l.max < rc:
				x^ = l^
			}
		case .Eql:
			switch {
			case lcok && rcok:
				setnumber(x, lc == rc ? 1 : 0)
			case l.max < r.min || r.max < l.min:
				setnumber(x, 0)
			}
		case .Force:
			switch {
			case l.op == .Add && l.rhs.op == .Num && rcok && l.rhs.n == rc:
				// x + 8 force 8
				x.lhs^ = l.lhs^
				setnumber(x.rhs, 0)
			}
		}

		l, r = x.lhs, x.rhs
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
		case .Force:
			x.min = 0
			x.max = 0
		}
	}
}

force :: proc() {
	upper_bound := make(map[^Node]int)
	last := prog[len(prog) - 1]
	upper_bound[last] = 0

	update :: proc(upper_bound: ^map[^Node]int, k: ^Node, v: int) {
		if !(k in upper_bound) {
			upper_bound[k] = v
		} else {
			upper_bound[k] = min(upper_bound[k], v)
		}
	}

	#reverse for &x, i in prog {
		if !(x in upper_bound) do continue
		m := upper_bound[x]

		if x.max < m do continue

		u := &upper_bound
		l := x.lhs
		r := x.rhs

		#partial switch x.op {
		case .Num:
			assert(x.n <= m, "impossible")
		case .Add:
			update(u, l, m - r.min)
			update(u, r, m - l.min)
		case .Mul:
			if r.min > 0 {
				update(u, l, m / r.min)
			}
			if l.min > 0 {
				update(u, r, m / l.min)
			}
		case .Div:
			if r.op == .Num {
				update(u, l, m * r.n + (r.n - 1))
			}
		case .Eql:
			rc, rcok := getconst(r)
			if l.op == .Eql && rcok && rc == 0 {
				// (x == y) == 0
				// x force y
				x.op = .Force
				update(u, l.lhs, l.rhs.max)
				update(u, l.rhs, l.lhs.max)
				llhs := l.lhs
				lrhs := l.rhs
				x.lhs^ = llhs^
				x.rhs^ = lrhs^
				x.min = 0
				x.max = 0
			}
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
	case .Force:
		res = 0
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
		if counter[x] == 0 && i != len(prog) - 1 do continue
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
			if counter[x] >= 2 || x.op == .Force {
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
	// dump()
	res := eval(z)
	force()
	opt()
	dump()
	return res
}
