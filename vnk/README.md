# vig
V Nuklear module -- nuklear wrapper

If you are new to nuklear see [here](https://github.com/vurtun/nuklear)

Current APIs available/tested in examples :
- create SDL2 / OpenGL window
- set clear color
- create nuklear subwindows
- create widgets : buttons, slider, text inputs, color picker, etc...
- persistent layout
- debug tools : FPS, stats, etc..

# Examples

See in examples/mainnk_v/mainnk_v.v
This is a V port of Nuklear sdl_opengl3 demo

# Dependencies
Ubuntu :
`$ sudo apt install git cmake libsdl2-dev libglew-dev`

ClearLinux :
`$ sudo swupd bundle-add git cmake devpkg-SDL2 devpkg-glew`

Windows/MSYS2 :
`$ pacman -S msys/git mingw64/mingw-w64-x86_64-cmake mingw64/mingw-w64-x86_64-SDL2 mingw64/mingw-w64-x86_64-glew`
