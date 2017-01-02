
#import "AppDelegate.h"
#import "TutorialApplication.h"
//#import <RenderSystems/GL/OSX/OgreOSXContext.h>
#import <RenderSystems/GL/OSX/OgreOSXCocoaWindow.h>

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

using namespace Ogre;

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                      CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    AppDelegate *appDelegate = (AppDelegate *)displayLinkContext;
    TutorialApplication *application = appDelegate.tutorialApplication;

    if(!application->isShuttingDown() &&
       Ogre::Root::getSingletonPtr() &&
       Ogre::Root::getSingleton().isInitialised())
    {
        NSOpenGLContext *ctx = static_cast<OSXCocoaWindow *>(application->getWindow())->nsopenGLContext();
        CGLContextObj cglContext = (CGLContextObj)[ctx CGLContextObj];

        // Lock the context before we render into it.
        CGLLockContext(cglContext);

        // Calculate the time since we last rendered.
        Real deltaTime = 1.0 / (outputTime->rateScalar * (Real)outputTime->videoTimeScale / (Real)outputTime->videoRefreshPeriod);

        // Make the context current and dispatch the render.
        [ctx makeCurrentContext];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
           Ogre::Root::getSingleton().renderOneFrame(deltaTime);
        });

        CGLUnlockContext(cglContext);
    }
    else if(application->isShuttingDown())
    {
        [appDelegate shutdown];
    }
    return kCVReturnSuccess;
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)application {
    [self go];
}

- (void)go {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    try {
        self.tutorialApplication->go();
        Ogre::Root::getSingleton().getRenderSystem()->_initRenderTargets();

        // Clear event times
        Ogre::Root::getSingleton().clearEventTimes();
    } catch( Ogre::Exception& e ) {
        std::cerr << "An exception has occurred: " <<
        e.getFullDescription().c_str() << std::endl;
    }

    // Setup close button
    OSXCocoaWindow *cocoaWindow = static_cast<OSXCocoaWindow *>(self.tutorialApplication->getWindow());
    NSWindow *window = cocoaWindow->ogreWindow();

    window.styleMask |= NSClosableWindowMask;

    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
    closeButton.target = self;
    closeButton.action = @selector(closeAction:);

    // Create a display link capable of being used with all active displays
    CVReturn ret = kCVReturnSuccess;
    ret = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);

    // Set the renderer output callback function
    ret = CVDisplayLinkSetOutputCallback(self.displayLink, &DisplayLinkCallback, self);

    // Set the display link for the current renderer
    NSOpenGLContext *ctx = cocoaWindow->nsopenGLContext();
    NSOpenGLPixelFormat *fmt = cocoaWindow->nsopenGLPixelFormat();
    CGLContextObj cglContext = (CGLContextObj)[ctx CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[fmt CGLPixelFormatObj];
    ret = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(self.displayLink, cglContext, cglPixelFormat);

    // Activate the display link
    ret = CVDisplayLinkStart(self.displayLink);
    
    [pool release];
}

- (void)shutdown {
    if(self.displayLink)
    {
        CVDisplayLinkStop(self.displayLink);
        CVDisplayLinkRelease(self.displayLink);
        self.displayLink = nil;
    }

    [NSApp terminate:nil];
}

- (void)closeAction:(id)sender {
    [self shutdown];
}

@end
