import nsauzede.vsdl2

const (
	empty   = 0x0
	storage = 0x1
	box     = 0x2
	player  = 0x4
	wall    = 0x8
	width   = 320
	height  = 200
	bpp     = 32
	level1  = '
....wwwww
....w...w
....wb.bw
..www...www
..w...b...w
www.wbwww.w.....wwwwww
w...w.www.wwwwwww..ssw
w.b................PBw
wwwww.wwww.w.wwww..ssw
....w......www..wwwwww
....wwwwwwww
'
)

struct Game {
mut:
	quit          bool
	win           bool
	map           [][]byte
	must_draw     bool
	boxes         int
	stored        int
	current_level int
	// map dims
	w             int
	h             int
	// block dims
	bw            int
	bh            int
	// player pos
	px            int
	py            int
	// SDL
	window        voidptr
	renderer      voidptr
	screen        &vsdl2.Surface
	texture       voidptr
}

fn new_game() Game {
	mut map := [][]byte{}
	mut boxes := 0
	mut storages := 0
	mut stored := 0
	mut w := 0
	mut h := 0
	mut px := 0
	mut py := 0
	mut player_found := false
	for line in level1.split_into_lines() {
		if line.len > w {
			w = line.len
		}
	}
	for line in level1.split_into_lines() {
		if line.len == 0 {
			continue
		}
		mut v := [byte(empty)].repeat(w)
		for i, e in line {
			match e {
				`.`, ` ` {
					v[i] = empty
				}
				`s` {
					v[i] = storage
					storages++
				}
				`b` {
					v[i] = box
					boxes++
				}
				`B` {
					v[i] = box | storage
					storages++
					boxes++
					stored++
				}
				`p` {
					if player_found {
						panic('Player found multiple times in level')
					}
					px = i
					py = h
					player_found = true
					v[i] = empty
				}
				`P` {
					if player_found {
						panic('Player found multiple times in level')
					}
					px = i
					py = h
					player_found = true
					v[i] = storage
					storages++
				}
				`w` {
					v[i] = wall
				}
				else {
					panic('Invalid element [$e.str()] in level')
				}
			}
		}
		map << v
		h++
	}
	if boxes != storages {
		panic('Mismatch between boxes=$boxes and storages=$storages in level')
	}
	if !player_found {
		panic('Player not found in level')
	}
	mut game := Game{
		quit: false
		win: false
		map: map
		must_draw: true
		boxes: boxes
		stored: stored
		w: w
		h: h
		px: px
		py: py
		current_level: 1
		screen: 0
	}
	C.SDL_Init(C.SDL_INIT_VIDEO)
	C.atexit(C.SDL_Quit)
	vsdl2.create_window_and_renderer(width, height, 0, &game.window, &game.renderer)
	C.SDL_SetWindowTitle(game.window, 'クレートさん')
	game.screen = vsdl2.create_rgb_surface(0, width, height, bpp, 0x00FF0000, 0x0000FF00,
		0x000000FF, 0xFF000000)
	game.texture = C.SDL_CreateTexture(game.renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING,
		width, height)
	game.bw = width / w
	game.bh = height / h
	return game
}

fn (mut g Game) can_move(x, y int) bool {
	if x < g.w && y < g.h {
		e := g.map[y][x]
		if e == empty || e == storage {
			return true
		}
	}
	return false
}

// Try to move to x+dx:y+dy and also push to x+2dx:y+2dy
fn (mut g Game) try_move(dx, dy int) {
	mut do_it := false
	x := g.px + dx
	y := g.py + dy
	if g.map[y][x] & box == box {
		to_x := x + dx
		to_y := y + dy
		if g.can_move(to_x, to_y) {
			g.map[y][x] &= ~box
			if g.map[y][x] & storage == storage {
				g.stored--
			}
			g.map[to_y][to_x] |= box
			if g.map[to_y][to_x] & storage == storage {
				g.stored++
				if g.stored == g.boxes {
					g.win = true
				}
			}
			do_it = true
		}
	} else {
		do_it = g.can_move(x, y)
	}
	if do_it {
		g.px = x
		g.py = y
		g.must_draw = true
	}
}

fn (mut g Game) draw_map() {
	if g.must_draw {
		C.SDL_RenderClear(g.renderer)
		mut rect := vsdl2.Rect{0, 0, g.w, g.h}
		mut col := vsdl2.Color{byte(0), byte(0), byte(0), byte(255)}
		vsdl2.fill_rect(g.screen, &rect, col)
		for j, line in g.map {
			for i, e in line {
				col = match e {
					empty {
						if g.px == i && g.py == j { vsdl2.Color{byte(255), byte(255), byte(255), byte(0)} } else { vsdl2.Color{byte(66), byte(66), byte(66), byte(0)} }
					}
					storage {
						if g.px == i && g.py == j { vsdl2.Color{byte(190), byte(190), byte(190), byte(0)} } else { vsdl2.Color{byte(105), byte(105), byte(105), byte(0)} }
					}
					box {
						vsdl2.Color{byte(156), byte(100), byte(63), byte(0)}
					}
					wall {
						vsdl2.Color{byte(255), byte(0), byte(0), byte(0)}
					}
					box | storage {
						vsdl2.Color{byte(109), byte(69), byte(43), byte(0)}
					}
					else {
						vsdl2.Color{byte(0), byte(255), byte(0), byte(0)}
					}
				}
				rect = vsdl2.Rect{i * g.bw, j * g.bh, g.bw, g.bh}
				vsdl2.fill_rect(g.screen, &rect, col)
			}
		}
		C.SDL_UpdateTexture(g.texture, 0, g.screen.pixels, g.screen.pitch)
		C.SDL_RenderCopy(g.renderer, g.texture, voidptr(0), voidptr(0))
		C.SDL_RenderPresent(g.renderer)
		g.must_draw = false
	}
}

fn (mut g Game) handle_events() {
	if g.win {
		println('YOU WIN level $g.current_level !!!')
		g.quit = true
		return
	}
	ev := vsdl2.Event{}
	for 0 < vsdl2.poll_event(&ev) {
		match int(ev.@type) {
			C.SDL_QUIT {
				g.quit = true
				break
			}
			C.SDL_KEYDOWN {
				key := ev.key.keysym.sym
				match key {
					C.SDLK_ESCAPE {
						g.quit = true
						break
					}
					C.SDLK_UP {
						g.try_move(0, -1)
					}
					C.SDLK_DOWN {
						g.try_move(0, 1)
					}
					C.SDLK_LEFT {
						g.try_move(-1, 0)
					}
					C.SDLK_RIGHT {
						g.try_move(1, 0)
					}
					else {}
				}
			}
			else {}
		}
	}
}

fn (g Game) sleep() {
	vsdl2.delay(1000 / 60)
}

fn main() {
	mut game := new_game()
	for !game.quit {
		game.handle_events()
		game.draw_map()
		game.sleep()
	}
}
