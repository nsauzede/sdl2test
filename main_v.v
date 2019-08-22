// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v file.

module main

import vsdl

type atexit_func_t fn ()
fn C.atexit(atexit_func_t)

fn main() {
//        println('hello SDL2/v\n')     // TODO doesn't compile ?
        w := 100
        h := 100
        bpp := 32
        sdl_window := voidptr(0)
        sdl_renderer := voidptr(0)
//        println('window='+u64(sdl_window).str())  // ditto
        C.SDL_Init(SDL_INIT_VIDEO)
        C.atexit(C.SDL_Quit)
        C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl_window, &sdl_renderer)
        screen := C.SDL_CreateRGBSurface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
        sdl_texture := C.SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, w, h)
//        println('window='+u64(sdl_window).str())
//        println('renderer='+u64(sdl_renderer).str())
        println('screen=$screen')
        println('texture=$sdl_texture')
        mut quit := false
        for !quit {
                ev := SdlEvent{}
                for !!C.SDL_PollEvent(&ev) {
                        if int(ev._type) == SDL_QUIT {          // TODO no integral promotion ????
                                quit = true
                                break
                        }
                        if int(ev._type) == SDL_KEYDOWN {
                                if int(ev.key.keysym.sym) == SDLK_ESCAPE {      // ditto
                                        quit = true
                                        break
                                }
                        }
                }

                if quit {
                        break
                }
/* // TODO doesn't compile ???
                rect := SdlRect {
                        x: 0
                        y: 0
                        w: w
                        h: h
                }
*/
                rect := SdlRect {0,0,w,h}
                col := C.SDL_MapRGB(screen.format, 128, 0, 0)
                C.SDL_FillRect(screen, &rect, col)
                C.SDL_UpdateTexture(sdl_texture, NULL, screen.pixels, screen.pitch)
                C.SDL_RenderClear(sdl_renderer)
                C.SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL)
                C.SDL_RenderPresent(sdl_renderer)
                C.SDL_Delay(500)
        }
}
