extern crate sdl2;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;

use std::env::current_exe;
use std::fs::File;
use std::io::Read;
use std::thread::sleep;
use std::time::Duration;

const EMPTY: u8 = 0x0;
const STORE: u8 = 0x1;
const CRATE: u8 = 0x2;
const PLAYER: u8 = 0x4;
const WALL: u8 = 0x8;
const WIDTH: u32 = 320;
const HEIGHT: u32 = 200;
const C_EMPTY: char = ' ';
const C_STORE: char = '.';
const C_STORED: char = '*';
const C_CRATE: char = '$';
const C_PLAYER: char = '@';
const C_SPLAYER: char = '&';
const C_WALL: char = '#';
const LEVELS_FILE: &str = "levels.txt";

type Map = Vec<Vec<u8>>;
struct Level {
    map: Map,
    crates: u32,
    stored: u32,
    w: usize,
    h: usize,
    px: usize,
    py: usize,
}
struct Game {
    quit: bool,
    win: bool,
    must_draw: bool,
    levels: Vec<Level>,
    level: usize,
    // following are copies of current level's
    crates: u32,
    stored: u32,
    w: usize,
    h: usize,
    px: usize,
    py: usize,
}

impl Game {
    fn load_levels() -> Vec<Level> {
        let root_dir = current_exe().unwrap();
        let root_dir = root_dir
            .parent()
            .unwrap()
            .parent()
            .unwrap()
            .parent()
            .unwrap();
        let parent_dir = root_dir.parent().unwrap();
        let levels_file = parent_dir.join("res").join("levels").join(LEVELS_FILE);
        let levels_file = levels_file.to_str().unwrap();
        let mut levels = Vec::new();
        let mut vlevels = Vec::new();
        let mut slevel = String::new();
        let mut level = 1;
        let mut slevels = String::new();
        let mut f = File::open(levels_file).unwrap();
        f.read_to_string(&mut slevels).unwrap();
        for line in slevels.lines() {
            if line.is_empty() {
                if !slevel.is_empty() {
                    vlevels.push(slevel);
                    slevel = "".to_string();
                }
                continue;
            }
            if line.starts_with(';') {
                continue;
            }
            slevel = format!("{}\n{}", slevel, line);
        }
        if !slevel.is_empty() {
            vlevels.push(slevel);
        }
        for s in vlevels {
            let mut map = Vec::new();
            let mut crates = 0;
            let mut storages = 0;
            let mut stored = 0;
            let mut w = 0;
            let mut h = 0;
            let mut px = 0;
            let mut py = 0;
            let mut player_found = false;
            for line in s.lines() {
                if line.len() > w {
                    w = line.len();
                }
            }
            for line in s.lines() {
                if line.is_empty() {
                    continue;
                }
                let mut v = vec![EMPTY; w];
                for (i, e) in line.chars().enumerate() {
                    match e {
                        C_EMPTY => {
                            v[i] = EMPTY;
                        }
                        C_STORE => {
                            v[i] = STORE;
                            storages += 1;
                        }
                        C_CRATE => {
                            v[i] = CRATE;
                            crates += 1;
                        }
                        C_STORED => {
                            v[i] = CRATE | STORE;
                            storages += 1;
                            crates += 1;
                            stored += 1;
                        }
                        C_PLAYER => {
                            if player_found {
                                panic!("Player found multiple times in level {}", level);
                            };
                            px = i;
                            py = h;
                            player_found = true;
                            v[i] = EMPTY;
                        }
                        C_SPLAYER => {
                            if player_found {
                                panic!("Player found multiple times in level {}", level);
                            };
                            px = i;
                            py = h;
                            player_found = true;
                            v[i] = STORE;
                            storages += 1;
                        }
                        C_WALL => {
                            v[i] = WALL;
                        }
                        _ => {
                            panic!("Invalid element [{}] in level", e);
                        }
                    }
                }
                map.push(v);
                h += 1;
            }
            if crates != storages {
                panic!(
                    "Mismatch between crates={} and storages={} in level",
                    crates, storages
                );
            }
            if !player_found {
                panic!("Player not found in level {}", level);
            } else {
            }
            levels.push(Level {
                map,
                crates,
                stored,
                w,
                h,
                px,
                py,
            });
            level += 1;
        }
        levels
    }
    fn new() -> Game {
        let levels = Game::load_levels();
        let mut g = Game {
            quit: false,
            win: false,
            must_draw: true,
            levels,
            level: 0,
            crates: 0,
            stored: 0,
            w: 0,
            h: 0,
            px: 0,
            py: 0,
        };
        g.set_level(0);
        g
    }
    fn set_level(&mut self, level: usize) -> bool {
        if level < self.levels.len() {
            self.win = false;
            self.must_draw = true;
            self.level = level;
            self.crates = self.levels[level].crates;
            self.stored = self.levels[level].stored;
            self.w = self.levels[level].w;
            self.h = self.levels[level].h;
            self.px = self.levels[level].px;
            self.py = self.levels[level].py;
            true
        } else {
            false
        }
    }
    fn can_move(&self, x: usize, y: usize) -> bool {
        if x < self.w && y < self.h {
            let e = self.levels[self.level].map[y][x];
            if e == EMPTY || e == STORE {
                return true;
            }
        }
        false
    }
    /// Try to move to x+dx:y+dy and also push to x+2dx:y+2dy
    fn try_move(&mut self, dx: isize, dy: isize) {
        let mut do_it = false;
        let x = self.px as isize + dx;
        let y = self.py as isize + dy;
        if x < 0 || y < 0 {
            return;
        }
        let x = x as usize;
        let y = y as usize;
        if x >= self.w || y >= self.h {
            return;
        }
        if self.levels[self.level].map[y][x] & CRATE == CRATE {
            let to_x = (x as isize + dx) as usize;
            let to_y = (y as isize + dy) as usize;
            if self.can_move(to_x, to_y) {
                self.levels[self.level].map[y][x] &= !CRATE;
                if self.levels[self.level].map[y][x] & STORE == STORE {
                    self.stored -= 1;
                }
                self.levels[self.level].map[to_y][to_x] |= CRATE;
                if self.levels[self.level].map[to_y][to_x] & STORE == STORE {
                    self.stored += 1;
                    if self.stored == self.crates {
                        self.win = true;
                    }
                }
                do_it = true;
            }
        } else {
            do_it = self.can_move(x, y);
        }
        if do_it {
            self.px = x;
            self.py = y;
            self.must_draw = true;
        }
    }
    fn draw_map(&mut self) {
        if self.must_draw {
            for (j, line) in self.levels[self.level].map.iter().enumerate() {
                for (i, &e) in line.iter().enumerate() {
                    let c = if e == EMPTY {
                        if self.px == i && self.py == j {
                            C_PLAYER
                        } else {
                            C_EMPTY
                        }
                    } else if e == STORE {
                        if self.px == i && self.py == j {
                            C_SPLAYER
                        } else {
                            C_STORE
                        }
                    } else if e == CRATE {
                        C_CRATE
                    } else if e == WALL {
                        C_WALL
                    } else if e == PLAYER {
                        C_PLAYER
                    } else if e == CRATE | STORE {
                        C_STORED
                    } else if e == PLAYER | STORE {
                        C_SPLAYER
                    } else {
                        '?'
                    };
                    print!("{}", c);
                }
                println!();
            }
            self.must_draw = false;
        }
    }

    fn handle_events(&mut self, event_pump: &mut sdl2::EventPump) {
        if self.win {
            println!("YOU WIN level {} !!!!", self.level + 1);
            if self.set_level(self.level + 1) {
            } else {
                self.quit = true;
            }
            return;
        }
        for event in event_pump.poll_iter() {
            match event {
                Event::Quit { .. } => {
                    self.quit = true;
                    break;
                }
                Event::KeyDown {
                    keycode: Some(Keycode::Escape),
                    ..
                } => {
                    self.quit = true;
                    break;
                }
                Event::KeyDown {
                    keycode: Some(Keycode::Down),
                    ..
                } => {
                    self.try_move(0, 1);
                }
                Event::KeyDown {
                    keycode: Some(Keycode::Right),
                    ..
                } => {
                    self.try_move(1, 0);
                }
                Event::KeyDown {
                    keycode: Some(Keycode::Left),
                    ..
                } => {
                    self.try_move(-1, 0);
                }
                Event::KeyDown {
                    keycode: Some(Keycode::Up),
                    ..
                } => {
                    self.try_move(0, -1);
                }
                Event::KeyDown {
                    keycode: Some(k), ..
                } if (k == Keycode::RCtrl
                    || k == Keycode::LCtrl
                    || k == Keycode::PageDown
                    || k == Keycode::Space) => {}
                _ => {}
            }
        }
    }
}

fn main() {
    let sdl_context = sdl2::init().expect("SDL initialization failed");
    let video_subsystem = sdl_context
        .video()
        .expect("Couldn't get SDL video subsystem");
    let width = WIDTH;
    let height = HEIGHT;
    let _window = video_subsystem
        .window("クレートさん", width, height)
        .position_centered()
        .build()
        .expect("Failed to create window");
    let mut event_pump = sdl_context.event_pump().expect(
        "Failed to get
          SDL event pump",
    );
    let mut game = Game::new();
    while !game.quit {
        game.handle_events(&mut event_pump);
        game.draw_map();
        sleep(Duration::new(0, 1_000_000_000u32 / 60));
    }
}
