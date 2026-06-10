// https://github.com/tsoding/leaf-venation/blob/main/main.c
package main
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:slice"
import rl "vendor:raylib"

VEIN_RADIUS :: 5
VEIN_COLOR :: rl.WHITE
VEIN_CORE_COLOR :: rl.BLACK
AUXIN_RATE :: 20
AUXIN_RADIUS :: VEIN_RADIUS
AUXIN_COLOR :: rl.RED
AUXIMITY :: 30

Vein :: struct {
	pos: [2]f32,
	dir: [2]f32,
}

Auxin :: [2]f32

veins := [dynamic; 2048]Vein{}
auxins := [dynamic; 2048]Auxin{}

spray_auxins :: proc() {
	w: f32 = auto_cast rl.GetScreenWidth()
	h: f32 = auto_cast rl.GetScreenHeight()

	for i in 0 ..< AUXIN_RATE {
		auxin := Auxin{rand.float32_range(0, w), rand.float32_range(0, h)}
		append(&auxins, auxin)
	}
}
kill_auxins_by_auximity :: proc() {
	for i := 0; i < len(auxins); {
		removed := false
		for &vein in veins {
			if linalg.distance(auxins[i], vein.pos) <= AUXIMITY {
				unordered_remove(&auxins, i)
				removed = true
				break
			}
		}
		if !removed {
			i += 1
		}
	}
}
calculate_growth_directions :: proc() {
	if len(veins) == 0 {
		return
	}

	for &vein in veins {
		vein.dir = 0
	}
	for &auxin in auxins {
		cvein := &veins[0]
		for &vein in veins {
			if linalg.distance(vein.pos, auxin) <
			   linalg.distance(cvein.pos, auxin) {
				cvein = &vein
			}
		}

		cvein.dir += auxin - cvein.pos
	}

	for &vein in veins {
		vein.dir = linalg.normalize0(vein.dir)
	}
}

grow_new_veins :: proc() {
	veins_len := len(veins)
	for i in 0 ..< veins_len {
		vein := veins[i]
		if vein.dir == 0 {
			continue
		}
		new_vein := Vein {
			pos = vein.pos + vein.dir * VEIN_RADIUS * 2,
		}
		append(&veins, new_vein)
	}
}

main :: proc() {
	rl.InitWindow(800, 600, "Raylib Template")
	rl.SetTargetFPS(60)
	rl.SetExitKey(.Q)

	{
		w: f32 = auto_cast rl.GetScreenWidth()
		h: f32 = auto_cast rl.GetScreenHeight()
		vein := Vein {
			pos = {w / 2, h * 2 / 3},
		}
		append(&veins, vein)
	}

	spray_auxins()

	for !rl.WindowShouldClose() {
		if (rl.IsKeyDown(.SPACE)) {
			calculate_growth_directions()
			grow_new_veins()
			kill_auxins_by_auximity()
			spray_auxins()
			kill_auxins_by_auximity()
		}

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.GetColor(0x181818FF))
			for vein in veins {
				rl.DrawCircleV(vein.pos, VEIN_RADIUS, VEIN_COLOR)
				rl.DrawCircleV(vein.pos, VEIN_RADIUS / 2, VEIN_CORE_COLOR)
				rl.DrawLineV(vein.pos, vein.pos + vein.dir * 20, rl.PURPLE)
			}
			for p in auxins {
				rl.DrawCircleV(p, AUXIN_RADIUS, AUXIN_COLOR)
				if false {
					rl.DrawRing(
						p,
						AUXIMITY,
						AUXIMITY + 2,
						0,
						360,
						69,
						AUXIN_COLOR,
					)
				}
			}
		}
		rl.EndDrawing()
	}
}

