#include <stdlib.h>
#include <stdio.h>

#define SDL_DISABLE_IMMINTRIN_H
#include <SDL.h>
#ifdef SDL2
#include <SDL_ttf.h>
#include <SDL_image.h>
#endif

typedef struct AudioCtx_s {
        // dynamic
        Uint8 *audio_pos; // current pointer to the audio buffer to be played
        Uint32 audio_len; // remaining length of the sample we have to play
        // static at load
        SDL_AudioSpec wav_spec; // the specs of our piece of music
        Uint8 *wav_buffer; // buffer containing our audio file
        Uint32 wav_length; // length of our sample
} AudioCtx;

void my_audio_callback(void *userdata, Uint8 *stream, int _len) {
	Uint32 len = _len;
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

int main(int argc, char *argv[]) {
#ifdef SDL1
#define SDLV 1
#else
#define SDLV 2
#endif
	printf("hello SDL %d\n", SDLV);
	char *soundpath = "sounds/door2.wav";
	int w = 200;
	int h = 400;
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
	font = TTF_OpenFont("fonts/RobotoMono-Regular.ttf", 16);
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

#ifdef SDL2
	IMG_Init(IMG_INIT_PNG);
	SDL_Surface *img = IMG_Load("images/gb_head.png");
	SDL_Texture *imgtex = SDL_CreateTextureFromSurface(sdlRenderer, img);
	printf("img=%p imgtex=%p\n", img, imgtex);
#endif

	int quit = 0;
	int ballx = 0, bally = h / 2, balld = 10, balldir = 1;
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
		SDL_Rect rect;
               rect.x = 0;
               rect.y = 0;
               rect.w = w;
               rect.h = h;
		Uint32 col = SDL_MapRGB(screen->format, 255, 255, 255);
		SDL_FillRect(screen, &rect, col);

		rect.x = ballx;
		rect.y = bally;
		rect.w = balld;
		rect.h = balld;
		col = SDL_MapRGB(screen->format, 255, 0, 0);
		SDL_FillRect(screen, &rect, col);
		ballx += balldir;
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
		SDL_UpdateTexture(sdlTexture, NULL, screen->pixels, screen->pitch);
		SDL_RenderClear(sdlRenderer);
		SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
		if (font) {
			SDL_Color color = { 0, 0, 0, 0 };
			SDL_Surface * surface = TTF_RenderText_Solid(font,"Hello SDL_ttf", color);
			SDL_Texture * texture = SDL_CreateTextureFromSurface(sdlRenderer, surface);
			int texW = 0;
			int texH = 0;
			SDL_QueryTexture(texture, NULL, NULL, &texW, &texH);
			SDL_Rect dstrect = { 0, 0, texW, texH };
			SDL_RenderCopy(sdlRenderer, texture, NULL, &dstrect);
			SDL_DestroyTexture(texture);
			SDL_FreeSurface(surface);
		}
#ifdef SDL2
		rect.w = 32;
		rect.h = 32;
		rect.x = (w - rect.w) / 2;
		rect.y = (h - rect.h) / 2;
		SDL_RenderCopy(sdlRenderer, imgtex, NULL, &rect);
//		SDL_RenderCopy(sdlRenderer, imgtex, NULL, NULL);
#endif

		SDL_RenderPresent(sdlRenderer);
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
