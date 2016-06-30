TARGET=main.exe

all: CHECK_SDL $(TARGET)

ifndef SDLCONFIG

SDL1CONFIG=sdl-config
ifneq ($(shell a=`which $(SDL1CONFIG) 2>&1`;echo $$?),0)
SDL1CONFIG=
else
#CHECK_SDL:
#	@echo "Found SDL1"
endif

SDL2CONFIG=sdl2-config
ifneq ($(shell a=`which $(SDL2CONFIG) 2>&1`;echo $$?),0)
SDL2CONFIG=
else
#CHECK_SDL:
#	@echo "Found SDL2"
endif

ifdef SDL2CONFIG
SDLCONFIG=$(SDL2CONFIG)
else
ifdef SDL1CONFIG
SDLCONFIG=$(SDL1CONFIG)
endif
endif

ifndef SDLCONFIG
SDLCONFIG=NO_SDL_INSTALLED
CHECK_SDL:
	@echo "No SDL installed.\nTry : $$ sudo apt-get install libsdl2-dev";false
else
CHECK_SDL:
	@echo "Using detected SDLCONFIG=$(SDLCONFIG)"
endif

else

CHECK_SDL:
	@echo "Using forced SDLCONFIG=$(SDLCONFIG)"

endif

CXXFLAGS=-Wall -Werror
#CXXFLAGS=-Wextra

CXXFLAGS+=-g -O0

ifdef SDLCONFIG
CXXFLAGS+=`$(SDLCONFIG) --cflags`
endif

OP_SYS=$(shell uname -o)
ifeq ($(OP_SYS),Msys)
WINDOWS=1
endif

ifdef WINDOWS
STATIC=1
endif

SDLV=$(shell )

ifeq ($(shell $(SDLCONFIG) --version | cut -f 1 -d "."),1)
USE_SDL1=1
else
USE_SDL1=
endif

ifdef USE_SDL1
CXXFLAGS+=-DSDL1
endif

ifdef STATIC
LDLIBS+=`$(SDLCONFIG) --static-libs` -static
else
LDLIBS+=`$(SDLCONFIG) --libs`
endif
ifdef WINDOWS
# this one to get text console output
LDLIBS+=-mno-windows
endif

%.exe:%.o
	$(CXX) -o $@ $(LDFLAGS) $^ $(LDLIBS)

clean:
	$(RM) $(TARGET)

clobber: clean
	$(RM) *~
