// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v file.
module main
import vsdl
type atexit_func_t fn ()
fn C.atexit(atexit_func_t)

//fn C.TTF_Quit()
//fn C.TTF_RenderText_Solid(voidptr, voidptr, SdlColor) voidptr

const (
        Colors = [
                SdlColor{u8(255), u8(255), u8(255), u8(0)},
                SdlColor{u8(255), u8(0), u8(0), u8(0)}
        ]
)
struct AudioContext {
mut:
//        audio_pos *u8
        audio_pos voidptr
        audio_len u32
        wav_spec SdlAudioSpec
        wav_buffer *u8
        wav_length u32
}

fn acb(userdata voidptr, stream *u8, _len int) {
        mut ctx := &AudioContext(userdata)
        println('acb!!! wav_buffer=${ctx.wav_buffer} audio_len=${ctx.audio_len}')
        if ctx.audio_len == u32(0) { return }
        mut len := u32(_len)
        if len > ctx.audio_len { len = ctx.audio_len }
        C.memcpy(stream, ctx.audio_pos, len)
//      ctx.audio_pos = voidptr(u64(ctx.audio_pos) + u64(len))
        ctx.audio_pos += len
        ctx.audio_len -= len
}

fn main() {
        println('hello SDL 2 [v]\n')
        w := 200
        h := 400
        bpp := 32
        sdl_window := *voidptr(0)
        sdl_renderer := *voidptr(0)
        C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO)
        C.atexit(C.SDL_Quit)
        C.TTF_Init()
        C.atexit(C.TTF_Quit)
        font := C.TTF_OpenFont('RobotoMono-Regular.ttf', 16)
//        println('font=$font')
        C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl_window, &sdl_renderer)
//        println('renderer=$sdl_renderer')
        screen := C.SDL_CreateRGBSurface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
        sdl_texture := C.SDL_CreateTexture(sdl_renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING, w, h)
        mut actx := AudioContext{}
        C.SDL_zero(actx)
        C.SDL_LoadWAV('sounds/door2.wav', &actx.wav_spec, &actx.wav_buffer, &actx.wav_length)
        println('got wav_buffer=${actx.wav_buffer}')
        actx.wav_spec.callback = acb
        actx.wav_spec.userdata = &actx
        if C.SDL_OpenAudio(&actx.wav_spec, 0) < 0 {
                println('couldn\'t open audio')
                return
        }
        mut quit := false
        mut ballx := 0
        bally := h / 2
        balld := 10
        mut balldir := 1
        for !quit {
                ev := SdlEvent{}
                for !!C.SDL_PollEvent(&ev) {
                        if int(ev._type) == C.SDL_QUIT {          // TODO no integral promotion ????
                                quit = true
                                break
                        }
                        if int(ev._type) == C.SDL_KEYDOWN {
                                if int(ev.key.keysym.sym) == C.SDLK_ESCAPE {      // ditto
                                        quit = true
                                        break
                                }
                        }
                }
                if quit {
                        break
                }
//                rect := SdlRect {x: 0, y: 0, w: w, h: h }     // TODO doesn't compile ???
                mut rect := SdlRect {0,0,w,h}
                mut col := C.SDL_MapRGB(screen.format, 255, 255, 255)
                C.SDL_FillRect(screen, &rect, col)

                rect = SdlRect {ballx, bally, balld, balld}
//                col = C.SDL_MapRGB(screen.format, 255, 0, 0)
                col = C.SDL_MapRGB(screen.format, Colors[1].r, Colors[1].g, Colors[1].b)
                C.SDL_FillRect(screen, &rect, col)
                ballx += balldir
                if balldir == 1 {
                        if ballx >= w - balld {
                                balldir = -1
                                actx.audio_pos = actx.wav_buffer
                                actx.audio_len = actx.wav_length
                                C.SDL_PauseAudio(0)
                        }
                } else {
                        if ballx <= 0 {
                                balldir = 1
                                actx.audio_pos = actx.wav_buffer
                                actx.audio_len = actx.wav_length
                                C.SDL_PauseAudio(0)
                        }
                }

                C.SDL_UpdateTexture(sdl_texture, 0, screen.pixels, screen.pitch)
                C.SDL_RenderClear(sdl_renderer)
                C.SDL_RenderCopy(sdl_renderer, sdl_texture, 0, 0)

//                tcol := C.SDL_Color {u32(0), u32(0), u32(0)}    // TODO doesn't compile ?
//                tcol := [u8(0), u8(0), u8(0), u8(0)]
                tcol := SdlColor {u8(3), u8(2), u8(1), u8(0)}
//                tsurf := C.TTF_RenderText_Solid(font,'Hello SDL_ttf', tcol)
                tsurf := *voidptr(0xdeadbeef)
//                println('tsurf=$tsurf')
                C.stubTTF_RenderText_Solid(font,'Hello SDL_ttf V !', &tcol, &tsurf)
//                println('tsurf=$tsurf')
//                tsurf := C.TTF_RenderText_Solid(font,'Hello SDL_ttf', 0)
//                println('tsurf=$tsurf')
//                println('tsurf=' + $tsurf')
                ttext := C.SDL_CreateTextureFromSurface(sdl_renderer, tsurf)
//                println('ttext=$ttext')
                texw := 0
                texh := 0
                C.SDL_QueryTexture(ttext, 0, 0, &texw, &texh)
                dstrect := SdlRect { 0, 0, texw, texh }
                C.SDL_RenderCopy(sdl_renderer, ttext, 0, &dstrect)
                C.SDL_DestroyTexture(ttext)
                C.SDL_FreeSurface(tsurf)

                C.SDL_RenderPresent(sdl_renderer)
                C.SDL_Delay(10)
        }
        if isnil(font) {
                C.TTF_CloseFont(font)
        }
        C.SDL_CloseAudio()
        if voidptr(actx.wav_buffer) != voidptr(0) {
                C.SDL_FreeWAV(actx.wav_buffer)
        }
}
