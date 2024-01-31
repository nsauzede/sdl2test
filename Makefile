_SYS:=$(shell uname -o)
ifeq ($(_SYS),Msys)
WIN32:=1
endif

TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=mainmix_c.exe
TARGET+=maingl_c.exe
#TARGET+=main_v.exe
TARGET+=nsauzede/vsdl2/examples/main_v.exe
#TARGET+=tetris_v.exe
#TARGET+=tetrisnomix_v.exe
#TARGET+=tvintris.exe
#TARGET+=tvintris0_v.exe
#TARGET+=tvintrisgl_v.exe
#TARGET+=maingl_v.exe
TARGET+=glfnt.exe
ifndef WIN32
TARGET+=mainnk_v.exe
TARGET+=mainig_v.exe
endif

#CFLAGS:=
CFLAGS+=-Wall
#CFLAGS+=-Werror
CFLAGS+=-Wextra
#CFLAGS+=-pedantic
CFLAGS+=-Wno-unused-variable
CFLAGS+=-Wno-unused-parameter
CFLAGS+=-Wno-unused-result

CXXFLAGS:=
CXXFLAGS+=-Wall
CXXFLAGS+=-Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g
CFLAGS+=-g

ifdef NOPT
CXXFLAGS+=-O0
CFLAGS+=-O0
endif

CXXFLAGS+=-I.

V:=./v/v
#VFLAGS:=-debug -show_c_cmd
VCFLAGS:=-std=gnu11 -w -g -O0

ifdef WIN32
GLLDLIBS:=-lopengl32 -lglu32
else
GLLDLIBS:=-lGL -lGLU
endif

GLADFLAGS:=-I ../v/thirdparty/ -I ../stb
GLADLIBS:=../v/thirdparty/glad/glad.o -l dl -lglfw

LDLIBS+=-L. -lgc
AR:=ar

all: SDL_CHECK SUBM_CHECK VMOD_CHECK $(TARGET)

#VMOD_CHECK: V_CHECK VSDL2_CHECK VIG_CHECK VNK_CHECK
VMOD_CHECK: V_CHECK NSAUZEDE_CHECK VSDL2_CHECK VNK_CHECK

nsauzede/vig/README.md:
	git submodule deinit --force --all
	git submodule update --init --recursive

SUBM_CHECK: nsauzede/vig/README.md

GC_CHECK: libgc.a

ifdef WIN32
GLLIBS:=-lGLEW32 -lopengl32 -lfreetype -lglfw3 -pthread
else
GLLIBS:=-lGLEW -lGL -lfreetype -lglfw  -ldl -lX11 -pthread
endif
glfnt.exe: glfnt.cpp
	g++ $^ $(CXXFLAGS) -o $@ `pkg-config freetype2 --cflags` -I v/thirdparty/ $(GLLIBS)

%gl_c.exe: LDLIBS+=$(GLLDLIBS)
%glsl_c.exe: LDLIBS+=$(GLLDLIBS)
%gl_v.exe: LDLIBS+=$(GLLDLIBS)
%glad.exe: CXXFLAGS+=$(GLADFLAGS)
%glad.exe: LDLIBS+=$(GLADLIBS)

libgc.o: v/thirdparty/libgc/gc.c
	$(CC) -c $< -o $@
libgc.a: libgc.o
	$(AR) cr $@ $^

include sdl.mak
ifeq ($(SDL_VER),1)
SDL_FLAGS+=-DSDL1
else
SDL_FLAGS+=-DSDL2
endif

#CFLAGS+=$(SDL_FLAGS)
#CXXFLAGS+=$(SDL_FLAGS)
%_cpp.exe: CXXFLAGS+=$(SDL_FLAGS)
%_c.exe: CFLAGS+=$(SDL_FLAGS)
%_v.exe: CFLAGS+=$(SDL_FLAGS)
tvintris.exe: CFLAGS+=$(SDL_FLAGS)

ifeq ($(SDL_VER),1)
LDLIBS+=$(SDL_LIBS) -lSDL_ttf -lSDL_mixer
else
LDLIBS+=$(SDL_LIBS) -lSDL2_ttf -lSDL2_mixer -lSDL2_image
endif

CFLAGS+=-pthread
CXXFLAGS+=-pthread
LDFLAGS+=-pthread

V_CHECK: $(V) GC_CHECK

$(V):
	git clone https://github.com/nsauzede/v
	(cd $(@D) ; $(MAKE) ; cd -)

%ig_v.exe: CFLAGS+=-Insauzede/vig -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=1 -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 -DIMGUI_IMPL_API= $(SDL_FLAGS)
%ig_v.exe: LDFLAGS=
%ig_v.exe: LDLIBS+=nsauzede/vig/imgui_impl_sdl.o nsauzede/vig/imgui_impl_opengl3.o nsauzede/vig/cimgui/bld/CMakeFiles/cimgui.dir/cimgui.cpp.o nsauzede/vig/cimgui/bld/CMakeFiles/cimgui.dir/imgui/*.cpp.o $(SDL_LIBS) -lGL -lGLEW -lm -ldl

mainig.tmp.c: nsauzede/vig/examples/mainig/mainig.v | VIG_CHECK
	$(V) -o $@ $(VFLAGS) $^
mainig_v.exe: mainig.tmp.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

NSAUZEDE_CHECK:
	mkdir -p $(HOME)/.vmodules
	\rm -Rf $(HOME)/.vmodules/nsauzede
	ln -sf $(PWD)/nsauzede $(HOME)/.vmodules

$(HOME)/.vmodules/nsauzede/vig/v.mod:
	$(V) install nsauzede.vig

#.PHONY: _VIG_CHECK VIG_CHECK
_VIG_CHECK:
	touch nsauzede/vig/v.mod

VIG_CHECK: _VIG_CHECK $(HOME)/.vmodules/nsauzede/vig/v.mod
	$(MAKE) -C nsauzede/vig

%ig_v.exe: %ig_v.o | VIG_CHECK
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

ifdef WIN32
NKLDLIBS:=-lopengl32 -lglew32
else
NKLDLIBS:=-lGL -lGLEW
endif

%nk_v.exe: CFLAGS+=-Insauzede/vnk -DNK_INCLUDE_FIXED_TYPES -DNK_INCLUDE_STANDARD_IO -DNK_INCLUDE_STANDARD_VARARGS -DNK_INCLUDE_DEFAULT_ALLOCATOR -DNK_INCLUDE_VERTEX_BUFFER_OUTPUT -DNK_INCLUDE_FONT_BAKING -DNK_INCLUDE_DEFAULT_FONT -DNK_IMPLEMENTATION -DNK_SDL_GL3_IMPLEMENTATION $(SDL_FLAGS)
%nk_v.exe: LDFLAGS=
%nk_v.exe: LDLIBS+=$(SDL_LIBS) $(NKLDLIBS) -lm

$(HOME)/.vmodules/nsauzede/vsdl2/v.mod:
	$(V) install nsauzede.vsdl2

#.PHONY: _VSDL2_CHECK VSDL2_CHECK
_VSDL2_CHECK:
	touch nsauzede/vsdl2/v.mod

VSDL2_CHECK: _VSDL2_CHECK $(HOME)/.vmodules/nsauzede/vsdl2/v.mod

$(HOME)/.vmodules/nsauzede/vnk/v.mod:
	$(V) install nsauzede.vnk

#.PHONY: _VNK_CHECK VNK_CHECK
_VNK_CHECK:
	touch nsauzede/vnk/v.mod

VNK_CHECK: _VNK_CHECK $(HOME)/.vmodules/nsauzede/vnk/v.mod
	$(MAKE) -C nsauzede/vnk

mainnk_v.c: nsauzede/vnk/examples/mainnk_v/mainnk_v.v
	$(V) -o $@ $(VFLAGS) $^

%nk_v.exe: %nk_v.o | VNK_CHECK
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

%.exe: %.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

vsdlstub.o: vsdl/vsdlstub.c
	$(CC) -c -o $@ $(CFLAGS) -g $^

ifdef WIN32
CFLAGS+=-Wno-incompatible-pointer-types
endif

tvintris.tmp.c: nsauzede/vsdl2/examples/tvintris/tvintris.v
	$(V) -o $@ $(VFLAGS) $^
tvintris.exe: tvintris.tmp.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

%_v.exe: CFLAGS+=$(VCFLAGS)
#%_v.exe: LDLIBS+=vsdlstub.o
#%.c: %.v | vsdlstub.o
%.c: %.v
#	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt *.tmp.c .tmp.*.c *.so *_v

mrproper: clobber
	$(RM) -Rf v
	$(MAKE) -C nsauzede/vig clobber
	$(MAKE) -C nsauzede/vnk clobber
