#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>

#include <SDL.h>

#define dbgprintf(...) do{}while(0)

typedef struct state {
	int quit;
	int w;
	int h;
	int bpp;
	int scale;
	int score;
	int fps;
	uint64_t tick;
	uint64_t last_tick;
	struct timespec last_ts;

	SDL_Surface *screen;
	SDL_Window *sdlWindow;
	SDL_Renderer *sdlRenderer;
	SDL_Texture *sdlTexture;
	Uint32 white;
	Uint32 black;
} state_t;

typedef struct input {
	int quit;
} input_t;

void die() {
	exit(1);
}

void init_state(state_t *s) {
	memset(s, 0, sizeof(state_t));
	s->scale = 4;
	s->w = 200;
	s->h = 400;
	s->bpp = 32;
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		die();
	}
	SDL_CreateWindowAndRenderer(s->w, s->h, 0, &s->sdlWindow, &s->sdlRenderer);
	s->screen = SDL_CreateRGBSurface(0, s->w, s->h, s->bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
	s->sdlTexture = SDL_CreateTexture(s->sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, s->w, s->h);
	s->white = SDL_MapRGB(s->screen->format, 255, 255, 255);
	s->black = SDL_MapRGB(s->screen->format, 0, 0, 0);
	s->score = 42;
	clock_gettime(CLOCK_REALTIME, &s->last_ts);
}

void draw_clear(state_t *s, Uint32 col) {
	SDL_Rect rect;
	rect.x = 0;
	rect.y = 0;
	rect.w = s->w;
	rect.h = s->h;
	SDL_FillRect(s->screen, &rect, col);
}

void draw_score(state_t *s, Uint32 col, int score) {
	SDL_Rect rect;
	rect.x = 0;
	rect.y = 0;
	rect.w = s->scale;
	rect.h = s->scale;
	char sscore[1024];
	int ndigits = sprintf(sscore, "%d", score);
	// 4x5 font
	const int fw = 4;
	const int fh = 5;
	int stride = (fw + 7) / 8 * fh;	// bytes per font element
	char font[] = {
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
	};
	for (int n = 0; n < ndigits; n++) {
		int digit = sscore[n] - '0';
		for (int j = 0; j < fh; j++) {
			rect.y = s->scale * j;
			for (int i = 0; i < fw; i++) {
				rect.x = s->scale * (n * fw + i);
				if (font[digit * stride + j] & (1 << (fw - i - 1))) {
					SDL_FillRect(s->screen, &rect, col);
				}
			}
		}
	}
}

void draw_update(state_t *s) {
	SDL_UpdateTexture(s->sdlTexture, 0, s->screen->pixels, s->screen->pitch);
	SDL_RenderClear(s->sdlRenderer);
	SDL_RenderCopy(s->sdlRenderer, s->sdlTexture, 0, 0);
	SDL_RenderPresent(s->sdlRenderer);
}

void get_user_input(input_t *ui) {
	memset(ui, 0, sizeof(input_t));
	SDL_Event ev;
	dbgprintf("SDL POLLING\n");
	while (SDL_PollEvent(&ev)) {
		if (ev.type == SDL_QUIT) {
			dbgprintf("SDL QUIT\n");
			ui->quit = 1;
			break;
		}
		if (ev.type == SDL_KEYDOWN) {
			if (ev.key.keysym.sym == SDLK_ESCAPE) {
				ui->quit = 1;
				break;
			}
		}
	}
	dbgprintf("SDL POLLING DONE\n");
}

void process_one_frame(state_t *s, input_t *user_input) {
	dbgprintf("PROCESS\n");
	if (user_input->quit) {
		dbgprintf("QUITTING !!\n");
		s->quit = 1;
		return;
	}
	dbgprintf("PROCESS DONE\n");
//	s->score = s->tick;
	struct timespec ts;
	clock_gettime(CLOCK_REALTIME, &ts);
	if (ts.tv_sec > s->last_ts.tv_sec) {
		s->fps = (s->tick - s->last_tick) / (ts.tv_sec - s->last_ts.tv_sec);
		s->last_tick = s->tick;
		s->last_ts = ts;
	}
	s->score = s->fps;
	s->tick++;
}

void draw_everything_on_screen(state_t *s) {
	dbgprintf("DRAW\n");
	draw_clear(s, s->black);
	draw_score(s, s->white, s->score);
	draw_update(s);
}

void wait_until_frame_time_elapsed() {
	dbgprintf("SDL DELAY\n");
	SDL_Delay(16);
	dbgprintf("SDL DELAY DONE\n");
}

int main() {
	state_t state;
	init_state(&state);
	while (!state.quit) {
		input_t user_input;
		get_user_input(&user_input);
		process_one_frame(&state, &user_input);
		draw_everything_on_screen(&state);
		wait_until_frame_time_elapsed();
	}
	return 0;
}
