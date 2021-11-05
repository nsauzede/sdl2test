# sdl2test
Small examples of libSDL2 usage in V, C and C++ languages.
Historically, the purpose was to evaluate the changes from SDL1 to SDL2.

Note that the V modules wrapping : SDL2, Imgui and Nuklear have been moved to their separate git repo, and are still used/demonstrated here as git sub-modules.

You can find their own repos here:
- [vsdl2 SDL2 V wrapper](https://github.com/nsauzede/vsdl2)
- [vig ImGui V wrapper](https://github.com/nsauzede/vig)
- [vnk Nuklear V wrapper](https://github.com/nsauzede/vnk)

----
- cratesan is a Sokoban clone, in Rust and V

<img src='https://github.com/nsauzede/sdl2test/blob/master/cratesan/res/images/cratesan.png'>

- tvintris_v.v is a dual-player (local) version, inspired by ancient game Twintris. It uses published vpm module nsauzede.vsdl2

<img src='https://github.com/nsauzede/sdl2test/blob/master/tvintris.png'>

- tvintrisgl_v.v is a dual-player (local) version with OpenGL, inspired by ancient game Twintris. It uses published vpm module nsauzede.vsdl2
This OpenGL version still lacks TTF font for now, however

<img src='https://github.com/nsauzede/sdl2test/blob/master/tvintrisgl.gif'>

<img src='https://github.com/nsauzede/sdl2test/blob/master/tvintrisgl.png'>

# Credits
- tetris_v.v is just and SDL2 port of original source from <a href='https://github.com/vlang/v'>vlang/v</a> example by Alex
I wrote a simple SDL2 V wrapper, ported GLFW usage to SDL2, tweaked colors and added music & sounds

<img src='https://github.com/nsauzede/sdl2test/raw/master/tetris_v.png'>

Colors, Music and Sounds ripped from amiga title <a href='http://hol.abime.net/5109/screenshot'>Twintris</a> (1990 nostalgia !)
- Graphician : Svein Berge
- Musician : Tor Bernhard Gausen (Walkman/Cryptoburners)

# Dependencies
Ubuntu :
`$ sudo apt install libsdl2-ttf-dev libsdl2-mixer-dev libssl-dev`
And optionally for extra tests :
`$ sudo apt install libglfw3-dev libglm-dev libfreetype-dev`

ClearLinux : (maybe miss libopenssl dev ?)
`$ sudo swupd bundle-add devpkg-SDL2_ttf devpkg-SDL2_mixer`

Windows/MSYS2 : (maybe miss libopenssl dev ?)
`$ pacman -S mingw-w64-x86_64-SDL2_ttf mingw-w64-x86_64-SDL2_mixer`


# Misc
Makefile auto-detects available SDL version (2 or 1)

- vsdl : naive V wrapper for SDL2 binding
- CSDL : small C++ class to abstract SDL1/2
- various C and V examples to
