#include <ApplicationServices/ApplicationServices.h>
#include <AppKit/AppKit.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <stdlib.h>

@interface ScreenFiller : NSView {
    CGImageRef initialImage;
    NSBezierPath *drawingPath;
    BOOL isDrawing;
}

@property (assign) NSBezierPath *drawingPath;
@property (assign) BOOL isDrawing;

- (void)drawRect:(NSRect)dirtyRect;

@end

@implementation ScreenFiller

@synthesize drawingPath, isDrawing;

- (id)init {
    self = [super init];
    if (self) {
        // Take screenshot at init
        CGDirectDisplayID display = CGMainDisplayID();
        initialImage = CGDisplayCreateImage(display);
        if (!initialImage) {
            NSLog(@"Failed to create screenshot image");
        }
        drawingPath = [[NSBezierPath alloc] init];
        [drawingPath setLineWidth:5.0];
        isDrawing = YES;
    }
    return self;
}

- (void)dealloc {
    if (initialImage) {
        CGImageRelease(initialImage);
    }
    [drawingPath release];
    [super dealloc];
}



- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = [self bounds];
    static bool logged = false;
    if (!logged) {
        NSLog(@"Drawing initial image");
        logged = true;
    }
    if (initialImage) {
        // Draw initial screenshot
        NSImage *image = [[NSImage alloc] initWithCGImage:initialImage size:NSMakeSize(CGImageGetWidth(initialImage), CGImageGetHeight(initialImage))];
        [image drawInRect:bounds];
        [image release];
    }
    // Draw the drawing path
    [[NSColor colorWithCalibratedRed:0.3 green:0.3 blue:1.0 alpha:1.0] set];
    [drawingPath stroke];
}

@end

static ScreenFiller *globalView;
static CGPoint lastMousePosition;

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"App started");

    // Create application
    NSApplication *app = [NSApplication sharedApplication];

    // Create window
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:screenRect
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];

    globalView = [[ScreenFiller alloc] init];
    [window setContentView:globalView];
    [window setLevel:NSScreenSaverWindowLevel];
    [window setIgnoresMouseEvents:NO];
    [window makeKeyAndOrderFront:nil];
    [window setReleasedWhenClosed:NO];

    // Get screen size
    float screenHeight = screenRect.size.height;

    // Get initial mouse position
    CGEventRef event = CGEventCreate(NULL);
    lastMousePosition = CGEventGetLocation(event);
    CFRelease(event);
    [[globalView drawingPath] moveToPoint:CGPointMake(lastMousePosition.x, screenHeight - lastMousePosition.y)];

    // Add monitor for mouse moved events
    id mouseMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMouseMoved handler:^(NSEvent *event) {
        NSLog(@"Mouse moved by user, exiting");
        [NSApp terminate:nil];
        return event;
    }];

    // Prevent display from sleeping
    IOPMAssertionID assertionID;
    IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep, kIOPMAssertionLevelOn, CFSTR("CursorRunner"), &assertionID);

    // Set up timer to move cursor chaotically every 0.1 seconds
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
        // Move cursor by small random deltas
        int deltaX = (int)arc4random_uniform(21) - 10; // -10 to 10
        int deltaY = (int)arc4random_uniform(21) - 10;
        int newX = lastMousePosition.x + deltaX;
        int newY = lastMousePosition.y + deltaY;
        // Clamp to screen
        if (newX < 0) newX = 0;
        if (newX >= screenRect.size.width) newX = screenRect.size.width - 1;
        if (newY < 0) newY = 0;
        if (newY >= screenRect.size.height) newY = screenRect.size.height - 1;
        CGPoint newPosition = CGPointMake(newX, newY);
        CGWarpMouseCursorPosition(newPosition);
        [[globalView drawingPath] lineToPoint:CGPointMake(newPosition.x, screenHeight - newPosition.y)];
        [globalView setNeedsDisplay:YES];
        lastMousePosition = newPosition;
    }];

    [app run];

    // Release the assertion
    IOPMAssertionRelease(assertionID);

    [timer invalidate];
    [globalView release];
    [pool release];

    return 0;
}
