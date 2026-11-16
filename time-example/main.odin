package main
import "core:fmt"
import "core:time"
import dt "core:time/datetime"
import tz "core:time/timezone"

println :: fmt.println

print_time :: proc(t: time.Time) {
	ymd_buf: [time.MIN_YYYY_DATE_LEN]u8
	hms_buf: [time.MIN_HMS_LEN]u8
	ymd := time.to_string_yyyy_mm_dd(t, ymd_buf[:])
	hms := time.to_string_hms(t, hms_buf[:])
	fmt.println(ymd, hms)
}


// return offset in seconds
local_offset_from_utc :: proc() -> i64 {
	ltz := local_tz()
	if ltz == nil {
		return 0
	} else {
		return ltz.rrule.std_offset
	}
}

local_tz :: proc() -> ^dt.TZ_Region {
	@(static) local_tz: ^dt.TZ_Region
	if local_tz == nil {
		tzok: bool
		local_tz, tzok = tz.region_load("local")
		assert(tzok)
	}
	return local_tz
}

main :: proc() {
	now := time.now()

	utc_datetime, _ := time.time_to_datetime(now)
	local_datetime, _ := tz.datetime_to_tz(utc_datetime, local_tz())

	local_time, _ := time.compound_to_time(local_datetime)
	print_time(local_time)
	utc_time, _ := time.compound_to_time(utc_datetime)
	print_time(utc_time)

	println(local_offset_from_utc())
}
