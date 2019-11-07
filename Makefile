_SYS:=$(shell uname -o)
ifeq ($(_SYS),Msys)
WIN32:=1
endif

TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=mainmix_c.exe
TARGET+=maingl_c.exe
TARGET+=main_v.exe
#TARGET+=tetris_v.exe
#TARGET+=tetrisnomix_v.exe
TARGET+=tvintris.exe
#TARGET+=tvintris0_v.exe
#TARGET+=tvintrisgl_v.exe
#TARGET+=maingl_v.exe
ifndef WIN32
TARGET+=glfnt.exe
TARGET+=mainig_v.exe
endif
TARGET+=mainnk_v.exe

CFLAGS:=
CXXFLAGS:=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0
CFLAGS+=-g -O0

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

all: SDL_CHECK VSDL2_CHECK $(TARGET)

VSDL2_CHECK:
	git submodule update --init --recursive

glfnt.exe: glfnt.cpp
	g++ $^ -o $@ -I /usr/include/freetype2/ -I v/thirdparty/ -lGLEW -lGL -lfreetype -lglfw  -ldl -lX11 -pthread

%gl_c.exe: LDLIBS+=$(GLLDLIBS)
%glsl_c.exe: LDLIBS+=$(GLLDLIBS)
%gl_v.exe: LDLIBS+=$(GLLDLIBS)
%glad.exe: CXXFLAGS+=$(GLADFLAGS)
%glad.exe: LDLIBS+=$(GLADLIBS)

VMOD_CHECK: $(V) $(HOME)/.vmodules/nsauzede/vsdl2/v.mod
$(HOME)/.vmodules/nsauzede/vsdl2/v.mod:
	$(V) install nsauzede.vsdl2

include sdl.mak
ifeq ($(SDL_VER),1)
SDL_FLAGS+=-DSDL1
else
SDL_FLAGS+=-DSDL2
endif

CFLAGS+=$(SDL_FLAGS)
CXXFLAGS+=$(SDL_FLAGS)

ifeq ($(SDL_VER),1)
LDLIBS+=$(SDL_LIBS) -lSDL_ttf -lSDL_mixer
else
LDLIBS+=$(SDL_LIBS) -lSDL2_ttf -lSDL2_mixer
endif

CFLAGS+=-pthread
CXXFLAGS+=-pthread
LDFLAGS+=-pthread

$(V):
	git clone https://github.com/vlang/v
	(cd $(@D) ; $(MAKE) ; cd -)

%ig_v.exe: CFLAGS+=-Ivig -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS=1 -DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1 -DIMGUI_IMPL_API= $(SDL_FLAGS)
%ig_v.exe: LDFLAGS=
%ig_v.exe: LDLIBS=vig/imgui_impl_sdl.o vig/imgui_impl_opengl3.so vig/cimgui.so $(SDL_LIBS) -lGL -lGLEW -lm

mainig.tmp.c: vig/examples/mainig/mainig.v | $(V)
	$(V) -o $@ $(VFLAGS) $^
mainig_v.exe: mainig.tmp.o | VIG_CHECK
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

VIG_CHECK:
	$(MAKE) -C vig

%ig_v.exe: %ig_v.o | VIG_CHECK
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

ifdef WIN32
NKLDLIBS:=-lopengl32 -lglew32
else
NKLDLIBS:=-lGL -lGLEW
endif

%nk_v.exe: CFLAGS+=-Insauzede/vnk -DNK_INCLUDE_FIXED_TYPES -DNK_INCLUDE_STANDARD_IO -DNK_INCLUDE_STANDARD_VARARGS -DNK_INCLUDE_DEFAULT_ALLOCATOR -DNK_INCLUDE_VERTEX_BUFFER_OUTPUT -DNK_INCLUDE_FONT_BAKING -DNK_INCLUDE_DEFAULT_FONT -DNK_IMPLEMENTATION -DNK_SDL_GL3_IMPLEMENTATION $(SDL_FLAGS)
%nk_v.exe: LDFLAGS=
%nk_v.exe: LDLIBS=$(SDL_LIBS) $(NKLDLIBS) -lm

VNK_CHECK:
	$(MAKE) -C nsauzede/vnk

mainnk_v.c: nsauzede/vnk/examples/mainnk_v/mainnk_v.v | $(V)
	$(V) -o $@ $(VFLAGS) $^

%nk_v.exe: %nk_v.o | VNK_CHECK
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

%.exe: %.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

vsdlstub.o: vsdl/vsdlstub.c
	$(CC) -c -o $@ $(CFLAGS) -g $^

tvintris.tmp.c: nsauzede/vsdl2/examples/tvintris/tvintris.v | $(V)
	$(V) -o $@ $(VFLAGS) $^
tvintris.exe: tvintris.tmp.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

%_v.exe: CFLAGS+=$(VCFLAGS)
#%_v.exe: LDLIBS+=vsdlstub.o
#%.c: %.v | $(V) vsdlstub.o
%.c: %.v | $(V)
#	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt *.tmp.c .tmp.*.c *.so *_v

mrproper: clobber
	$(RM) -Rf v
