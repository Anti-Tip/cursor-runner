#include <ApplicationServices/ApplicationServices.h>
#include <unistd.h>
#include <stdlib.h>
#include <time.h>

int main() {
    srand(time(NULL));

    CGDirectDisplayID display = CGMainDisplayID();
    size_t width = CGDisplayPixelsWide(display);
    size_t height = CGDisplayPixelsHigh(display);

    while (1) {
        int x = rand() % width;
        int y = rand() % height;

        CGEventRef moveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, CGPointMake(x, y), kCGMouseButtonLeft);
        CGEventPost(kCGHIDEventTap, moveEvent);
        CFRelease(moveEvent);

        usleep(100000); // 0.1 секунды

        CGEventRef checkEvent = CGEventCreate(NULL);
        CGPoint current = CGEventGetLocation(checkEvent);
        CFRelease(checkEvent);

        if ((int)current.x != x || (int)current.y != y) {
            return 0;
        }
    }

    return 0;
}
