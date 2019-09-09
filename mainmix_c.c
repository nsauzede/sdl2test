#include <stdlib.h>
#include <stdio.h>

#include <SDL.h>
#ifdef SDL2
#endif
#include <SDL_ttf.h>
#include <SDL_mixer.h>

typedef struct AudioCtx_s {
	Mix_Chunk *wave;
} AudioCtx;

#if 1
#define BUFFER 1024
        Sint16 stream[2][BUFFER*2*2];
int len=BUFFER*2*2, done=0, need_refresh=0, bits=0, which=0,
        sample_size=0, position=0, rate=0;
#endif

void print_init_flags(int flags)
{
#define PFLAG(a) if(flags&MIX_INIT_##a) printf(#a " ")
        PFLAG(FLAC);
        PFLAG(MOD);
        PFLAG(MP3);
        PFLAG(OGG);
        if(!flags)
                printf("None");
        printf("\n");
}

int main(int argc, char *argv[]) {
#ifdef WIN32
	setbuf(stdout, 0);	// this to avoid stdout buffering on windows/mingw
#endif

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

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_JOYSTICK) < 0) return 1;
	atexit(SDL_Quit);
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
#ifdef SDL2
	if (TTF_Init() == -1) {
		printf("failed to init TTF\n");
		exit(1);
	}
	atexit(TTF_Quit);
	font = TTF_OpenFont("RobotoMono-Regular.ttf", 16);
#endif
        int audio_rate,audio_channels;
        Uint16 audio_format;
        Uint32 t;
        Mix_Music *music;
        int volume=SDL_MIX_MAXVOLUME;

	int initted=Mix_Init(0);
#if 1
	printf("Before Mix_Init SDL_mixer supported: ");
        print_init_flags(initted);
        initted=Mix_Init(~0);
        printf("After  Mix_Init SDL_mixer supported: ");
        print_init_flags(initted);
        Mix_Quit();
#endif
        if(Mix_OpenAudio(44100,MIX_DEFAULT_FORMAT,2,BUFFER)<0) {
                printf("error Mix_OpenAudio\n");
                exit(1);
        }
#if 1
        /* we play no samples, so deallocate the default 8 channels...*/
//        Mix_AllocateChannels(0);
        {
                int i,n=Mix_GetNumChunkDecoders();
                printf("There are %d available chunk(sample) decoders:\n", n);
                for(i=0; i<n; ++i)
                        printf("        %s\n", Mix_GetChunkDecoder(i));
                n = Mix_GetNumMusicDecoders();
                printf("There are %d available music decoders:\n",n);
                for(i=0; i<n; ++i)
                        printf("        %s\n", Mix_GetMusicDecoder(i));
        }
        
        Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
        bits=audio_format&0xFF;
        sample_size=bits/8+audio_channels;
        rate=audio_rate;
        printf("Opened audio at %d Hz %d bit %s, %d bytes audio buffer\n", audio_rate,
                        bits, audio_channels>1?"stereo":"mono", BUFFER );
//        music=Mix_LoadMUS("sounds/SuperTwintrisThoseThree.mod");
#endif
        music=Mix_LoadMUS("sounds/TwintrisThosenine.mod");
#if 1
        if (music) {
          Mix_MusicType type=Mix_GetMusicType(music);
          printf("Music type: %s\n",
                          type==MUS_NONE?"MUS_NONE":
                          type==MUS_CMD?"MUS_CMD":
                          type==MUS_WAV?"MUS_WAV":
                          /*type==MUS_MOD_MODPLUG?"MUS_MOD_MODPLUG":*/
                          type==MUS_MOD?"MUS_MOD":
                          type==MUS_MID?"MUS_MID":
                          type==MUS_OGG?"MUS_OGG":
                          type==MUS_MP3?"MUS_MP3":
//                          type==MUS_MP3_MAD?"MUS_MP3_MAD":
                          type==MUS_FLAC?"MUS_FLAC":
                          "Unknown");
        }
#endif
#if 1
        AudioCtx actx;
#ifdef SDL2
        SDL_zero(actx);
#else
	memset(&actx, 0, sizeof(actx));
#endif
        actx.wave = Mix_LoadWAV(soundpath);
        if (actx.wave == NULL ){
                printf("couldn't load wav\n");
                return 1;
        }
#endif
    printf("%i joysticks were found.\n\n", SDL_NumJoysticks() );
    printf("The names of the joysticks are:\n");
		
    for( int i=0; i < SDL_NumJoysticks(); i++ ) 
    {
    	SDL_Joystick *joy = SDL_JoystickOpen(i);
        printf("Opened Joystick %d\n", i);
#ifdef SDL1
//	char *name = SDL_JoystickName(i);
//	printf("    %s\n", name ? name : "(noname)");
        printf("Name: %s\n", SDL_JoystickName(i));
#else
        printf("Name: %s\n", SDL_JoystickNameForIndex(i));
#endif
        printf("Number of Axes: %d\n", SDL_JoystickNumAxes(joy));
        printf("Number of Buttons: %d\n", SDL_JoystickNumButtons(joy));
        printf("Number of Balls: %d\n", SDL_JoystickNumBalls(joy));
    }
	SDL_JoystickEventState(SDL_ENABLE);
    //        Mix_SetPostMix(postmix,argv[1]);
#if 1
        if(Mix_PlayMusic(music, 1)!=-1) {
	        Mix_VolumeMusic(volume);
        }
#endif
	int quit = 0;
	int ballx = 0, bally = h / 2, balld = 10, balldir = 1;
	int pause = 0;
	while (!quit) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				quit = 1;
				break;
			}
#ifdef SDL2
			if (event.type == SDL_JOYDEVICEADDED) {
				printf("JOYDEVADDED\n");
				continue;
			}
#endif
			if (event.type == SDL_JOYHATMOTION) {
				printf("hat\n");
				continue;
			}
			if (event.type == SDL_JOYAXISMOTION) {
//				printf("axis\n");
				continue;
			}
			if (event.type == SDL_JOYBUTTONDOWN) {
				printf("EVENT JOYSTICK : button=%d\n", event.jbutton.button);
				if (event.jbutton.button == 0) {
        // trigger sound restart
	Mix_PlayChannel(0, actx.wave, 0);
				}
				continue;
			}
			if (event.type == SDL_KEYDOWN) {
				if (event.key.keysym.sym == SDLK_ESCAPE) {
					quit = 1;
					break;
				}
				if (event.key.keysym.sym == SDLK_RETURN) {
					if (!pause) {
						// trigger sound restart
						Mix_PlayChannel(0, actx.wave, 0);
					}
					continue;
				}
				if (event.key.keysym.sym == SDLK_SPACE) {
					pause = 1 - pause;
					if (pause) {
						Mix_PauseMusic();
					} else {
						Mix_ResumeMusic();
					}
					continue;
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
if (!pause) {
		ballx += balldir;
		if (balldir == 1) {
			if (ballx >= w - balld) {
				balldir = -1;
        // trigger sound restart
	Mix_PlayChannel(0, actx.wave, 0);
			}
		} else {
			if (ballx <= 0) {
				balldir = 1;
        // trigger sound restart
	Mix_PlayChannel(0, actx.wave, 0);
			}
		}
}
#ifdef SDL1
		SDL_UpdateRect(screen, 0, 0, 0, 0);
#else
		SDL_UpdateTexture(sdlTexture, NULL, screen->pixels, screen->pitch);
		SDL_RenderClear(sdlRenderer);
		SDL_RenderCopy(sdlRenderer, sdlTexture, NULL, NULL);
		if (font) {
			SDL_Color color = { 0, 0, 0 };
			SDL_Surface * surface = TTF_RenderText_Solid(font,"Hello SDL ttf/mixer", color);
			SDL_Texture * texture = SDL_CreateTextureFromSurface(sdlRenderer, surface);
			int texW = 0;
			int texH = 0;
			SDL_QueryTexture(texture, NULL, NULL, &texW, &texH);
			SDL_Rect dstrect = { 0, 0, texW, texH };
			SDL_RenderCopy(sdlRenderer, texture, NULL, &dstrect);
			SDL_DestroyTexture(texture);
			SDL_FreeSurface(surface);
		}
		SDL_RenderPresent(sdlRenderer);
#endif
		SDL_Delay(10);
	}
#ifdef SDL2
	if (font) {
		TTF_CloseFont(font);
	}
#endif
	if (actx.wave) {
		Mix_FreeChunk(actx.wave);
	}
        if (music)
                Mix_FreeMusic(music);
        Mix_CloseAudio();
	printf("bye\n");

	return 0;
}
