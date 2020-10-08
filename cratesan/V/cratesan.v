import nsauzede.vsdl2
import nsauzede.vsdl2.image as img
import os

const (
	width       = 320 * 2
	height      = 200 * 2
	empty       = 0x0
	store       = 0x1
	crate       = 0x2
	wall        = 0x4
	c_empty     = ` `
	c_store     = `.`
	c_stored    = `*`
	c_crate     = `$`
	c_player    = `@`
	c_splayer   = `&`
	c_wall      = `#`
	bpp         = 32
	levels_file = os.resource_abs_path('../res/levels/levels.txt')
	i_empty     = os.resource_abs_path('../res/images/empty.png')
	i_store     = os.resource_abs_path('../res/images/store.png')
	i_stored    = os.resource_abs_path('../res/images/stored.png')
	i_crate     = os.resource_abs_path('../res/images/crate.png')
	i_player    = os.resource_abs_path('../res/images/player.png')
	i_splayer   = os.resource_abs_path('../res/images/splayer.png')
	i_wall      = os.resource_abs_path('../res/images/wall.png')
	n_empty     = 0
	n_store     = 1
	n_stored    = 2
	n_crate     = 3
	n_player    = 4
	n_splayer   = 5
	n_wall      = 6
)

enum Status {
	play
	win
}

struct Level {
mut:
	map    [][]byte
	crates int
	stored int
	// map dims
	w      int
	h      int
	// player pos
	px     int
	py     int
}

struct Game {
mut:
	title      string
	quit       bool
	status     Status
	must_draw  bool
	levels     []Level
	lev        Level
	level      int
	// following are copies of current level's
	crates     int
	stored     int
	// map dims
	w          int
	h          int
	// player pos
	px         int
	py         int
	// block dims
	bw         int
	bh         int
	// SDL
	window     voidptr
	renderer   voidptr
	screen     &vsdl2.Surface
	texture    voidptr
	width      int
	height     int
	block_surf []&vsdl2.Surface
	block_text []voidptr
}

fn load_levels() []Level {
	mut levels := []Level{}
	mut vlevels := []string{}
	mut slevel := ''
	slevels := os.read_file(levels_file.trim_space()) or {
		panic('Failed to open levels file')
	}
	for line in slevels.split_into_lines() {
		if line.len == 0 {
			if slevel.len > 0 {
				vlevels << slevel
				slevel = ''
			}
			continue
		}
		if line.starts_with(';') {
			continue
		}
		slevel = slevel + '\n' + line
	}
	if slevel.len > 0 {
		vlevels << slevel
	}
	for s in vlevels {
		mut map := [][]byte{}
		mut crates := 0
		mut stores := 0
		mut stored := 0
		mut w := 0
		mut h := 0
		mut px := 0
		mut py := 0
		mut player_found := false
		for line in s.split_into_lines() {
			if line.len > w {
				w = line.len
			}
		}
		for line in s.split_into_lines() {
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
		levels << Level{
			map: map
			crates: crates
			stored: stored
			w: w
			h: h
			px: px
			py: py
		}
	}
	return levels
}

fn (mut g Game) set_level(level int) bool {
	if level < g.levels.len {
		g.status = .play
		g.must_draw = true
		g.level = level
		g.lev = g.levels[level]
		g.lev.map = [][]byte{}
		for j in g.levels[level].map {
			mut v := []byte{}
			for i in j {
				v << i
			}
			g.lev.map << v
		}
		g.crates = g.levels[level].crates
		g.stored = g.levels[level].stored
		g.w = g.levels[level].w
		g.h = g.levels[level].h
		g.px = g.levels[level].px
		g.py = g.levels[level].py
		g.bw = g.width / g.w
		g.bh = g.height / g.h
		return true
	} else {
		return false
	}
}

fn (mut g Game) load_tex(file string) {
	surf := img.load(file)
	if !isnil(surf) {
		g.block_surf << surf
		tex := vsdl2.create_texture_from_surface(g.renderer, surf)
		if !isnil(tex) {
			g.block_text << tex
		}
	}
}

fn (mut g Game) delete() {
	for t in g.block_text {
		if !isnil(t) {
			vsdl2.destroy_texture(t)
		}
	}
	for s in g.block_surf {
		if !isnil(s) {
			vsdl2.free_surface(s)
		}
	}
}

fn new_game(title string) Game {
	levels := load_levels()
	mut g := Game{
		title: title
		quit: false
		status: .play
		must_draw: true
		levels: levels
		screen: 0
	}
	C.SDL_Init(C.SDL_INIT_VIDEO)
	C.atexit(C.SDL_Quit)
	vsdl2.create_window_and_renderer(width, height, 0, &g.window, &g.renderer)
	C.SDL_SetWindowTitle(g.window, g.title.str)
	g.screen = vsdl2.create_rgb_surface(0, width, height, bpp, 0x00FF0000, 0x0000FF00,
		0x000000FF, 0xFF000000)
	g.texture = C.SDL_CreateTexture(g.renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING,
		width, height)
	g.width = width
	g.height = height
	g.set_level(0)
	g.load_tex(i_empty)
	g.load_tex(i_store)
	g.load_tex(i_stored)
	g.load_tex(i_crate)
	g.load_tex(i_player)
	g.load_tex(i_splayer)
	g.load_tex(i_wall)
	return g
}

fn (mut g Game) can_move(x, y int) bool {
	if x < g.w && y < g.h {
		e := g.lev.map[y][x]
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
	if g.lev.map[y][x] & crate == crate {
		to_x := x + dx
		to_y := y + dy
		if g.can_move(to_x, to_y) {
			g.lev.map[y][x] &= ~crate
			if g.lev.map[y][x] & store == store {
				g.stored--
			}
			g.lev.map[to_y][to_x] |= crate
			if g.lev.map[to_y][to_x] & store == store {
				g.stored++
				if g.stored == g.crates {
					g.status = .win
					println('You win level ${g.level+1} ! Press RETURN to proceed..')
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
		mut rect := vsdl2.Rect{0, 0, g.width, g.height}
		mut col := vsdl2.Color{byte(0), byte(0), byte(0), byte(255)}
		vsdl2.fill_rect(g.screen, &rect, col)
		x := (width - g.w * g.bw) / 2
		y := (height - g.h * g.bh) / 2
		for j, line in g.lev.map {
			for i, e in line {
				rect = vsdl2.Rect{x + i * g.bw, y + j * g.bh, g.bw, g.bh}
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
				vsdl2.fill_rect(g.screen, &rect, col)
				tex := match e {
					empty {
						if g.px == i && g.py == j { g.block_text[n_player] } else { g.block_text[n_empty] }
					}
					store {
						if g.px == i && g.py == j { g.block_text[n_splayer] } else { g.block_text[n_store] }
					}
					crate {
						g.block_text[n_crate]
					}
					wall {
						g.block_text[n_wall]
					}
					crate | store {
						g.block_text[n_stored]
					}
					else {
						voidptr(0)
					}
				}
				if !isnil(tex) {
					vsdl2.render_copy(g.renderer, tex, voidptr(0), &rect)
				}
			}
		}
		if g.block_text.len == 0 {
			C.SDL_UpdateTexture(g.texture, 0, g.screen.pixels, g.screen.pitch)
			C.SDL_RenderCopy(g.renderer, g.texture, voidptr(0), voidptr(0))
		}
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
				C.SDLK_r {
					g.set_level(g.level)
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
				C.SDLK_RETURN {
					if g.set_level(g.level + 1) {
					} else {
						cont = false
					}
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
	mut game := new_game('クレートさん V')
	for !game.quit {
		game.handle_events()
		game.draw_map()
		game.sleep()
	}
	game.delete()
}
