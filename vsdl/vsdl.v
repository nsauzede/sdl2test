// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v file.

module vsdl

#flag linux `sdl2-config --cflags --libs`  -lSDL2_ttf -lSDL2_mixer
#include <SDL.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>

fn C.SDL_Init(flags u32) int
fn C.SDL_CreateWindowAndRenderer(w int, h int, flags u32, window voidptr, renderer voidptr) int
fn C.SDL_CreateRGBSurface(flags u32, width int, height int, depth int, Rmask u32, Gmask u32, Bmask u32, Amask u32) *SdlSurface
fn C.SDL_CreateTexture(renderer voidptr, format u32, access int, w int, h int) voidptr
fn C.SDL_MapRGB(format voidptr, r u8, g u8, b u8) u32
fn C.SDL_PollEvent(voidptr) int
//fn C.extTTF_RenderText_Solid(font voidptr, text voidptr, col *SdlColor, ret **SdlSurface)
//fn C.toto()

//fn C.TTF_RenderText_Solid(voidptr, voidptr, SdlColor) voidptr

//fn C.TTF_Quit()
//fn C.TTF_OpenFont(a byteptr, b int) voidptr
//type SdlColor struct

struct C.TTF_Font { }

struct C.SDL_Color{
pub:
        r u8
        g u8
        b u8
        a u8
}

//fn C.TTF_RenderText_Solid(voidptr, voidptr, voidptr) voidptr
/*
struct SdlColor {
//pub:
        r u8
        g u8
        b u8
        a u8
}
//type SdlColor SdlColor
*/

type SdlScancode int    // TODO define the real enum here
type SdlKeycode i32
type SdlRect SdlRect
type SdlColor C.SDL_Color
type SdlSurface SdlSurface
type MixChunk C.Mix_Chunk

struct SdlQuitEvent {
        _type u32
        timestamp u32
}
struct SdlKeysym {
pub:
        scancode SdlScancode
        sym SdlKeycode
        mod u16
        unused u32
}
struct SdlKeyboardEvent {
pub:
        _type u32
        timestamp u32
        windowid u32
        state u8
        repeat u8
        padding2 u8
        padding3 u8
        keysym SdlKeysym
}
union SdlEventU {
pub:
        _type u32
        quit SdlQuitEvent
        key SdlKeyboardEvent
}
type SdlEvent SdlEventU
struct SdlRect {
pub:
        x int
        y int
        w int
        h int
}
struct SdlColor0 {
pub:
        r u8
        g u8
        b u8
        a u8
}
struct SdlSurface {
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

type SdlAudioFormat u16
type SdlAudioCallback_t fn(userdata voidptr, stream *u8, len int)
struct SdlAudioSpec {
pub:
mut:
        freq int
        format SdlAudioFormat
        channels u8
        silence u8
        samples u16
        size u32
        callback SdlAudioCallback_t
        userdata voidptr
}
type SdlAudioSpec SdlAudioSpec
