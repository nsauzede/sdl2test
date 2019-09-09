TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=mainmix_c.exe
TARGET+=main_v.exe
TARGET+=tetris_v.exe
TARGET+=tetrisnomix_v.exe
TARGET+=tvintris_v.exe
TARGET+=tvintris0_v.exe

CFLAGS:=
CXXFLAGS:=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0
CFLAGS+=-g -O0

CXXFLAGS+=-I.

V:=./v/v
VFLAGS:=-debug -show_c_cmd
VCFLAGS:=-std=gnu11 -w -g -O0

all: SDL_CHECK VMOD_INSTALL $(TARGET)

VMOD_INSTALL: $(V)
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
%.c: %.v | vsdlstub.o
	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt

mrproper: clobber
	$(RM) -Rf v
