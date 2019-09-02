TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=mainmix_c.exe
TARGET+=main_v.exe
TARGET+=tetris_v.exe
TARGET+=tetrisnomix_v.exe
TARGET+=tvintris_v.exe

CFLAGS:=
CXXFLAGS:=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0

CXXFLAGS+=-I.

V:=./v/v
VFLAGS:=-debug -show_c_cmd
VCFLAGS:=-std=gnu11 -w -g -O0

all: SDL_CHECK $(TARGET)

include sdl.mak
ifeq ($(SDL_VER),1)
SDL_FLAGS+=-DSDL1
else
SDL_FLAGS+=-DSDL2
endif

CFLAGS+=$(SDL_FLAGS)
CXXFLAGS+=$(SDL_FLAGS)
LDLIBS+=$(SDL_LIBS) vsdlstub.o -lSDL2_ttf -lSDL2_mixer

CFLAGS+=-pthread
CXXFLAGS+=-pthread
LDFLAGS+=-pthread

$(V):
	git clone https://github.com/vlang/v
	(cd $(@D) ; $(MAKE) ; cd -)

mainmix_c.exe: LDLIBS+=-lSDL2_mixer
%.exe: %.o | vsdlstub.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

vsdlstub.o: vsdl/vsdlstub.c
	$(CC) -c -o $@ $(CFLAGS) -g $^

%_v.exe: CFLAGS+=$(VCFLAGS)
%.c: %.v
	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt

mrproper: clobber
	$(RM) -Rf v
