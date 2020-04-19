extern crate sdl2;

use sdl2::event::Event;
use sdl2::keyboard::Keycode;
//use sdl2::render::Canvas;
use std::time::Duration;

struct State {
	sdl_context: sdl2::Sdl,
//	window: sdl2::video::Window,
	canvas: sdl2::render::Canvas<sdl2::video::Window>,
	quit: bool,
}

struct UserInput {
	quit: bool,
}

fn init_state() -> Result<State, String> {
	let sdl_context = sdl2::init()?;
	let video_subsystem = sdl_context.video()?;
	let window = video_subsystem.window("game", 200, 400)
		.position_centered()
		.opengl()
		.build()
		.map_err(|e| e.to_string())?;
	let /*mut*/ canvas = window.into_canvas().build().map_err(|e| e.to_string())?;

	Ok(State {
		sdl_context: sdl_context,
//		window: window,
		canvas: canvas,
//		video_subsystem: sdl_context.video()?,
		quit: false,
	})
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
}

//fn draw_everything_on_screen(s: &mut State) -> Result<(), String> {
fn draw_everything_on_screen(s: &mut State) {
	s.canvas.clear();
	s.canvas.present();
//	Ok(())
}

fn wait_until_frame_time_elapsed(_s: &State) {
//	sdl2::SDL_Delay(16);
	::std::thread::sleep(Duration::new(0, 1_000_000_000u32 / 30));
//	sdl2::TimerSubsystem::delay(16);
}

fn main() -> Result<(), String> {
	let mut state = init_state()?;
	while !state.quit {
		let user_input = get_user_input(&state)?;
		process_one_frame(&mut state, &user_input);
//		draw_everything_on_screen(&mut state)?;
		draw_everything_on_screen(&mut state);
		wait_until_frame_time_elapsed(&state);
	}
	Ok(())
}
