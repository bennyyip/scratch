// https://www.dgtlgrove.com/p/multi-core-by-default
// https://github.com/EpicGames/raddebugger/blob/master/src/base/base_thread_context.h
package summation
import "base:intrinsics"
import "core:fmt"
import "core:math"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import "core:sync"
import "core:thread"

println :: fmt.println

Range :: struct {
	min, max: int,
}

Lane :: struct {
	idx, count:       int,
	barrier:          ^sync.Barrier,
	broadcast_memory: rawptr,
}

Thread_Ctx :: struct {
	lane:      Lane,
	allocator: mem.Allocator,
	arena:     vmem.Arena,
}

lane_broadcast :: proc(
	lane: ^Lane,
	broadcast_ptr: rawptr,
	broadcast_size: int = size_of(rawptr),
	src_lane_idx: int = 0,
) {
	assert(broadcast_ptr != nil)

	if lane.idx == src_lane_idx {
		mem.copy(lane.broadcast_memory, broadcast_ptr, broadcast_size)
	}
	lane_sync(lane)
	if lane.idx != src_lane_idx {
		mem.copy(broadcast_ptr, lane.broadcast_memory, broadcast_size)
	}

	lane_sync(lane)
}

lane_sync :: proc(lane: ^Lane) {
	sync.barrier_wait(lane.barrier)
}


lane_range :: proc(lane: Lane, count: int) -> Range {
	n_idx := lane.idx
	n_count := lane.count
	m_count := count

	main_idxes_per_lane := m_count / n_count
	leftover_idxes_count := m_count - main_idxes_per_lane * n_count
	leftover_idxes_before_this_lane_count := math.min(
		n_idx,
		leftover_idxes_count,
	)
	lane_base_idx :=
		n_idx * main_idxes_per_lane + leftover_idxes_before_this_lane_count
	lane_base_idx__clamped := math.min(lane_base_idx, m_count)
	lane_opl_idx :=
		lane_base_idx__clamped +
		main_idxes_per_lane +
		((n_idx < leftover_idxes_count) ? 1 : 0)
	lane_opl_idx__clamped := math.min(lane_opl_idx, m_count)
	return {lane_base_idx__clamped, lane_opl_idx__clamped}
}


// TODO: figure out how fs_shared work https://github.com/EpicGames/raddebugger/blob/master/src/file_stream/file_stream.c
// Dynamically Assigning Many Variable-Work Tasks
// thread_entry_point :: proc(t: ^thread.Thread) {
// Task *tasks = ...;
// S64 tasks_count = ...;

// // set up the counter
// static S64 task_take_counter = 0;
// task_take_counter = 0;
// BarrierSync(barrier);

// // loop on all threads - take tasks as long as we can
// for(;;)
// {
//   S64 task_idx = AtomicIncEval64(&task_take_counter) - 1;
//   if(task_idx >= tasks_count)
//   {
//     break;
//   }
//   // do task
// }
//

thread_entry_point :: proc(t: ^thread.Thread) {
	thread_ctx := cast(^Thread_Ctx)t.data
	context.allocator = thread_ctx.allocator
	lane := thread_ctx.lane

	// read input
	values: [dynamic]int
	if lane.idx == 0 {
		resize(&values, 69)
	}
	values_ptr := &values
	lane_broadcast(&lane, &values_ptr)
	values = values_ptr^

	range := lane_range(lane, len(values))
	for i in range.min ..< range.max {
		values[i] = -i
	}

	// process input on each lane
	sum: int = 0
	sum_ptr := &sum
	lane_broadcast(&lane, &sum_ptr)

	lane_sum := 0
	for x in values[range.min:range.max] {
		lane_sum += x
	}

	// add lane result to global result
	sync.atomic_add(sum_ptr, lane_sum)
	lane_sync(&lane)
	// optional if you don't care about the result at other lanes
	lane_broadcast(&lane, &sum, size_of(int))

	if lane.idx == 0 {
		println(sum)
	}
}

main :: proc() {
	ncpu := os.get_processor_core_count()
	threads := make([dynamic]^thread.Thread, ncpu)
	barrier := new(sync.Barrier)
	broadcast_memory := new(rawptr)
	sync.barrier_init(barrier, ncpu)
	for i in 0 ..< ncpu {
		lane := Lane{i, ncpu, barrier, broadcast_memory}

		t := thread.create(thread_entry_point)
		data := new(Thread_Ctx)
		data.lane = lane
		data.allocator = vmem.arena_allocator(&data.arena)
		t.data = data
		t.user_index = i
		threads[i] = t

		thread.start(t)
	}

	defer {
		for t in threads {
			thread_ctx := cast(^Thread_Ctx)t.data
			vmem.arena_destroy(&thread_ctx.arena)
		}
	}

	thread.join_multiple(..threads[:])

	sum := 0
	for i in 0 ..< 69 {
		sum -= i
	}
	println(sum)

}
