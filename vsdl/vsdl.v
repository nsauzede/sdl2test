// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v.txt file.

module vsdl

#flag linux `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer
#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>

//fn C.SDL_Init(flags u32) int
//fn C.SDL_CreateWindowAndRenderer(w int, h int, flags u32, window voidptr, renderer voidptr) int
fn C.SDL_CreateRGBSurface(flags u32, width int, height int, depth int, Rmask u32, Gmask u32, Bmask u32, Amask u32) &SdlSurface
//fn C.SDL_CreateTexture(renderer voidptr, format u32, access int, w int, h int) voidptr
//fn C.SDL_MapRGB(format voidptr, r byte, g byte, b byte) u32
//fn C.SDL_PollEvent(voidptr) int
//fn C.stubTTF_RenderText_Solid(font voidptr, text voidptr, col *SdlColor, ret **SdlSurface)

//fn C.stubTTF_RenderText_Solid(font voidptr, text voidptr, col &SdlColor, ret &voidptr)

//fn C.TTF_Quit()
//fn C.TTF_OpenFont(a byteptr, b int) voidptr
//type SdlColor struct

//struct C.TTF_Font { }

struct C.SDL_Color{
pub:
        r byte
        g byte
        b byte
        a byte
}
type SdlColor C.SDL_Color

struct C.SDL_Rect {
pub:
        x int
        y int
        w int
        h int
}
type SdlRect C.SDL_Rect

//type SdlScancode int    // TODO define the real enum here
//type SdlKeycode int
//type SdlRect SdlRect
//type SdlColor C.SDL_Color
//type SdlSurface SdlSurface
//type MixChunk C.Mix_Chunk

struct SdlQuitEvent {
        _type u32
        timestamp u32
}
struct SdlKeysym {
pub:
//        scancode SdlScancode
        scancode	int
//        sym		SdlKeycode
        sym		int
        mod		u16
        unused		u32
}
struct SdlKeyboardEvent {
pub:
        _type u32
        timestamp u32
        windowid u32
        state byte
        repeat byte
        padding2 byte
        padding3 byte
        keysym SdlKeysym
}
struct SdlJoyButtonEvent {
pub:
        _type u32
        timestamp u32
        which int
        button byte
        state byte
}
struct SdlJoyHatEvent {
pub:
        _type u32
        timestamp u32
        which int
        hat byte
        value byte
}
union SdlEventU {
pub:
        _type u32
        quit SdlQuitEvent
        key SdlKeyboardEvent
        jbutton SdlJoyButtonEvent
        jhat SdlJoyHatEvent
}
type SdlEvent SdlEventU

struct C.SDL_Surface {
pub:
        flags u32
        format voidptr
        w int
        h int
        pitch int
        pixels voidptr
        userdata voidptr
        locked int
        lock_data voidptr
        clip_rect SdlRect
        map voidptr
        refcount int
}
type SdlSurface C.SDL_Surface

//type SdlAudioFormat u16
//type SdlAudioCallback_t fn(userdata voidptr, stream &byte, len int)
//struct SdlAudioSpec {
struct C.SDL_AudioSpec {
pub:
mut:
        freq int
//        format SdlAudioFormat
        format u16
        channels byte
        silence byte
        samples u16
        size u32
//        callback SdlAudioCallback_t
        callback voidptr
        userdata voidptr
}
type SdlAudioSpec C.SDL_AudioSpec


const (
	version = '0.0.1'
)
