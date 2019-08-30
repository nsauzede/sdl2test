#include <stdlib.h>
#include <stdio.h>

#include <SDL.h>
#ifdef SDL2
#include <SDL_ttf.h>
#include <SDL_mixer.h>
#endif

#if 0
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
#endif

#if 1
#define BUFFER 1024
        Sint16 stream[2][BUFFER*2*2];
int len=BUFFER*2*2, done=0, need_refresh=0, bits=0, which=0,
        sample_size=0, position=0, rate=0;

static void postmix(void *udata, Uint8 *_stream, int _len)
{
#if 0
        position+=_len/sample_size;
        /* fprintf(stderr,"pos=%7.2f seconds \r",position/(float)rate); */
        if(need_refresh)
                return;
        /* save the stream buffer and indicate that we need a redraw */
        len=_len;
        memcpy(stream[(which+1)%2],_stream,len>s->w*4?s->w*4:len);
        which=(which+1)%2;
        need_refresh=1;
#endif
}
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

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) return 1;
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
#if 0
        AudioCtx actx;
        SDL_zero(actx);
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
#endif
        int audio_rate,audio_channels;
        Uint16 audio_format;
        Uint32 t;
        Mix_Music *music;
        int volume=SDL_MIX_MAXVOLUME;

	int initted=Mix_Init(0);
	printf("Before Mix_Init SDL_mixer supported: ");
        print_init_flags(initted);
        initted=Mix_Init(~0);
        printf("After  Mix_Init SDL_mixer supported: ");
        print_init_flags(initted);
        Mix_Quit();
        if(Mix_OpenAudio(44100,MIX_DEFAULT_FORMAT,2,BUFFER)<0) {
                printf("error Mix_OpenAudio\n");
                exit(1);
        }
        /* we play no samples, so deallocate the default 8 channels...*/
        Mix_AllocateChannels(0);
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
        music=Mix_LoadMUS("sounds/SuperTwintrisThoseThree.mod");
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
        Mix_SetPostMix(postmix,argv[1]);
        if(Mix_PlayMusic(music, 1)!=-1) {
	        Mix_VolumeMusic(volume);
        }

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
#if 0
        // trigger sound restart
        actx.audio_pos = actx.wav_buffer; // copy sound buffer
        actx.audio_len = actx.wav_length; // copy file length
        /* Start playing */
        SDL_PauseAudio(0);
#endif
			}
		} else {
			if (ballx <= 0) {
				balldir = 1;
#if 0
        // trigger sound restart
        actx.audio_pos = actx.wav_buffer; // copy sound buffer
        actx.audio_len = actx.wav_length; // copy file length
        /* Start playing */
        SDL_PauseAudio(0);
#endif
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
		SDL_RenderPresent(sdlRenderer);
#endif
		SDL_Delay(10);
	}
#ifdef SDL2
	if (font) {
		TTF_CloseFont(font);
	}
#endif
#if 0
        // shut everything audio down
        SDL_CloseAudio();
        SDL_FreeWAV(actx.wav_buffer);
#endif
        if (music)
                Mix_FreeMusic(music);
        Mix_CloseAudio();
	printf("bye\n");

	return 0;
}
