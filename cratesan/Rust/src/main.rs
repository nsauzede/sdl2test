extern crate sdl2;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;
use sdl2::pixels::Color;
use sdl2::rect::Rect;
use sdl2::render::{Canvas, Texture, TextureCreator};
use sdl2::video::{Window, WindowContext};

use std::env::current_exe;
use std::fs::File;
use std::io::Read;
use std::thread::sleep;
use std::time::Duration;

const EMPTY: u8 = 0x0;
const STORE: u8 = 0x1;
const CRATE: u8 = 0x2;
//const PLAYER: u8 = 0x4;
const WALL: u8 = 0x8;
const WIDTH: usize = 320;
const HEIGHT: usize = 200;
const NUM_TEXTURES: usize = 9;
const TEX_PLAYER: usize = 0;
const TEX_EMPTY: usize = 1;
const TEX_SPLAYER: usize = 2;
const TEX_STORE: usize = 3;
const TEX_CRATE: usize = 4;
const TEX_WALL: usize = 5;
const TEX_STOREDW: usize = 6;
const TEX_STORED: usize = 7;
const TEX_INV: usize = 8;
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

enum Status {
    Play,
    Win,
}

struct Game {
    quit: bool,
    status: Status,
    must_draw: bool,
    levels: Vec<Level>,
    level: usize,
    // following are copies of current level's
    crates: u32,
    stored: u32,
    /// map dims
    w: usize,
    h: usize,
    /// player pos
    px: usize,
    py: usize,
    /// block dims
    bw: usize,
    bh: usize,
    width: usize,
    height: usize,
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
            let mut stores = 0;
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
                            stores += 1;
                        }
                        C_CRATE => {
                            v[i] = CRATE;
                            crates += 1;
                        }
                        C_STORED => {
                            v[i] = CRATE | STORE;
                            stores += 1;
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
                            stores += 1;
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
            if crates != stores {
                panic!(
                    "Mismatch between crates={} and stores={} in level",
                    crates, stores
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
    fn new(width: usize, height: usize) -> Game {
        let levels = Game::load_levels();
        let mut g = Game {
            quit: false,
            status: Status::Play,
            must_draw: true,
            levels,
            level: 0,
            crates: 0,
            stored: 0,
            w: 0,
            h: 0,
            px: 0,
            py: 0,
            bw: 0,
            bh: 0,
            width,
            height,
        };
        g.set_level(0);
        g
    }
    fn set_level(&mut self, level: usize) -> bool {
        if level < self.levels.len() {
            self.status = Status::Play;
            self.must_draw = true;
            self.level = level;
            self.crates = self.levels[level].crates;
            self.stored = self.levels[level].stored;
            self.w = self.levels[level].w;
            self.h = self.levels[level].h;
            self.px = self.levels[level].px;
            self.py = self.levels[level].py;
            self.bw = self.width / self.w;
            self.bh = self.height / self.h;
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
                        self.status = Status::Win;
                        println!("YOU WIN level {} !!!!", self.level + 1);
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
    fn draw_map(
        &mut self,
        canvas: &mut sdl2::render::Canvas<sdl2::video::Window>,
        textures: &[sdl2::render::Texture<'_>; NUM_TEXTURES],
    ) {
        if self.must_draw {
            canvas.set_draw_color(Color::RGB(0, 0, 0));
            canvas.clear();
            let x = (WIDTH - self.w * self.bw) / 2;
            let y = (HEIGHT - self.h * self.bh) / 2;
            for (j, line) in self.levels[self.level].map.iter().enumerate() {
                for (i, &e) in line.iter().enumerate() {
                    let idx = if e == EMPTY {
                        if self.px == i && self.py == j {
                            TEX_PLAYER
                        } else {
                            TEX_EMPTY
                        }
                    } else if e == STORE {
                        if self.px == i && self.py == j {
                            TEX_SPLAYER
                        } else {
                            TEX_STORE
                        }
                    } else if e == CRATE {
                        TEX_CRATE
                    } else if e == WALL {
                        TEX_WALL
                    } else if e == CRATE | STORE {
                        match self.status {
                            Status::Win => TEX_STOREDW,
                            _ => TEX_STORED,
                        }
                    } else {
                        TEX_INV
                    };
                    canvas
                        .copy(
                            &textures[idx as usize],
                            None,
                            Rect::new(
                                (x + i * self.bw) as i32,
                                (y + j * self.bh) as i32,
                                self.bw as u32,
                                self.bh as u32,
                            ),
                        )
                        .expect("Couldn't copy texture into window");
                }
            }
            canvas.present();
            self.must_draw = false;
        }
    }

    fn handle_events(&mut self, event_pump: &mut sdl2::EventPump) {
        for event in event_pump.poll_iter() {
            if !match self.status {
                Status::Win => self.handle_event_win(event),
                Status::Play => self.handle_event_play(event),
            } {
                break;
            }
        }
    }
    fn handle_event_win(&mut self, event: sdl2::event::Event) -> bool {
        let mut cont = true;
        match event {
            Event::Quit { .. } => {
                self.quit = true;
                cont = false;
            }
            Event::KeyDown {
                keycode: Some(k), ..
            } => match k {
                Keycode::Escape => {
                    self.quit = true;
                    cont = false;
                }
                Keycode::Return => {
                    if self.set_level(self.level + 1) {
                    } else {
                        self.quit = true;
                    }
                }
                _ => {}
            },
            _ => {}
        }
        cont
    }
    fn handle_event_play(&mut self, event: sdl2::event::Event) -> bool {
        let mut cont = true;
        match event {
            Event::Quit { .. } => {
                self.quit = true;
                cont = false;
            }
            Event::KeyDown {
                keycode: Some(k), ..
            } => match k {
                Keycode::Escape => {
                    self.quit = true;
                    cont = false;
                }
                Keycode::Up => {
                    self.try_move(0, -1);
                }
                Keycode::Down => {
                    self.try_move(0, 1);
                }
                Keycode::Left => {
                    self.try_move(-1, 0);
                }
                Keycode::Right => {
                    self.try_move(1, 0);
                }
                _ => {}
            },
            _ => {}
        }
        cont
    }
}

fn create_texture_rect<'a>(
    canvas: &mut Canvas<Window>,
    texture_creator: &'a TextureCreator<WindowContext>,
    r: u8,
    g: u8,
    b: u8,
    width: u32,
    height: u32,
) -> Option<Texture<'a>> {
    if let Ok(mut square_texture) = texture_creator.create_texture_target(None, width, height) {
        canvas
            .with_texture_canvas(&mut square_texture, |texture| {
                texture.set_draw_color(Color::RGB(r, g, b));
                texture.clear();
            })
            .expect("Failed to color a texture");
        Some(square_texture)
    } else {
        None
    }
}

fn main() {
    let title = "クレートさん";
    let width = WIDTH;
    let height = HEIGHT;
    let mut game = Game::new(width, height);
    let sdl_context = sdl2::init().expect("SDL initialization failed");
    let video_subsystem = sdl_context
        .video()
        .expect("Couldn't get SDL video subsystem");
    let window = video_subsystem
        .window(title, width as u32, height as u32)
        .position_centered()
        .build()
        .expect("Failed to create window");
    let mut canvas = window
        .into_canvas()
        .target_texture()
        .present_vsync()
        .build()
        .expect("Couldn't get window's canvas");
    let mut event_pump = sdl_context.event_pump().expect(
        "Failed to get
          SDL event pump",
    );
    let texture_creator: TextureCreator<_> = canvas.texture_creator();
    macro_rules! texture {
        ($r:expr, $g:expr, $b:expr) => {
            create_texture_rect(
                &mut canvas,
                &texture_creator,
                $r,
                $g,
                $b,
                game.bw as u32,
                game.bh as u32,
            )
            .unwrap()
        };
    }
    let textures = [
        texture!(255, 255, 255),
        texture!(66, 66, 66),
        texture!(190, 190, 190),
        texture!(105, 105, 105),
        texture!(156, 100, 63),
        texture!(255, 0, 0),
        texture!(235, 178, 0),
        texture!(109, 69, 43),
        texture!(0, 255, 0),
    ];
    while !game.quit {
        game.handle_events(&mut event_pump);
        game.draw_map(&mut canvas, &textures);
        sleep(Duration::new(0, 1_000_000_000u32 / 60));
    }
}
