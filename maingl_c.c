#include <stdlib.h>
#include <stdio.h>

#include <SDL.h>
#ifdef SDL2
#include <SDL_ttf.h>
#endif
//#define GL_GLEXT_PROTOTYPES	// to get glGenBuffers(), ..
#include <SDL_opengl.h>
#include <GL/glu.h>

typedef struct AudioCtx_s {
        // dynamic
        Uint8 *audio_pos; // current pointer to the audio buffer to be played
        Uint32 audio_len; // remaining length of the sample we have to play
        // static at load
        SDL_AudioSpec wav_spec; // the specs of our piece of music
        Uint8 *wav_buffer; // buffer containing our audio file
        Uint32 wav_length; // length of our sample
} AudioCtx;

void my_audio_callback(void *userdata, Uint8 *stream, int len) {
        AudioCtx *ctx = userdata;
        if (ctx->audio_len ==0)
                return;

        len = ( len > ctx->audio_len ? ctx->audio_len : len );
        SDL_memset(stream, 0, len);
        //SDL_memcpy (stream, audio_pos, len);                                  //
        SDL_MixAudio(stream, ctx->audio_pos, len, SDL_MIX_MAXVOLUME);// mix from on

        ctx->audio_pos += len;
        ctx->audio_len -= len;
}

//#define USE2D
void GlFillRect(SDL_Surface *screen, SDL_Rect *rect, SDL_Color *col) {
	int ww = screen->w;
	int hh = screen->h;
	GLfloat x = (GLfloat)2 * rect->x / (ww - 1) - 1;		// 0->w-1 => 0->2 => -1->+1
	GLfloat y = (GLfloat)2 * ((hh - 1) - rect->y) / (hh - 1) - 1;	// 0->h-1 => 1->0 => 2->0 => +1->-1
	GLfloat w = (GLfloat)2 * rect->w / ww;
	GLfloat h = (GLfloat)2 * rect->h / hh;
	GLfloat r = (GLfloat)col->r / 255;
	GLfloat g = (GLfloat)col->g / 255;
	GLfloat b = (GLfloat)col->b / 255;

	glColor3f(r, g, b);
//	glBegin(GL_QUADS);
	glVertex2f(x, y);
	glVertex2f(x + w, y);
	glVertex2f(x + w, y - h);
	glVertex2f(x, y - h);
//	glEnd();
}

int main(int argc, char *argv[]) {
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	printf("hello SDL %d\n", SDLV);
	char *soundpath = "sounds/door2.wav";
	int w = 400;
	int h = 300;
	int bpp = 32;
	SDL_Surface *screen = 0;
#ifdef SDL1
#else
	SDL_Window *sdlWindow = 0;
	SDL_Renderer *sdlRenderer = 0;
	SDL_Texture *sdlTexture = 0;
	TTF_Font *font = 0;
#endif

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) return 1;
#ifdef SDL1
	screen = SDL_SetVideoMode(w, h, bpp, 0);
#else
	SDL_CreateWindowAndRenderer(w, h, 0, &sdlWindow, &sdlRenderer);
	screen = SDL_CreateRGBSurface(0, w, h, bpp,0x00FF0000,0x0000FF00,0x000000FF,0xFF000000);
	sdlTexture = SDL_CreateTexture(sdlRenderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, w, h);
	// OpenGL
	// Loosely followed the great SDL2+OpenGL2.1 tutorial here :
	// http://lazyfoo.net/tutorials/OpenGL/01_hello_opengl/index2.php
	SDL_GLContext glContext = SDL_GL_CreateContext(sdlWindow);
	if (glContext == NULL) {
		printf("Couldn't create OpenGL context !\n");
	} else {
		printf("Created OpenGL context.\n");
	}
	if (SDL_GL_SetSwapInterval(1) < 0) {
		printf("Couldn't use VSync !\n");
	} else {
		printf("Using VSync.\n");
	}
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glClearColor(0.f, 0.f, 0.f, 1.f);
#endif
	if (!screen) {
		printf("failed to init SDL screen\n");
		exit(1);
	}
	atexit(SDL_Quit);
#ifdef SDL2
	if (TTF_Init() == -1) {
		printf("failed to init TTF\n");
		exit(1);
	}
	atexit(TTF_Quit);
	font = TTF_OpenFont("RobotoMono-Regular.ttf", 16);
#endif

        AudioCtx actx;
#ifdef SDL2
        SDL_zero(actx);
#else
	memset(&actx, 0, sizeof(actx));
#endif
        if( SDL_LoadWAV(soundpath, &actx.wav_spec, &actx.wav_buffer, &actx.wav_length) == NULL ){
                printf("couldn't load wav\n");
                return 1;
        }
        // set the callback function
        actx.wav_spec.callback = my_audio_callback;
        actx.wav_spec.userdata = &actx;

        /* Open the audio device */
        if ( SDL_OpenAudio(&actx.wav_spec, NULL) < 0 ){
                fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
                exit(-1);
        }

	int quit = 0;
	int ballx = 0, bally = h / 2, balld = 10, balldir = 1, balldelt = balld / 2;
	int nangle = 0;
#if 0
	GLuint vbo;
	glGenBuffers(1, &vbo);
#endif
	while (!quit) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				quit = 1;
				break;
			}
			if (event.type == SDL_KEYDOWN) {
				if (event.key.keysym.sym == SDLK_ESCAPE) {
					quit = 1;
					break;
				}
			}
		}
		if (quit)
			break;
		ballx += balldir * balldelt;
		if (balldir == 1) {
			if (ballx >= w - balld) {
				balldir = -1;
        // trigger sound restart
        actx.audio_pos = actx.wav_buffer; // copy sound buffer
        actx.audio_len = actx.wav_length; // copy file length
        /* Start playing */
        SDL_PauseAudio(0);
			}
		} else {
			if (ballx <= 0) {
				balldir = 1;
        // trigger sound restart
        actx.audio_pos = actx.wav_buffer; // copy sound buffer
        actx.audio_len = actx.wav_length; // copy file length
        /* Start playing */
        SDL_PauseAudio(0);
			}
		}

#ifdef SDL1
		SDL_UpdateRect(screen, 0, 0, 0, 0);
#else
#ifdef USE2D
#if 1
		SDL_UpdateTexture(sdlTexture, NULL, screen->pixels, screen->pitch);
		SDL_RenderClear(sdlRenderer);
		SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
#endif
#if 1
		SDL_Rect rect = {0, 0, w, h};
		Uint32 col = SDL_MapRGB(screen->format, 0, 0, 0);
		SDL_FillRect(screen, &rect, col);
#if 0
		rect.x = 0;rect.y = 0;rect.w = w / 2;rect.h = h / 2;
		col = SDL_MapRGB(screen->format, 0, 255, 0);
		SDL_FillRect(screen, &rect, col);

		rect.x = w / 2;rect.y = h / 2;rect.w = w / 2;rect.h = h / 2;
		col = SDL_MapRGB(screen->format, 0, 0, 255);
		SDL_FillRect(screen, &rect, col);
#endif
		rect.x = ballx;rect.y = bally;rect.w = balld;rect.h = balld;
		col = SDL_MapRGB(screen->format, 255, 0, 0);
		SDL_FillRect(screen, &rect, col);
#endif
#if 1
		if (font) {
			SDL_Color color = { 255, 255, 255 };
			SDL_Surface * surface = TTF_RenderText_Solid(font,"Hello SDL OpenGL", color);
			SDL_Texture * texture = SDL_CreateTextureFromSurface(sdlRenderer, surface);
			int texW = 0;
			int texH = 0;
			SDL_QueryTexture(texture, NULL, NULL, &texW, &texH);
			SDL_Rect dstrect = { 0, 0, texW, texH };
			SDL_RenderCopy(sdlRenderer, texture, NULL, &dstrect);
			SDL_DestroyTexture(texture);
			SDL_FreeSurface(surface);
		}
#endif
		SDL_RenderPresent(sdlRenderer);
#else
		glClear(GL_COLOR_BUFFER_BIT);
#if 1
#define DELT 2
		float angle = nangle * DELT;
		nangle++;
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glRotatef(angle,1,1,1);
		glBegin(GL_QUADS);
		glColor3f(0.f, 0.f, 0.2f);
		glVertex2f(-0.5f, -0.5f);
		glColor3f(1.f, 0.f, 0.2f);
		glVertex2f(0.5f, -0.5f);
		glColor3f(1.f, 1.f, 0.2f);
		glVertex2f(0.5f, 0.5f);
		glColor3f(0.f, 1.f, 0.2f);
		glVertex2f(-0.5f, 0.5f);
		glEnd();
#endif
#if 1
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glBegin(GL_QUADS);
		SDL_Rect rect;
		SDL_Color col;
#if 0
		rect.x = 0;rect.y = 0; rect.w = w / 2; rect.h = h / 2;
		col.r = 0; col.g = 255;col.b = 0;
		GlFillRect(screen, &rect, &col);

		rect.x = w / 2;rect.y = h / 2;rect.w = w / 2;rect.h = h / 2;
		col.r = 0;col.g = 0;col.b = 255;
		GlFillRect(screen, &rect, &col);
#endif
		rect.x = ballx;rect.y = bally;rect.w = balld;rect.h = balld;
		col.r = 255;col.g = 0;col.b = 0;
		GlFillRect(screen, &rect, &col);

		if (font) {
			SDL_Color color = { 255, 255, 255 };
			SDL_Surface * surface = TTF_RenderText_Solid(font,"Hello SDL OpenGL", color);
			SDL_Texture * texture = SDL_CreateTextureFromSurface(sdlRenderer, surface);
			int texW = 0;
			int texH = 0;
			SDL_QueryTexture(texture, NULL, NULL, &texW, &texH);
			SDL_Rect dstrect = { 0, 0, texW, texH };
			SDL_RenderCopy(sdlRenderer, texture, NULL, &dstrect);
			SDL_DestroyTexture(texture);
			SDL_FreeSurface(surface);
		}

		glEnd();
#endif
		SDL_GL_SwapWindow(sdlWindow);
#endif
#endif
		SDL_Delay(10);
	}
#ifdef SDL2
	if (font) {
		TTF_CloseFont(font);
	}
#endif
        // shut everything audio down
        SDL_CloseAudio();
        SDL_FreeWAV(actx.wav_buffer);
	printf("bye\n");

	return 0;
}
