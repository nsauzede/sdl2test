# sdl2test
Small examples of SDL1 vs. SDL2 usage, in V, C and C++ languages.

<img src='https://github.com/nsauzede/sdl2test/raw/master/tetris_v.png'>

# Dependencies
Ubuntu :
`$ sudo apt install libsdl2-ttf-dev libsdl2-mixer-dev`

ClearLinux :
`$ sudo swupd bundle-add devpkg-SDL2_ttf devpkg-SDL2_mixer`

Windows/MSYS2 :
`$ pacman -S mingw-w64-x86_64-SDL2_ttf mingw-w64-x86_64-SDL2_mixer`


# Misc
Makefile auto-detects available SDL version (2 or 1)

- tetris_v.v is inspired from original source from Alex V example
- ported to SDL and enhanced with music sounds
- vsdl : naive V wrapper for SDL2 binding
- CSDL : small C++ class to abstract SDL1/2

# Credits
Music and sounds ripped from amiga title Twintris (1990 nostalgia !)
- Graphician : Svein Berge
- Musician : Tor Bernhard Gausen (Walkman/Cryptoburners)
