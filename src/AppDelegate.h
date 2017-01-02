
#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

class TutorialApplication;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, assign) CVDisplayLinkRef displayLink;
@property (nonatomic, assign) TutorialApplication *tutorialApplication;

- (void)go;
- (void)shutdown;

@end
