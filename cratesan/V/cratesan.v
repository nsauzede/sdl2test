import nsauzede.vsdl2

const (
	empty   = 0x0
	storage = 0x1
	box     = 0x2
	player  = 0x4
	wall    = 0x8
	width   = 320
	height  = 200
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
	w             int
	h             int
	px            int
	py            int
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
	println('w=$w')
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
	return Game{
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
	}
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
		for j, line in g.map {
			for i, e in line {
				c := match e {
					empty {
						if g.px == i && g.py == j { `p` } else { `.` }
					}
					storage {
						if g.px == i && g.py == j { `P` } else { `s` }
					}
					box {
						`b`
					}
					wall {
						`w`
					}
					player {
						`p`
					}
					box | storage {
						`B`
					}
					player | storage {
						`P`
					}
					else {
						`?`
					}
				}
				print(c)
			}
			println('')
		}
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

fn main() {
	C.SDL_Init(C.SDL_INIT_VIDEO)
	C.atexit(C.SDL_Quit)
	window := voidptr(0)
	renderer := voidptr(0)
	vsdl2.create_window_and_renderer(width, height, 0, &window, &renderer)
	C.SDL_SetWindowTitle(window, 'クレートさん')
	mut game := new_game()
	for !game.quit {
		game.handle_events()
		game.draw_map()
		vsdl2.delay(1000 / 60)
	}
}
