#include <inttypes.h>
#include <stdio.h>

#define dbgprintf(...) do{}while(0)

/*
        This dumb C STUB is to work around the fact V transpiler fails
        when function arguments like struct are passed by value,
        and also fails to allow returning a 64 bits void pointer.
*/

// obsolete
// use this V instead :
// text string, tcol SdlColor
// tsurf := C.TTF_RenderText_Solid(g.font, text.str, tcol)
#if 0

#include <SDL_ttf.h>

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

#endif

// obsolete -- use this V myrand_r until V rand_r is available
// Ported from https://git.musl-libc.org/cgit/musl/diff/src/prng/rand_r.c?id=0b44a0315b47dd8eced9f3b7f31580cf14bbfc01
// Thanks spytheman
//fn myrand_r(seed &int) int {
//  mut rs := seed
//  ns := ( *rs * 1103515245 + 12345 )
//  *rs = ns
//  return ns & 0x7fffffff
//}
#if 0

#ifdef WIN32
int rand_r(unsigned int *seedp) {
	srand(*seedp);
	*seedp = rand();
	return *seedp;
}
#endif

#endif
