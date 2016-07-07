#include <stdlib.h>
#include <stdio.h>

#include <SDL.h>

int main() {
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	printf( "hello SDL %d\n", SDLV);
	int w = 100;
	int h = 100;
	int bpp = 32;
	SDL_Surface *screen = 0;
#ifdef SDL1
#else
	SDL_Window *sdlWindow = 0;
	SDL_Renderer *sdlRenderer = 0;
	SDL_Texture *sdlTexture = 0;
#endif

	SDL_Init( SDL_INIT_VIDEO);
#ifdef SDL1
	screen = SDL_SetVideoMode( w, h, bpp, 0);
#else
	SDL_CreateWindowAndRenderer( w, h, 0, &sdlWindow, &sdlRenderer);
	screen = SDL_CreateRGBSurface(0, w, h, bpp,
                                        0x00FF0000,
                                        0x0000FF00,
                                        0x000000FF,
                                        0xFF000000);
	sdlTexture = SDL_CreateTexture(sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, w, h);
#endif
	if (!screen) {
		printf( "failed to init SDL\n");
		exit( 1);
	}
	atexit( SDL_Quit);
	int quit = 0;
	while (!quit) {
		SDL_Event event;
		while (SDL_PollEvent( &event)) {
			if (event.type == SDL_QUIT) {
				quit = 1;
				break;
			}
		}
		if (quit)
			break;
		SDL_Rect rect;
		rect.x = 0;
		rect.y = 0;
		rect.w = w;
		rect.h = h;
		Uint32 col = SDL_MapRGB( screen->format, 128, 0, 0);
		SDL_FillRect( screen, &rect, col);
#ifdef SDL1
		SDL_UpdateRect( screen, 0, 0, 0, 0);
#else
		SDL_UpdateTexture( sdlTexture, NULL, screen->pixels, screen->pitch);
		SDL_RenderClear( sdlRenderer);
		SDL_RenderCopy( sdlRenderer, sdlTexture, NULL, NULL);
		SDL_RenderPresent( sdlRenderer);
#endif
		SDL_Delay( 500);
	}
	printf( "bye\n");

	return 0;
}
