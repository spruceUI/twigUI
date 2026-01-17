#include <SDL/SDL.h>
#include <SDL/SDL_ttf.h>

#include <stdio.h>
#include <string.h>
#include <stdbool.h>

SDL_Surface *screen;
SDL_Event main_event;
TTF_Font *font = NULL;

int min(int a, int b) {
    return (a <= b) ? a : b;
}

bool load_font(int screen_w, int screen_h) {
    const int screen_min = min(screen_w, screen_h);
    const int base_size = 11;
    int font_size;

    if (screen_min < 320) {
        font_size = base_size;
    } else if (screen_min < 720) {
        font_size = base_size * 2;
    } else {
        font_size = base_size * 3;
    }

    font = TTF_OpenFont("nunwen.ttf", font_size);

    if (font == NULL) {
        return false;
    } else {
        return true;
    }
}

bool sdl_init(int screen_w, int screen_h) {
    /* Initialize the SDL library */
    if(SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "Couldn't initialize SDL: %s\n", SDL_GetError());
        return false;
    }

    /* Clean up on exit */
    atexit(SDL_Quit);

    screen = SDL_SetVideoMode(screen_w, screen_h, 32, SDL_HWSURFACE | SDL_DOUBLEBUF);
    if (screen == NULL) {
        fprintf(stderr, "Couldn't set video mode: %s\n", SDL_GetError());
        return false;
    }

    //Initialize SDL_ttf
    if (TTF_Init() == -1) {
        fprintf(stderr, "Couldn't initialize fonts: %s\n", SDL_GetError());
        return false;
    }

    // Open the font
    if (load_font(screen_w, screen_h) == false) {
        printf("Couldn't load font.\n");
        return false;
    }

    SDL_ShowCursor(0);

    return true;
}

void sdl_quit() {
    // Quit SDL
    TTF_CloseFont(font);
    TTF_Quit();

    SDL_FreeSurface(screen);
    SDL_Quit();
}

void draw_text(char *text) {
    char text_cpy[strlen(text)+1];
    strcpy(text_cpy, text);

    const SDL_Color t_color = {235, 219, 178};
    SDL_Surface *t_surface = NULL;
    SDL_Rect text_rect;

    int text_w;
    int text_h;

    // Count the amount of lines
    int lines_c = 0;
    char* token = strtok(text, "|");
    while(token) {
        lines_c++;
        token = strtok(NULL, "|");
    }

    // Actually draw text
    int line_n = 0;
    token = strtok(text_cpy, "|");
    while(token) {
        TTF_SizeText(font, token, &text_w, &text_h);

        text_rect.x = (screen->w / 2) - (text_w / 2);
        text_rect.y = ((screen->h / 2) - ((text_h * lines_c) / 2)) + (line_n++ * text_h);

        t_surface = TTF_RenderText_Solid(font, token, t_color);
        SDL_BlitSurface(t_surface, NULL, screen, &text_rect);

        SDL_FreeSurface(t_surface);
        token = strtok(NULL, "|");
    }
}

int main(int argc, char *argv[]) {
    bool exit = false;

    if (argc != 4) {
        puts("Usage:\n\tshow_msg <screen_w> <screen_h> <text message>");
        return 1;
    }

    int screen_w = strtol(argv[1], NULL, 0);
    int screen_h = strtol(argv[2], NULL, 0);

    // Initialize SDL
    if (sdl_init(screen_w, screen_h) == false) {
        return 1;
    }

    SDL_Flip(screen);
    SDL_FillRect(screen, NULL, SDL_MapRGB(screen->format, 40, 40, 56));

    draw_text(argv[3]);
    SDL_UpdateRect(screen, 0, 0, 0, 0);

    while (exit == false) {
        while (SDL_PollEvent(&main_event)) {
            switch (main_event.type) {
                case SDL_QUIT:
                    exit = true;
                    break;

                case SDL_KEYDOWN:
                    break;
                }
        }
    }

    sdl_quit();
    return 0;
}
