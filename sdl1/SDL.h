#ifndef LOCAL_SDL_H
#define LOCAL_SDL_H

#include_next <SDL.h>

static SDL_Window *g_local_sdlWindow = 0;
static SDL_Renderer *g_local_sdlRenderer = 0;
static SDL_Texture *g_local_sdlTexture = 0;
static inline SDL_Surface *SDL_SetVideoMode(int width, int height, int bpp, Uint32 flags) {
        SDL_CreateWindowAndRenderer(width, height, 0, &g_local_sdlWindow, &g_local_sdlRenderer);
        SDL_Surface *screen = SDL_CreateRGBSurface(0, width, height, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
        g_local_sdlTexture = SDL_CreateTexture(g_local_sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
        return screen;
}

static inline void SDL_UpdateRect(SDL_Surface *screen, Sint32 x, Sint32 y, Sint32 w, Sint32 h) {
        SDL_UpdateTexture(g_local_sdlTexture, NULL, screen->pixels, screen->pitch);
        SDL_RenderClear(g_local_sdlRenderer);
        SDL_RenderCopy(g_local_sdlRenderer, g_local_sdlTexture, NULL, NULL);
        SDL_RenderPresent(g_local_sdlRenderer);
}

#endif/*LOCAL_SDL_H*/
