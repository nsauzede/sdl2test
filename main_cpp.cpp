#include <stdlib.h>

#include <iostream>

#include "CSDL.h"

int main( int argc, char *argv[]) {
	int help = 0;
	int arg = 1;
	while (arg < argc) {
		if (!strcmp( argv[arg], "--help")){
			help = 1;
		}
		arg++;
	}
	if (help) {
		printf( "TODO: write help\n");
		exit( 0);
	}
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	std::cout << "hello SDL " << SDLV << std::endl;
	CSDL sdl;
	sdl.Init();
	int quit = 0;
	while (!quit) {
		if (sdl.Poll()) {
			quit = 1;
			break;
		}
		sdl.Draw();
		sdl.Delay( 500);
	}
	std::cout << "bye" << std::endl;
	return 0;
}
