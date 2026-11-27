package test_sort

import powersort "../"
import "core:math/rand"
import "core:slice"
import "core:testing"

@(test)
test_sort_stability :: proc(t: ^testing.T) {
	// Test sizes are all prime.
	test_sizes :: []int{7, 13, 347, 1031, 10111, 100003}
	Data :: struct {
		rand:  int,
		index: int,
	}

	for test_size in test_sizes {
		rand.reset(t.seed)

		vals := make([]Data, test_size)
		defer delete(vals)

		// Set up test values
		for &val, i in vals {
			val = {rand.int_max(10), i}
		}

		// Sort
		powersort.sort(vals, proc(l, r: Data) -> bool {return l.rand < r.rand})

		// Verify sorted test values
		rand.reset(t.seed)

		sum := vals[0].index
		for i in 1 ..< len(vals) {
			sum += vals[i].index
			if vals[i - 1].rand > vals[i].rand {
				testing.expect(t, false, "Expected slice to be sorted")
			}
			if vals[i - 1].rand < vals[i].rand {
				continue
			}
			if vals[i - 1].index > vals[i].index {
				testing.expect(t, false, "Expected slice to be stable")
			}
		}

		testing.expect(
			t,
			sum == test_size * (test_size - 1) / 2,
			"Expected slice to have all indecies",
		)

	}
}
