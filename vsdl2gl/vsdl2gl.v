// Copyright(C) 2019 Nicolas Sauzede. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.

module vsdl2gl

import nsauzede.vsdl2

// apparently, following line also works on non-linux ? o_O
#flag linux -lGL -lGLU
#include <SDL_opengl.h>
#include <GL/glu.h>

pub fn fill_rect(screen &vsdl2.Surface, rect &vsdl2.Rect, col &vsdl2.Color) {
        ww := screen.w
        hh := screen.h
        r := f32(col.r) / 255
        g := f32(col.g) / 255
        b := f32(col.b) / 255
        x := f32(2) * rect.x / (ww - 1) - 1
        y := f32(2) * ((hh - 1) - rect.y) / (hh - 1) - 1
        w := f32(2) * rect.w / ww
        h := f32(2) * rect.h / hh
        C.glMatrixMode(C.GL_MODELVIEW)
        C.glLoadIdentity()
        C.glBegin(C.GL_QUADS)
        C.glColor3f(r, g, b)
        C.glVertex2f(x, y)
        C.glVertex2f(x + w, y)
        C.glVertex2f(x + w, y - h)
        C.glVertex2f(x, y - h)
        C.glEnd()
}
