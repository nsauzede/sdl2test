TARGET:=
TARGET+=main121
TARGET+=main122
TARGET+=main12

all: $(TARGET)

SDL1_CFLAGS:=`sdl-config --cflags`
SDL1_LIBS:=`sdl-config --libs`
SDL2_CFLAGS:=`sdl2-config --cflags`
SDL2_LIBS:=`sdl2-config --libs`

main121: CFLAGS+=$(SDL1_CFLAGS) -DSDL1
main121: LDLIBS+=$(SDL1_LIBS)

main122: CFLAGS+=$(SDL2_CFLAGS) -DSDL2
main122: LDLIBS+=$(SDL2_LIBS)

main12: CFLAGS+=-I. $(SDL2_CFLAGS) -DSDL1
main12: LDLIBS+=$(SDL2_LIBS)

main121: main12.c
	$(CC) -o $@ $^ $(CFLAGS) $(LDLIBS)

main122: main12.c
	$(CC) -o $@ $^ $(CFLAGS) $(LDLIBS)

main12: main12.c
	$(CC) -o $@ $^ $(CFLAGS) $(LDLIBS)

clean:
	$(RM) $(TARGET)
