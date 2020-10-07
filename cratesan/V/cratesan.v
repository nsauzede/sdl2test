import nsauzede.vsdl2

const (
	empty       = 0x0
	store       = 0x1
	crate       = 0x2
	player      = 0x4
	wall        = 0x8
	width       = 320
	height      = 200
	c_empty     = ` `
	c_store     = `.`
	c_stored    = `*`
	c_crate     = `$`
	c_player    = `@`
	c_splayer   = `&`
	c_wall      = `#`
	bpp         = 32
	levels_file = 'levels.txt'
	level1      = '
    #####
    #   #
    #$  #
  ###  $##
  #  $ $ #
### # ## #   ######
#   # ## #####  ..#
# $  $          ..#
##### ### #@##  ..#
    #     #########
    #######
'
)

enum Status {
	play
	win
}

struct Game {
mut:
	title     string
	quit      bool
	status    Status
	must_draw bool
	map       [][]byte
	level     int
	// following are copies of current level's
	crates    int
	stored    int
	// map dims
	w         int
	h         int
	// block dims
	bw        int
	bh        int
	// player pos
	px        int
	py        int
	// SDL
	window    voidptr
	renderer  voidptr
	screen    &vsdl2.Surface
	texture   voidptr
}

fn new_game(title string) Game {
	mut map := [][]byte{}
	mut crates := 0
	mut stores := 0
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
				c_empty {
					v[i] = empty
				}
				c_store {
					v[i] = store
					stores++
				}
				c_crate {
					v[i] = crate
					crates++
				}
				c_stored {
					v[i] = crate | store
					stores++
					crates++
					stored++
				}
				c_player {
					if player_found {
						panic('Player found multiple times in level')
					}
					px = i
					py = h
					player_found = true
					v[i] = empty
				}
				c_splayer {
					if player_found {
						panic('Player found multiple times in level')
					}
					px = i
					py = h
					player_found = true
					v[i] = store
					stores++
				}
				c_wall {
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
	if crates != stores {
		panic('Mismatch between crates=$crates and stores=$stores in level')
	}
	if !player_found {
		panic('Player not found in level')
	}
	mut game := Game{
		title: title
		quit: false
		status: .play
		map: map
		must_draw: true
		crates: crates
		stored: stored
		w: w
		h: h
		px: px
		py: py
		level: 1
		screen: 0
	}
	C.SDL_Init(C.SDL_INIT_VIDEO)
	C.atexit(C.SDL_Quit)
	vsdl2.create_window_and_renderer(width, height, 0, &game.window, &game.renderer)
	C.SDL_SetWindowTitle(game.window, game.title.str)
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
		if e == empty || e == store {
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
	if g.map[y][x] & crate == crate {
		to_x := x + dx
		to_y := y + dy
		if g.can_move(to_x, to_y) {
			g.map[y][x] &= ~crate
			if g.map[y][x] & store == store {
				g.stored--
			}
			g.map[to_y][to_x] |= crate
			if g.map[to_y][to_x] & store == store {
				g.stored++
				if g.stored == g.crates {
					g.status = .win
					println('You win level $g.level, $g.title !!! :-)')
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
		x := (width - g.w * g.bw) / 2
		y := (height - g.h * g.bh) / 2
		for j, line in g.map {
			for i, e in line {
				col = match e {
					empty {
						if g.px == i && g.py == j { vsdl2.Color{byte(255), byte(255), byte(255), byte(0)} } else { vsdl2.Color{byte(66), byte(66), byte(66), byte(0)} }
					}
					store {
						if g.px == i && g.py == j { vsdl2.Color{byte(190), byte(190), byte(190), byte(0)} } else { vsdl2.Color{byte(105), byte(105), byte(105), byte(0)} }
					}
					crate {
						vsdl2.Color{byte(156), byte(100), byte(63), byte(0)}
					}
					wall {
						vsdl2.Color{byte(255), byte(0), byte(0), byte(0)}
					}
					crate | store {
						if g.status == .win { vsdl2.Color{byte(235), byte(178), byte(0), byte(0)} } else { vsdl2.Color{byte(109), byte(69), byte(43), byte(0)} }
					}
					else {
						vsdl2.Color{byte(0), byte(255), byte(0), byte(0)}
					}
				}
				rect = vsdl2.Rect{x + i * g.bw, y + j * g.bh, g.bw, g.bh}
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
	ev := vsdl2.Event{}
	mut cont := true
	for cont && 0 < vsdl2.poll_event(&ev) {
		cont = match g.status {
			.win { g.handle_event_win(ev) }
			.play { g.handle_event_play(ev) }
		}
	}
}

fn (mut g Game) handle_event_play(ev vsdl2.Event) bool {
	mut cont := true
	match int(ev.@type) {
		C.SDL_QUIT {
			g.quit = true
			cont = false
		}
		C.SDL_KEYDOWN {
			key := ev.key.keysym.sym
			match key {
				C.SDLK_ESCAPE {
					g.quit = true
					cont = false
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
	return cont
}

fn (mut g Game) handle_event_win(ev vsdl2.Event) bool {
	mut cont := true
	match int(ev.@type) {
		C.SDL_QUIT {
			g.quit = true
			cont = false
		}
		C.SDL_KEYDOWN {
			key := ev.key.keysym.sym
			match key {
				C.SDLK_ESCAPE {
					g.quit = true
					cont = false
				}
				else {}
			}
		}
		else {}
	}
	return cont
}

fn (g Game) sleep() {
	vsdl2.delay(1000 / 60)
}

fn main() {
	mut game := new_game('クレートさん')
	for !game.quit {
		game.handle_events()
		game.draw_map()
		game.sleep()
	}
}
