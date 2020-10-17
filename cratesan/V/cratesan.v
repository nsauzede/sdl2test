import nsauzede.vsdl2
import nsauzede.vsdl2.image as img
import os

const (
	zoom        = 2
	text_size   = 8
	text_ratio  = zoom
	white       = vsdl2.Color{255, 255, 255, 0}
	black       = vsdl2.Color{0, 0, 0, 0}
	text_color  = black
	width       = 320 * zoom
	height      = 200 * zoom
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
	res_dir     = os.resource_abs_path('../res')
	font_file   = res_dir + '/fonts/RobotoMono-Regular.ttf'
	levels_file = res_dir + '/levels/levels.txt'
	base_dir    = os.dir(os.real_path(os.executable()))
	scores_file = base_dir + '/scores.txt'
	i_empty     = res_dir + '/images/empty.png'
	i_store     = res_dir + '/images/store.png'
	i_stored    = res_dir + '/images/stored.png'
	i_crate     = res_dir + '/images/crate.png'
	i_player    = res_dir + '/images/player.png'
	i_splayer   = res_dir + '/images/splayer.png'
	i_wall      = res_dir + '/images/wall.png'
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
	pause
	win
}

struct Level {
	crates int // number of crates
mut:
	w      int // map dims
	h      int // map dims
	map    [][]byte // map
	stored int // number of stored crates
	px     int // player pos
	py     int // player pos
}

struct Score {
mut:
	level  int
	pushes int
	moves  int
	time_s u32
}

struct Snapshot {
mut:
	state       State
	undo_states []State
}

struct State {
mut:
	map    [][]byte // TODO : make it an option ? (ie: map ?[][]byte) -- seems broken rn
	stored int
	px     int
	py     int
	time_s u32
	pushes int
	moves  int
	undos  int
}

struct Game {
	title      string
mut:
	quit       bool
	status     Status
	must_draw  bool
	// Game levels
	levels     []Level
	level      int // current level
	snapshots  []Snapshot // saved snapshots (currently only one max)
	snap       Snapshot // current snapshot : state + undo_states
	last_ticks u32
	scores     []Score
	debug      bool
	bw         int // block dims
	bh         int // block dims
	// SDL stuff
	window     voidptr
	renderer   voidptr
	screen     &vsdl2.Surface
	texture    voidptr
	width      int
	height     int
	block_surf []&vsdl2.Surface
	block_text []voidptr
	// TTF
	font       voidptr
}

fn (g Game) save_state(mut state State, full bool) {
	unsafe {
		*state = g.snap.state
	}
	mut map := [][]byte{}
	if full {
		map = g.snap.state.map.clone()
	}
	state.map = map
}

fn (mut g Game) restore_state(state State) {
	map := g.snap.state.map
	g.snap.state = state
	if state.map.len == 0 {
		g.snap.state.map = map
	}
	if g.status == .win { // remove current level score, if win
		for i, score in g.scores {
			if score.level == g.level {
				println('deleting score $i : $score')
				g.scores.delete(i)
			}
		}
	}
}

fn (mut g Game) save_snapshot() {
	g.snapshots = []Snapshot{} // limit snapshots depth to 1
	g.snapshots << Snapshot{
		undo_states: g.snap.undo_states.clone()
	}
	g.save_state(mut g.snapshots[0].state, true)
	g.debug_dump()
}

fn (mut g Game) load_snapshot() {
	if g.snapshots.len > 0 {
		snap := g.snapshots.pop()
		g.snap.undo_states = snap.undo_states
		g.restore_state(snap.state)
		g.must_draw = true
		save_scores(g.scores)
		g.save_snapshot() // limit snapshots depth to 1
	}
}

fn (mut g Game) pop_undo() {
	if g.snap.undo_states.len > 0 {
		state := g.snap.undo_states.pop()
		g.restore_state(state)
		g.must_draw = true
		save_scores(g.scores)
		g.snap.state.undos++
		g.debug_dump()
	}
}

fn (mut g Game) push_undo(full bool) {
	mut state := State{}
	g.save_state(mut state, full)
	g.snap.undo_states << state
}

fn (mut g Game) can_move(x, y int) bool {
	if x < g.levels[g.level].w && y < g.levels[g.level].h {
		e := g.snap.state.map[y][x]
		if e == empty || e == store {
			return true
		}
	}
	return false
}

// Try to move to x+dx:y+dy and also push to x+2dx:y+2dy
fn (mut g Game) try_move(dx, dy int) bool {
	mut do_it := false
	x := g.snap.state.px + dx
	y := g.snap.state.py + dy
	if g.snap.state.map[y][x] & crate == crate {
		to_x := x + dx
		to_y := y + dy
		if g.can_move(to_x, to_y) {
			do_it = true
			g.push_undo(true)
			g.snap.state.pushes++
			g.snap.state.map[y][x] &= ~crate
			if g.snap.state.map[y][x] & store == store {
				g.snap.state.stored--
			}
			g.snap.state.map[to_y][to_x] |= crate
			if g.snap.state.map[to_y][to_x] & store == store {
				g.snap.state.stored++
				if g.snap.state.stored == g.levels[g.level].crates {
					g.status = .win
					g.save_score()
					save_scores(g.scores)
				}
			}
		}
	} else {
		do_it = g.can_move(x, y)
		if do_it {
			g.push_undo(false)
		}
	}
	if do_it {
		g.snap.state.moves++
		g.snap.state.px = x
		g.snap.state.py = y
		g.must_draw = true
		g.debug_dump()
	}
	return do_it
}

fn (g Game) debug_dump() {
	if g.debug {
		println('level=$g.level crates=$g.snap.state.stored/$g.levels[g.level].crates moves=$g.snap.state.moves pushes=$g.snap.state.pushes undos=$g.snap.state.undos/$g.snap.undo_states.len snaps=$g.snapshots.len time=$g.snap.state.time_s')
	}
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
		g.snap = Snapshot{
			state: State{
				map: g.levels[g.level].map.clone()
			}
		}
		g.snap.undo_states = []State{}
		g.snap.state.undos = 0
		g.snapshots = []Snapshot{}
		g.snap.state.stored = g.levels[g.level].stored
		g.levels[g.level].w = g.levels[g.level].w
		g.levels[g.level].h = g.levels[g.level].h
		g.snap.state.moves = 0
		g.snap.state.pushes = 0
		g.snap.state.time_s = 0
		g.last_ticks = vsdl2.get_ticks()
		g.snap.state.px = g.levels[g.level].px
		g.snap.state.py = g.levels[g.level].py
		g.bw = g.width / g.levels[g.level].w
		g.bh = (g.height - text_size * text_ratio) / g.levels[g.level].h
		g.debug_dump()
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
	save_scores(g.scores)
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
	if !isnil(g.font) {
		C.TTF_CloseFont(g.font)
	}
}

fn load_scores() []Score {
	mut ret := []Score{}
	s := os.read_file_array<Score>(scores_file)
	if s.len > 0 {
		ret = s
	}
	return ret
}

fn (mut g Game) save_score() {
	mut push_score := true
	for score in g.scores {
		if score.level == g.level {
			push_score = false
		}
	}
	if push_score {
		s := Score{
			level: g.level
			pushes: g.snap.state.pushes
			moves: g.snap.state.moves
			time_s: g.snap.state.time_s
		}
		g.scores << s
	}
}

fn save_scores(scores []Score) {
	if scores.len > 0 {
		os.write_file_array(scores_file, scores)
	} else {
		os.rm(scores_file)
	}
}

fn new_game(title string) Game {
	levels := load_levels()
	scores := load_scores()
	mut g := Game{
		title: title
		quit: false
		status: .play
		must_draw: true
		levels: levels
		scores: scores
		debug: false
		screen: 0
		font: 0
	}
	C.SDL_Init(C.SDL_INIT_VIDEO)
	C.atexit(C.SDL_Quit)
	C.TTF_Init()
	C.atexit(C.TTF_Quit)
	vsdl2.create_window_and_renderer(width, height, 0, &g.window, &g.renderer)
	C.SDL_SetWindowTitle(g.window, g.title.str)
	g.screen = vsdl2.create_rgb_surface(0, width, height, bpp, 0x00FF0000, 0x0000FF00,
		0x000000FF, 0xFF000000)
	g.texture = C.SDL_CreateTexture(g.renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING,
		width, height)
	g.font = C.TTF_OpenFont(font_file.str, text_size * text_ratio)
	g.width = width
	g.height = height
	mut dones := [false].repeat(levels.len)
	for score in scores {
		if score.level >= 0 && score.level < levels.len {
			dones[score.level] = true
		}
	}
	mut level := 0
	for done in dones {
		if !done {
			break
		}
		level++
	}
	g.set_level(level)
	g.load_tex(i_empty)
	g.load_tex(i_store)
	g.load_tex(i_stored)
	g.load_tex(i_crate)
	g.load_tex(i_player)
	g.load_tex(i_splayer)
	g.load_tex(i_wall)
	return g
}

fn (g &Game) draw_text(x, y int, text string, tcol vsdl2.Color) {
	if !isnil(g.font) {
		tcol_ := C.SDL_Color{tcol.r, tcol.g, tcol.b, tcol.a}
		tsurf := C.TTF_RenderText_Solid(g.font, text.str, tcol_)
		ttext := C.SDL_CreateTextureFromSurface(g.renderer, tsurf)
		texw := 0
		texh := 0
		C.SDL_QueryTexture(ttext, 0, 0, &texw, &texh)
		dstrect := vsdl2.Rect{x, y, texw, texh}
		vsdl2.render_copy(g.renderer, ttext, voidptr(0), &dstrect)
		C.SDL_DestroyTexture(ttext)
		vsdl2.free_surface(tsurf)
	}
}

fn (mut g Game) draw_map() {
	curr_ticks := vsdl2.get_ticks()
	if curr_ticks > g.last_ticks + 1000 {
		if g.status == .play {
			g.snap.state.time_s += (curr_ticks - g.last_ticks) / 1000
		}
		g.last_ticks = curr_ticks
		g.must_draw = true
	}
	if g.must_draw {
		C.SDL_RenderClear(g.renderer)
		mut rect := vsdl2.Rect{0, 0, g.width, g.height}
		mut col := vsdl2.Color{byte(0), byte(0), byte(0), byte(255)}
		vsdl2.fill_rect(g.screen, &rect, col)
		// bottom status bar
		rect = vsdl2.Rect{0, height - text_size * text_ratio, g.width, text_size * text_ratio}
		vsdl2.fill_rect(g.screen, &rect, white)
		C.SDL_UpdateTexture(g.texture, 0, g.screen.pixels, g.screen.pitch)
		C.SDL_RenderCopy(g.renderer, g.texture, voidptr(0), voidptr(0))
		x := (width - g.levels[g.level].w * g.bw) / 2
		y := 0
		for j, line in g.snap.state.map {
			for i, e in line {
				rect = vsdl2.Rect{x + i * g.bw, y + j * g.bh, g.bw, g.bh}
				tex := match e {
					empty {
						if g.snap.state.px == i && g.snap.state.py == j { g.block_text[n_player] } else { g.block_text[n_empty] }
					}
					store {
						if g.snap.state.px == i && g.snap.state.py == j { g.block_text[n_splayer] } else { g.block_text[n_store] }
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
		status := match g.status {
			.win { 'You win! Press Return..' }
			.pause { '*PAUSE* Press Space..' }
			else { '' }
		}
		ts := g.snap.state.time_s % 60
		tm := (g.snap.state.time_s / 60) % 60
		th := g.snap.state.time_s / 3600
		g.draw_text(0, g.height - text_size * text_ratio - 4, '${g.level+1:02d}| moves: ${g.snap.state.moves:04d} pushes: ${g.snap.state.pushes:04d} time:$th:${tm:02}:${ts:02} $status',
			text_color)
		C.SDL_RenderPresent(g.renderer)
		g.must_draw = false
	}
}

fn (mut g Game) handle_events() {
	ev := vsdl2.Event{}
	mut cont := true
	for cont && 0 < vsdl2.poll_event(&ev) {
		match int(ev.@type) {
			C.SDL_QUIT {
				g.quit = true
				cont = false
				break
			}
			C.SDL_KEYDOWN {
				key := ev.key.keysym.sym
				match key {
					C.SDLK_ESCAPE {
						g.quit = true
						cont = false
						break
					}
					C.SDLK_d {
						g.debug = !g.debug
						g.debug_dump()
						continue
					}
					else {}
				}
			}
			else {}
		}
		cont = match g.status {
			.win { g.handle_event_win(ev) }
			.play { g.handle_event_play(ev) }
			.pause { g.handle_event_pause(ev) }
		}
	}
}

fn (mut g Game) handle_event_play(ev vsdl2.Event) bool {
	mut cont := true
	match int(ev.@type) {
		C.SDL_KEYDOWN {
			key := ev.key.keysym.sym
			match key {
				C.SDLK_SPACE {
					g.status = .pause
					g.must_draw = true
					cont = false
				}
				C.SDLK_r {
					g.set_level(g.level)
					cont = false
				}
				C.SDLK_w {
					g.status = .win
					g.must_draw = true
					cont = false
				}
				C.SDLK_u {
					g.pop_undo()
				}
				C.SDLK_s {
					g.save_snapshot()
				}
				C.SDLK_l {
					g.load_snapshot()
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

fn (mut g Game) handle_event_pause(ev vsdl2.Event) bool {
	mut cont := true
	match int(ev.@type) {
		C.SDL_KEYDOWN {
			key := ev.key.keysym.sym
			match key {
				C.SDLK_SPACE {
					g.status = .play
					g.must_draw = true
					cont = false
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
		C.SDL_KEYDOWN {
			key := ev.key.keysym.sym
			match key {
				C.SDLK_RETURN {
					if g.set_level(g.level + 1) {
					} else {
						println('Game over.')
						g.quit = true
						cont = false
					}
				}
				C.SDLK_u {
					g.pop_undo()
					g.status = .play
					g.must_draw = true
					cont = false
				}
				C.SDLK_r {
					g.set_level(g.level)
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
	mut game := new_game('クレートさん V')
	for !game.quit {
		game.handle_events()
		game.draw_map()
		game.sleep()
	}
	game.delete()
}
