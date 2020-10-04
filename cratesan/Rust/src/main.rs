extern crate sdl2;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;

use std::thread::sleep;
use std::time::Duration;

const EMPTY: u8 = 0x0;
const STORAGE: u8 = 0x1;
const BOX: u8 = 0x2;
const PLAYER: u8 = 0x4;
const WALL: u8 = 0x8;
const WIDTH: u32 = 320;
const HEIGHT: u32 = 200;
const LEVEL1: &str = "
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
";

struct Game {
    quit: bool,
    win: bool,
    map: Vec<Vec<u8>>,
    must_draw: bool,
    boxes: u32,
    stored: u32,
    current_level: u32,
    w: usize,
    h: usize,
    px: usize,
    py: usize,
}

impl Game {
    fn new() -> Game {
        let mut map = Vec::new();
        let mut boxes = 0;
        let mut storages = 0;
        let mut stored = 0;
        let mut w = 0;
        let mut h = 0;
        let mut px = 0;
        let mut py = 0;
        let mut player_found = false;
        for line in LEVEL1.lines() {
            if line.len() > w {
                w = line.len();
            }
        }
        for line in LEVEL1.lines() {
            if line.is_empty() {
                continue;
            }
            let mut v = vec![EMPTY; w];
            for (i, e) in line.chars().enumerate() {
                match e {
                    '.' | ' ' => {
                        v[i] = EMPTY;
                    }
                    's' => {
                        v[i] = STORAGE;
                        storages += 1;
                    }
                    'b' => {
                        v[i] = BOX;
                        boxes += 1;
                    }
                    'B' => {
                        v[i] = BOX | STORAGE;
                        storages += 1;
                        boxes += 1;
                        stored += 1;
                    }
                    'p' => {
                        if player_found {
                            panic!("Player found multiple times in level");
                        };
                        px = i;
                        py = h;
                        player_found = true;
                        v[i] = EMPTY;
                    }
                    'P' => {
                        if player_found {
                            panic!("Player found multiple times in level");
                        };
                        px = i;
                        py = h;
                        player_found = true;
                        v[i] = STORAGE;
                        storages += 1;
                    }
                    'w' => {
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
        if boxes != storages {
            panic!(
                "Mismatch between boxes={} and storages={} in level",
                boxes, storages
            );
        }
        if !player_found {
            panic!("Player not found in level");
        }
        Game {
            quit: false,
            win: false,
            map,
            must_draw: true,
            boxes,
            stored,
            w,
            h,
            px,
            py,
            current_level: 1,
        }
    }
    fn can_move(&self, x: usize, y: usize) -> bool {
        if x < self.w && y < self.h {
            let e = self.map[y][x];
            if e == EMPTY || e == STORAGE {
                return true;
            }
        }
        false
    }
    /// Try to move to x+dx:y+dy and also push to x+2dx:y+2dy
    fn try_move(&mut self, dx: isize, dy: isize) {
        let mut do_it = false;
        let x = (self.px as isize + dx) as usize;
        let y = (self.py as isize + dy) as usize;
        if self.map[y][x] & BOX == BOX {
            let to_x = (x as isize + dx) as usize;
            let to_y = (y as isize + dy) as usize;
            if self.can_move(to_x, to_y) {
                self.map[y][x] &= !BOX;
                if self.map[y][x] & STORAGE == STORAGE {
                    self.stored -= 1;
                }
                self.map[to_y][to_x] |= BOX;
                if self.map[to_y][to_x] & STORAGE == STORAGE {
                    self.stored += 1;
                    if self.stored == self.boxes {
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
            for (j, line) in self.map.iter().enumerate() {
                for (i, &e) in line.iter().enumerate() {
                    let c = if e == EMPTY {
                        if self.px == i && self.py == j {
                            'p'
                        } else {
                            '.'
                        }
                    } else if e == STORAGE {
                        if self.px == i && self.py == j {
                            'P'
                        } else {
                            's'
                        }
                    } else if e == BOX {
                        'b'
                    } else if e == WALL {
                        'w'
                    } else if e == PLAYER {
                        'p'
                    } else if e == BOX | STORAGE {
                        'B'
                    } else if e == PLAYER | STORAGE {
                        'P'
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
            println!("YOU WIN level {} !!!!", self.current_level);
            self.quit = true;
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
