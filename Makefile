TARGET=main_cpp.exe main_c.exe

CXXFLAGS=-Wall -Werror
CXXFLAGS+=-Wextra

CXXFLAGS+=-g -O0

CXXFLAGS+=-I.

include sdl.mak
ifeq ($(SDL_VER),1)
SDL_FLAGS+=-DSDL1
else
SDL_FLAGS+=-DSDL2
endif

CFLAGS+=$(SDL_FLAGS)
CXXFLAGS+=$(SDL_FLAGS)
LDLIBS+=$(SDL_LIBS)

all: SDL_CHECK $(TARGET)

%.exe:%.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

clean:
	$(RM) $(TARGET)

clobber: clean
	$(RM) *~
