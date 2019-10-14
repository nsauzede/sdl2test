// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

// The vnl module use the nice Nuklear library (see README.md)
module vnk

#flag linux -Ivnk
#flag linux -DNK_INCLUDE_FIXED_TYPES
#flag linux -DNK_INCLUDE_STANDARD_IO
#flag linux -DNK_INCLUDE_STANDARD_VARARGS
#flag linux -DNK_INCLUDE_DEFAULT_ALLOCATOR
#flag linux -DNK_INCLUDE_VERTEX_BUFFER_OUTPUT
#flag linux -DNK_INCLUDE_FONT_BAKING
#flag linux -DNK_INCLUDE_DEFAULT_FONT
#flag linux -DNK_IMPLEMENTATION
#flag linux -DNK_SDL_GL3_IMPLEMENTATION
#include <GL/glew.h>
#include "nuklear.h"
#include "nuklear_sdl_gl3.h"

#flag linux -lGL -lGLEW

struct NkColorF0 {
pub:
mut:
	r f32
	g f32
	b f32
	a f32
}
type NkColorF NkColorF0

struct NkFontAtlas0 {
	foo int
}
type NkFontAtlas NkFontAtlas0
