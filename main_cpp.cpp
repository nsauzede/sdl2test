#include <stdlib.h>

#include <iostream>

#include "CSDL.h"

int main() {
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	std::cout << "hello SDL " << SDLV << std::endl;
	CSDL sdl;
	if (sdl.Init()) {
		std::cout << "failed to init SDL" << std::endl;
		exit( 1);
	}
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
