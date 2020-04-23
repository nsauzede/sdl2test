extern crate sdl2;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;
use sdl2::pixels::Color;
use sdl2::rect::Rect;
use std::time::Duration;

struct State {
	w: u32,
	h: u32,
	scale: u32,
	score: u32,
	fps: u32,
	sdl_context: sdl2::Sdl,
	canvas: sdl2::render::Canvas<sdl2::video::Window>,
	quit: bool,
	tick: u64,
	last_tick: u64,
	last_time: std::time::SystemTime,
}

struct UserInput {
	quit: bool,
}

fn init_state() -> Result<State, String> {
	let w = 200;
	let h = 400;
	let sdl_context = sdl2::init()?;
	let video_subsystem = sdl_context.video()?;
	let window = video_subsystem.window("game", w, h)
		.position_centered()
		.opengl()
		.build()
		.map_err(|e| e.to_string())?;
	let canvas = window.into_canvas().build().map_err(|e| e.to_string())?;

	Ok(State {
		w: w,
		h: h,
		scale: 4,
		score: 42,
		fps: 0,
		sdl_context: sdl_context,
		canvas: canvas,
		quit: false,
		tick: 0,
		last_tick: 0,
		last_time: std::time::SystemTime::now(),
	})
}

fn draw_clear(s: &mut State) -> Result<(), String> {
	s.canvas.set_draw_color(Color::RGB(0, 0, 0));
	s.canvas.clear();
	s.canvas.fill_rect(Rect::new(0, 0, s.w, s.h))?;
	Ok(())
}

fn draw_score(s: &mut State) -> Result<(), String> {
	s.canvas.set_draw_color(Color::RGB(255, 255, 255));
	let mut rect = Rect::new(0,0,s.scale,s.scale);
	let score = s.score;
	let sscore = format!("{}", score);
	let ndigits = sscore.len();
	// 4x5 font
	let fw = 4;
	let fh = 5;
	let stride = (fw + 7) / 8 * fh; // bytes per font element
	let font = [
		/*0-9*/
		0x2,0x5,0x5,0x2,0x0,
		0x2,0x6,0x2,0x7,0x0,
		0x6,0x1,0x2,0x7,0x0,
		0x7,0x3,0x1,0x6,0x0,
		0x4,0x6,0x7,0x2,0x0,
		0x7,0x4,0x1,0x6,0x0,
		0x3,0x6,0x5,0x2,0x0,
		0x7,0x1,0x2,0x4,0x0,
		0x5,0x2,0x5,0x2,0x0,
		0x2,0x5,0x3,0x6,0x0,
	];
	for n in 0..ndigits {
		let digit = sscore.chars().nth(n).unwrap() as i32 - '0' as i32;
		for j in 0..fh {
			rect.y = s.scale as i32 * j;
			for i in 0..fw {
				rect.x = s.scale as i32 * (n as i32 * fw + i);
				if 0 != (font[digit as usize * stride as usize + j as usize] & (1 << (fw - i - 1))) {
					s.canvas.fill_rect(rect)?;
				}
			}
		}
	}
	Ok(())
}

fn draw_update(s: &mut State) -> Result<(), String> {
	s.canvas.present();
	Ok(())
}

fn get_user_input(s: &State) -> Result<UserInput, String> {
	let mut ui = UserInput {
		quit: false,
	};
	let mut event_pump = s.sdl_context.event_pump()?;
	for event in event_pump.poll_iter() {
		match event {
			Event::Quit {..} | Event::KeyDown { keycode: Some(Keycode::Escape), .. } => {
				ui.quit = true;
				break
			},
			_ => {}
		}
	}
	Ok(ui)
}

fn process_one_frame(s: &mut State, ui: &UserInput) {
	if ui.quit {
		s.quit = true;
	}
	let now = std::time::SystemTime::now();
	let dur_s = now.duration_since(s.last_time).unwrap().as_secs();
	if dur_s >= 1 {
		s.fps = ((s.tick - s.last_tick) / (dur_s)) as u32;
		s.last_tick = s.tick;
		s.last_time = now;
		// HACK
		s.score = s.fps;
	}
	s.tick += 1;
}

fn draw_everything_on_screen(s: &mut State) -> Result<(), String> {
	draw_clear(s)?;
	draw_score(s)?;
	draw_update(s)?;
	Ok(())
}

fn wait_until_frame_time_elapsed(_s: &State) {
	::std::thread::sleep(Duration::new(0, 16_666_666u32));
}

fn main() -> Result<(), String> {
	let mut state = init_state()?;
	while !state.quit {
		let user_input = get_user_input(&state)?;
		process_one_frame(&mut state, &user_input);
		draw_everything_on_screen(&mut state)?;
		wait_until_frame_time_elapsed(&state);
	}
	Ok(())
}
