#include <stdlib.h>
#include <SDL.h>
typedef struct state {
	int w;
	int h;
	int bpp;
	SDL_Surface *screen;
	SDL_Window *sdlWindow;
	SDL_Renderer *sdlRenderer;
	SDL_Texture *sdlTexture;
} state_t;
typedef struct input {
} input_t;
void die() {
	exit(1);
}
void init_state(state_t *state) {
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) die();
}
void get_user_input(input_t *user_input) {
}
void process_one_frame(state_t *state, input_t *user_input) {
}
void draw_everything_on_screen(state_t *state) {
}
void wait_until_frame_time_elapsed() {
	SDL_Delay(10);
}
int main() {
	state_t state;
	init_state(&state);
	while (1) {
		input_t user_input;
		get_user_input(&user_input);
		process_one_frame(&state, &user_input);
		draw_everything_on_screen(&state);
		wait_until_frame_time_elapsed();
	}
	return 0;
}
