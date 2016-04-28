TARGET=main.exe

SDL2CONFIG=sdl2-config

CXXFLAGS=-Wall -Werror
#CXXFLAGS=-Wextra

CXXFLAGS+=-g -O0

CXXFLAGS+=`$(SDL2CONFIG) --cflags`

WINDOWS=1
STATIC=1

ifdef STATIC
LDLIBS+=`$(SDL2CONFIG) --static-libs` -static
else
LDLIBS+=`$(SDL2CONFIG) --libs`
endif
ifdef WINDOWS
# this one to get text console output
LDLIBS+=-mno-windows
endif

all: $(TARGET)

%.exe:%.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

clean:
	$(RM) $(TARGET)

clobber: clean
	$(RM) *~
