#include <ApplicationServices/ApplicationServices.h>
#include <unistd.h>
#include <cstdlib>
#include <ctime>

int main() {
    srand(time(NULL));
    CGDirectDisplayID display = CGMainDisplayID();
    CGRect screenBounds = CGDisplayBounds(display);
    int screenWidth = (int)screenBounds.size.width;
    int screenHeight = (int)screenBounds.size.height;
    int x = rand() % screenWidth;
    int y = rand() % screenHeight;
    int dx = (rand() % 10) - 5; // velocity -5 to 5
    int dy = (rand() % 10) - 5;
    while (true) {
        x += dx;
        y += dy;
        if (x < 0) { x = 0; dx = -dx; }
        if (x >= screenWidth) { x = screenWidth - 1; dx = -dx; }
        if (y < 0) { y = 0; dy = -dy; }
        if (y >= screenHeight) { y = screenHeight - 1; dy = -dy; }
        CGEventRef moveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, CGPointMake(x, y), kCGMouseButtonLeft);
        CGEventPost(kCGHIDEventTap, moveEvent);
        CFRelease(moveEvent);
        usleep(10000); // 0.01 seconds for smoother movement
        CGEventRef currentEvent = CGEventCreate(NULL);
        CGPoint currentPoint = CGEventGetLocation(currentEvent);
        CFRelease(currentEvent);
        if ((int)currentPoint.x != x || (int)currentPoint.y != y) {
            return 0;
        }
    }
    return 0;
}
