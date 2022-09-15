#include <stdlib.h>
#include <stdio.h>

#define SDL_DISABLE_IMMINTRIN_H
#include <SDL.h>

int main(int argc, char *argv[]) {
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	printf("hello SDL %d\n", SDLV);
	int w = 200;
	int h = 400;
	int bpp = 32;
	SDL_Surface *screen = 0;
#ifdef SDL1
#else
	SDL_Window *sdlWindow = 0;
	SDL_Renderer *sdlRenderer = 0;
	SDL_Texture *sdlTexture = 0;
#endif

	if (SDL_Init(SDL_INIT_VIDEO) < 0) return 1;
#ifdef SDL1
	screen = SDL_SetVideoMode(w, h, bpp, 0);
#else
	SDL_CreateWindowAndRenderer(w, h, 0, &sdlWindow, &sdlRenderer);
	screen = SDL_CreateRGBSurface(0, w, h, bpp,0x00FF0000,0x0000FF00,0x000000FF,0xFF000000);
	sdlTexture = SDL_CreateTexture(sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, w, h);
#endif
	if (!screen) {
		printf("failed to init SDL screen\n");
		exit(1);
	}
	atexit(SDL_Quit);
	int quit = 0;
	int ballx = 0, bally = h / 2, balld = 10, balldir = 1;
	while (!quit) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				quit = 1;
				break;
			}
			if (event.type == SDL_KEYDOWN) {
				if (event.key.keysym.sym == SDLK_ESCAPE) {
					quit = 1;
					break;
				}
			}
		}
		if (quit)
			break;
		SDL_Rect rect;
               rect.x = 0;
               rect.y = 0;
               rect.w = w;
               rect.h = h;
		Uint32 col = SDL_MapRGB(screen->format, 255, 255, 255);
		SDL_FillRect(screen, &rect, col);

		rect.x = ballx;
		rect.y = bally;
		rect.w = balld;
		rect.h = balld;
		col = SDL_MapRGB(screen->format, 255, 0, 0);
		SDL_FillRect(screen, &rect, col);
		ballx += balldir;
		if (balldir == 1) {
			if (ballx >= w - balld) {
				balldir = -1;
			}
		} else {
			if (ballx <= 0) {
				balldir = 1;
			}
		}

#ifdef SDL1
		SDL_UpdateRect(screen, 0, 0, 0, 0);
#else
		SDL_UpdateTexture(sdlTexture, NULL, screen->pixels, screen->pitch);
		SDL_RenderClear(sdlRenderer);
		SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
		SDL_RenderPresent(sdlRenderer);
#endif
		SDL_Delay(10);
	}
	printf("bye\n");

	return 0;
}
