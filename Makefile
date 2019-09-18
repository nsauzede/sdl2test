TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=mainmix_c.exe
TARGET+=maingl_c.exe
TARGET+=main_v.exe
TARGET+=tetris_v.exe
TARGET+=tetrisnomix_v.exe
TARGET+=tvintris_v.exe
TARGET+=tvintris0_v.exe
TARGET+=tvintrisgl_v.exe
TARGET+=maingl_v.exe
TARGET+=glfnt.exe

CFLAGS:=
CXXFLAGS:=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0
CFLAGS+=-g -O0

CXXFLAGS+=-I.

V:=./v/v
#VFLAGS:=-debug -show_c_cmd
VCFLAGS:=-std=gnu11 -w -g -O0

_SYS:=$(shell uname -o)
ifeq ($(_SYS),Msys)
WIN32:=1
endif

ifdef WIN32
GLLDLIBS:=-lopengl32 -lglu32
else
GLLDLIBS:=-lGL -lGLU
endif

all: SDL_CHECK VMOD_CHECK $(TARGET)

glfnt.exe: glfnt.cpp
	g++ $^ -o $@ -I /usr/include/freetype2/ -I v/thirdparty/ -lGLEW -lGL -lfreetype /usr/local/lib64/libglfw3.a  -ldl -lX11 -pthread

%gl_c.exe: LDLIBS+=$(GLLDLIBS)
%gl_v.exe: LDLIBS+=$(GLLDLIBS)

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

%.exe: %.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

vsdlstub.o: vsdl/vsdlstub.c
	$(CC) -c -o $@ $(CFLAGS) -g $^

%_v.exe: CFLAGS+=$(VCFLAGS)
%_v.exe: LDLIBS+=vsdlstub.o
%.c: %.v | $(V) vsdlstub.o
#	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt *.tmp.c

mrproper: clobber
	$(RM) -Rf v
