TARGET:=game

CFLAGS+=`sdl2-config --cflags`
LDLIBS+=`sdl2-config --libs`

CFLAGS+=-Wall -Werror

all: game

check: game
	./game

clean:
	$(RM) $(TARGET)
