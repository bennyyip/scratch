package powersort
import "base:intrinsics"
import "core:math/rand"
import "core:slice"

import "core:fmt"

sort :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) #no_bounds_check {
	when size_of(E) != 0 {
		if n := len(data); n > 1 {
			_sort(data, less)
		}
	}
}

_sort :: proc(data: $T/[]$E, less: proc(i, j: E) -> bool) #no_bounds_check {
	Run :: struct {
		start, count: int,
		power:        i32,
	}

	runs: [dynamic; 64]Run
	count := len(data)
	buffer := make([]E, count / 2 + 1)
	defer delete(buffer)

	start := 0
	run := extend_run(data, less, start, count)
	append(&runs, run)
	start += run.count

	for start < count {
		run = extend_run(data, less, start, count)

		top := runs[len(runs) - 1]
		run.power = merge_power(top.start, top.count, run.count, count)
		for run.power <= runs[len(runs) - 1].power {
			merge_last_two(data, less, &runs, buffer)
		}
		append(&runs, run)
		start += run.count
	}

	for len(runs) >= 2 {
		merge_last_two(data, less, &runs, buffer)
	}

	extend_run :: proc(
		data: $T/[]$E,
		less: proc(i, j: E) -> bool,
		start: int,
		count: int,
	) -> Run #no_bounds_check {
		end := start + 1
		if end < count {
			if less(data[end], data[start]) {
				// strictly b > a, so reverse is still stable
				end += 1
				for end < count && less(data[end], data[end - 1]) {
					end += 1
				}
				slice.reverse(data[start:end])
			} else {
				// a <= b
				end += 1
				for end < count && !less(data[end], data[end - 1]) {
					end += 1
				}
			}
		}

		return Run {
			start,
			end - start,
			0,
		}
	}

	merge_last_two :: proc(
		data: $T/[]$E,
		less: proc(i, j: E) -> bool,
		runs: ^[dynamic; 64]Run,
		buffer: []E,
	) #no_bounds_check {
		ry := pop(runs)
		rx := pop(runs)
		new_run := Run {
			rx.start,
			rx.count + ry.count,
			min(rx.power, ry.power),
		}
		append(runs, new_run)

		xs := data[rx.start:rx.start + rx.count]
		ys := data[ry.start:ry.start + ry.count]
		dst := data[new_run.start:new_run.start + new_run.count]

		assert(rx.start + rx.count == ry.start)

		if len(xs) < len(ys) {
			copy_non_overlapping(buffer, xs, len(xs))
			xs = buffer[:len(xs)]

			i := 0
			for ; len(xs) > 0 && len(ys) > 0; i += 1 {
				if less(ys[0], xs[0]) {
					dst[i] = ys[0]
					ys = ys[1:]
				} else {
					dst[i] = xs[0]
					xs = xs[1:]
				}
			}
			if len(xs) > 0 {
				copy_non_overlapping(dst[i:], xs, len(xs))
				i += len(xs)
			}
			if len(ys) > 0 {
				copy_non_overlapping(dst[i:], ys, len(ys))
				i += len(ys)
			}
			assert(i == len(dst))
		} else {
			last :: slice.last

			copy_non_overlapping(buffer, ys, len(ys))
			ys = buffer[:len(ys)]

			i := len(dst) - 1
			for ; len(xs) > 0 && len(ys) > 0; i -= 1 {
				if less(last(ys), last(xs)) {
					dst[i] = last(xs)
					xs = xs[:len(xs) - 1]
				} else {
					dst[i] = last(ys)
					ys = ys[:len(ys) - 1]
				}
			}
			if len(xs) > 0 {
				copy_non_overlapping(dst[:i + 1], xs, len(xs))
			}
			if len(ys) > 0 {
				copy_non_overlapping(dst[:i + 1], ys, len(ys))
			}
		}
	}

	merge_power :: proc(start1, count1, count2, n: int) -> i32 {
		power: i32 = 0
		a := 2 * start1 + count1
		b := a + count1 + count2
		for {
			power += 1
			if a >= n {
				a -= n
				b -= n
			} else if (b >= n) {
				break
			}
			a <<= 1
			b <<= 1
		}
		return power
	}
}

copy_non_overlapping :: #force_inline proc "contextless" (dst, src: $T/[]$E, n: int) {
	intrinsics.mem_copy_non_overlapping(raw_data(dst), raw_data(src), n * size_of(E))
}

main :: proc() {}
