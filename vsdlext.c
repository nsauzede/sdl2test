#include <inttypes.h>
#include <stdio.h>

#include <SDL_ttf.h>

DECLSPEC void SDLCALL extTTF_RenderText_Solid(TTF_Font *font,
                const char *text, SDL_Color *fg, SDL_Surface **ret) {
//        printf("%s: got color=%"PRIu8",%"PRIu8",%"PRIu8",%"PRIu8"\n", __func__, fg->r, fg->g, fg->b, fg->a);
        SDL_Surface *res = TTF_RenderText_Solid(font, text, *fg);
//        printf("%s: returning res=%p\n", __func__, res);
        *ret = res;
}
