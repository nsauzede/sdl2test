TARGET=main.exe

CXXFLAGS=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0

CXXFLAGS+=-I.

include sdl.mak
ifeq ($(SDL_VER),1)
CXXFLAGS+=-DSDL1
else
CXXFLAGS+=-DSDL2
endif

CXXFLAGS+=$(SDL_FLAGS)
LDLIBS+=$(SDL_LIBS)

all: SDL_CHECK $(TARGET)

%.exe:%.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

clean:
	$(RM) $(TARGET)

clobber: clean
	$(RM) *~
