#include "vga.h"

#define NS(X) kernel_screen_vga_ ## X

#define VIDEO_ADDR ((char *) 0xb8000)

static inline bool checkBoundary(int row, int col) {
    return row >= 0 && row < 25 && col >= 0 && col < 80;
}

bool NS(setChar)(int row, int col, char ch) {
    if (!checkBoundary(row, col))
        return false;
    *(VIDEO_ADDR + (80 * row + col) * 2) = ch;
    return true;
}

char NS(getChar)(int row, int col) {
    return *(VIDEO_ADDR + (80 * row + col) * 2);
}

bool NS(changeAttribute)(
        int row, int col,
        bool blink,
        bool foregroundIntensity,
        NS(Color) foregroundColor,
        NS(Color) backgroundColor) {
    if (!checkBoundary(row, col))
        return false;
    unsigned char attribute = 0;
    if (blink)
        attribute |= 0b10000000;
    if (foregroundIntensity)
        attribute |= 0b00001000;
    attribute |= (foregroundColor & 0b00000111);
    attribute |= ((backgroundColor << 4) & 0b01110000);
    *(VIDEO_ADDR + (80 * row + col) * 2 + 1) = attribute;

    return true;
}

void NS(moveCursor)(int x, int y) {
    int pos = y * NS(getWidth)() + x;

    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t) (pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t) ((pos >> 8) & 0xFF));
}