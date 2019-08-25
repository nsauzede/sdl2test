#include <inttypes.h>
#include <stdio.h>

#include <SDL_ttf.h>

/*
        This dumb C STUB is to work around the fact V transpiler fails
        when function arguments like struct are passed by value,
        and also fails to allow returning a 64 bits void pointer.
*/

#define dbgprintf(...) do{}while(0)

DECLSPEC void SDLCALL stubTTF_RenderText_Solid(TTF_Font *font,
                const char *text, SDL_Color *fg, SDL_Surface **ret) {
/*
        SDL_Color _fg = {0, 0, 0, 0};
        fg = &_fg;
*/
        dbgprintf("%s: got font=%p text=%p (%s) fg=%p ret=%p (%p)\n", __func__, font, text, text, fg, ret, *ret);
        dbgprintf("%s: got color=%"PRIu8",%"PRIu8",%"PRIu8",%"PRIu8"\n", __func__, fg->r, fg->g, fg->b, fg->a);
        SDL_Surface *res = TTF_RenderText_Solid(font, text, *fg);
        dbgprintf("%s: returning res=%p\n", __func__, res);
        *ret = res;
}
