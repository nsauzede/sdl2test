// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE_v.txt file.
module main

//import vsdl2
import vsdl2gl
[inline] fn sdl_fill_rect(s &SdlSurface,r &SdlRect,c &SdlColor) {vsdl2gl.fill_rect(s,r,c)}

type atexit_func_t fn ()
fn C.atexit(atexit_func_t)

const (
        Colors = [
                SdlColor{byte(255), byte(255), byte(255), byte(0)},
                SdlColor{byte(255), byte(0), byte(0), byte(0)}
        ]
)

struct AudioContext {
mut:
//        audio_pos *byte
        audio_pos voidptr
        audio_len u32
        wav_spec SdlAudioSpec
        wav_buffer &byte
        wav_length u32
        wav2_buffer &byte
        wav2_length u32
}

fn acb(userdata voidptr, stream &byte, _len int) {
        mut ctx := &AudioContext(userdata)
//        println('acb!!! wav_buffer=${ctx.wav_buffer} audio_len=${ctx.audio_len}')
        if ctx.audio_len == u32(0) {
                C.memset(stream, 0, _len)
                return
        }
        mut len := u32(_len)
        if len > ctx.audio_len { len = ctx.audio_len }
        C.memcpy(stream, ctx.audio_pos, len)
//      ctx.audio_pos = voidptr(u64(ctx.audio_pos) + u64(len))
        ctx.audio_pos += len
        ctx.audio_len -= len
}
fn main() {
        println('hello SDL2 OpenGL V !!')
        w := 400
        h := 300
        bpp := 32
        sdl_window := *voidptr(0)
        sdl_renderer := *voidptr(0)
        C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO)
        C.atexit(C.SDL_Quit)
        C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl_window, &sdl_renderer)
//        println('renderer=$sdl_renderer')
        screen := C.SDL_CreateRGBSurface(0, w, h, bpp, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
//        sdl_texture := C.SDL_CreateTexture(sdl_renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING, w, h)
glinit := true
if glinit {
	// OpenGL
	// Loosely followed the great SDL2+OpenGL2.1 tutorial here :
	// http://lazyfoo.net/tutorials/OpenGL/01_hello_opengl/index2.php
	gl_context := C.SDL_GL_CreateContext(sdl_window)
	if isnil(gl_context) {
		println('Couldn\'t create OpenGL context !')
	} else {
		println('Created OpenGL context.')
	}
	C.SDL_GL_SetSwapInterval(1)
	C.glMatrixMode(C.GL_PROJECTION)
	C.glLoadIdentity()
	C.glMatrixMode(C.GL_MODELVIEW)
	C.glLoadIdentity()
	C.glClearColor(0., 0., 0., 1.)
}
        mut actx := AudioContext{}
        C.SDL_zero(actx)
        C.SDL_LoadWAV('sounds/door2.wav', &actx.wav_spec, &actx.wav_buffer, &actx.wav_length)
        C.SDL_LoadWAV('sounds/single.wav', &actx.wav_spec, &actx.wav2_buffer, &actx.wav2_length)
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
        ballm := balld / 2
        mut balldir := ballm
	mut nangle := 0
	mut show_3d := true
        for !quit {
                ev := SdlEvent{}
                for 0 < C.SDL_PollEvent(&ev) {
                        switch int(ev._type) {
                                case C.SDL_QUIT:
                                        quit = true
                                        break
                                case C.SDL_KEYDOWN:
                                        switch int(ev.key.keysym.sym) {
                                                case C.SDLK_ESCAPE:
                                                        quit = true
                                                        break
                                                case C.SDLK_SPACE:
                                                        actx.audio_pos = actx.wav2_buffer
                                                        actx.audio_len = actx.wav2_length
                                                        C.SDL_PauseAudio(0)
                                                case C.SDLK_3:
                                                        show_3d = !show_3d
                                        }
                        }
                }
                if quit {
                        break
                }
                ballx += balldir
                if balldir == ballm {
                        if ballx >= w - balld {
                                balldir = -ballm
                                actx.audio_pos = actx.wav_buffer
                                actx.audio_len = actx.wav_length
                                C.SDL_PauseAudio(0)
                        }
                } else {
                        if ballx <= 0 {
                                balldir = ballm
                                actx.audio_pos = actx.wav_buffer
                                actx.audio_len = actx.wav_length
                                C.SDL_PauseAudio(0)
                        }
                }

		mut rect := SdlRect{}
		mut col := SdlColor{}
		// 2D part
		rect = SdlRect {0, 0, w, h}
		col = SdlColor{byte(0), byte(0), byte(0), byte(0)}
		sdl_fill_rect(screen, &rect, &col)
if show_3d {
		// 3D part
// following line is useless if we wipe the screen in 2D above (sdl_fill_rect)
//		C.glClear(C.GL_COLOR_BUFFER_BIT)

		C.glMatrixMode(C.GL_MODELVIEW)
		C.glLoadIdentity()
		angle := f32(nangle) * 2
		C.glRotatef(angle,f32(1),f32(1),f32(1))
		C.glBegin(C.GL_QUADS)
		C.glColor3f(0., 0., 0.2)
		C.glVertex2f(-0.5, -0.5)
		C.glColor3f(1., 0., 0.2)
		C.glVertex2f(0.5, -0.5)
		C.glColor3f(1., 1., 0.2)
		C.glVertex2f(0.5, 0.5)
		C.glColor3f(0., 1., 0.2)
		C.glVertex2f(-0.5, 0.5)
		C.glEnd()
		nangle++
}

		// 2D part
		rect = SdlRect {ballx, bally, balld, balld}
		col = SdlColor{byte(255), byte(0), byte(0), byte(0)}
		sdl_fill_rect(screen, &rect, &col)

		// 3D part
		C.SDL_GL_SwapWindow(sdl_window)

		C.SDL_Delay(10)
	}
	C.SDL_CloseAudio()
	if voidptr(actx.wav_buffer) != voidptr(0) {
		C.SDL_FreeWAV(actx.wav_buffer)
	}
}
