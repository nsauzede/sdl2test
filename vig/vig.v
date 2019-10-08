module vig

#flag linux -Ivig -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=1 -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 -DIMGUI_IMPL_API=
#include "cimgui.h"
#include "imgui_impl_opengl3.h"
#include "imgui_impl_sdl.h"
#include <GL/glew.h>    // Initialize with glewInit()

//fn C.igColorEdit3(label charptr,col mut f32[3],flags int) bool
//fn C.igShowDemoWindow(p_open *bool)
//fn C.igCheckbox(label voidptr, p_open *bool)

struct C.ImVec2 {
pub:
mut:
        x f32
        y f32
}
//type ImVec2 C.ImVec2
type ImVecTwo C.ImVec2

struct C.ImVec4 {
pub:
mut:
        x f32
        y f32
        z f32
        w f32
}
//type ImVec4 C.ImVec4
type ImVecFour C.ImVec4
