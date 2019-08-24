TARGET:=
TARGET+=main_cpp.exe
TARGET+=main_c.exe
TARGET+=main_v.exe

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
LDLIBS+=$(SDL_LIBS) -lSDL2_ttf vsdlstub.o

$(V):
	git clone https://github.com/vlang/v
	(cd $(@D) ; $(MAKE) ; cd -)

%.exe: %.o | vsdlstub.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

vsdlstub.o: vsdl/vsdlstub.c
	$(CC) -c -o $@ $(CFLAGS) $^

main_v.o: CFLAGS+=$(VCFLAGS)
%.c: %.v
	$(MAKE) -s $(V)
	$(V) -o $@ $(VFLAGS) $^

clean:
	$(RM) $(TARGET) *.o *_v.c

clobber: clean
	$(RM) *~ *.exe fns.txt

mrproper: clobber
	$(RM) -Rf v
