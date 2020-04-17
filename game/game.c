#include <stdlib.h>
#include <stdio.h>

#include <SDL.h>

#define dbgprintf(...) do{}while(0)

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
	int quit;
} input_t;

void die() {
	exit(1);
}

void init_state(state_t *state) {
	memset(state, 0, sizeof(state_t));
	state->w = 100;
	state->h = 200;
	state->bpp = 32;
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		die();
	}
	SDL_CreateWindowAndRenderer(state->w, state->h, 0, &state->sdlWindow, &state->sdlRenderer);
	state->screen = SDL_CreateRGBSurface(0, state->w, state->h, state->bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
	state->sdlTexture = SDL_CreateTexture(state->sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, state->w, state->h);
}

void get_user_input(input_t *user_input) {
	memset(user_input, 0, sizeof(input_t));
	SDL_Event ev;
	dbgprintf("SDL POLLING\n");
	while (SDL_PollEvent(&ev)) {
		if (ev.type == SDL_QUIT) {
			dbgprintf("SDL QUIT\n");
			user_input->quit = 1;
		}
	}
	dbgprintf("SDL POLLING DONE\n");
}

void process_one_frame(state_t *state, input_t *user_input) {
	dbgprintf("PROCESS\n");
	if (user_input->quit) {
		dbgprintf("QUITTING !!\n");
		exit(0);
	}
	dbgprintf("PROCESS DONE\n");
}

void draw_everything_on_screen(state_t *state) {
	dbgprintf("DRAW\n");
}

void wait_until_frame_time_elapsed() {
	dbgprintf("SDL DELAY\n");
	SDL_Delay(10);
	dbgprintf("SDL DELAY DONE\n");
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
