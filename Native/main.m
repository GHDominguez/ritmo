#import <Cocoa/Cocoa.h>
#import "RitmoModel.h"
#import "RitmoUI.h"

@interface RitmoAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) RitmoModel *model;
@property(nonatomic, strong) RitmoViewController *controller;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSTimer *dayRefreshTimer;
@end

@implementation RitmoAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.model = [[RitmoModel alloc] init];
    self.controller = [[RitmoViewController alloc] initWithModel:self.model];
    NSRect frame = NSMakeRect(0, 0, 1000, 650);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                             styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    self.window.releasedWhenClosed = NO;
    self.window.title = @"Ritmo";
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;
    self.window.minSize = NSMakeSize(900, 650);
    self.window.contentViewController = self.controller;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(snapshotDidChange:)
                                               name:@"RitmoSnapshotDidChange"
                                             object:self.model];
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.target = self;
    self.statusItem.button.action = @selector(toggleWindow:);
    self.statusItem.button.font = [NSFont monospacedDigitSystemFontOfSize:13 weight:NSFontWeightSemibold];
    self.statusItem.button.toolTip = @"Límite acumulado para hoy · clic para abrir Ritmo";
    [self updateStatusItem];
    self.dayRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                            target:self
                                                          selector:@selector(refreshCurrentDate:)
                                                          userInfo:nil
                                                           repeats:YES];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(refreshCurrentDate:)
                                               name:NSCalendarDayChangedNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(refreshCurrentDate:)
                                               name:NSSystemClockDidChangeNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(refreshCurrentDate:)
                                               name:NSSystemTimeZoneDidChangeNotification
                                             object:nil];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];

    NSString *snapshotPath = NSProcessInfo.processInfo.environment[@"RITMO_SNAPSHOT_PATH"];
    if (snapshotPath.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSView *view = self.window.contentView;
            NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
            [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
            NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [png writeToFile:snapshotPath atomically:YES];
            [NSApp terminate:nil];
        });
    }
}

- (void)snapshotDidChange:(NSNotification *)notification {
    [self updateStatusItem];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self refreshCurrentDate:notification];
}

- (void)refreshCurrentDate:(id)sender {
    if ([self.model updateReferenceDateToToday]) {
        [self.controller refresh];
    }
}

- (void)updateStatusItem {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"es_AR"];
    formatter.currencySymbol = @"$";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    NSString *(^compactCurrency)(double) = ^NSString *(double value) {
        NSString *text = [formatter stringFromNumber:@(value)] ?: @"$0";
        text = [text stringByReplacingOccurrencesOfString:@"\u00a0" withString:@""];
        return [text stringByReplacingOccurrencesOfString:@" " withString:@""];
    };
    NSString *limit = compactCurrency(self.model.snapshot.allowedThroughDate);
    self.statusItem.button.title = limit;
    self.statusItem.button.accessibilityLabel = [NSString stringWithFormat:@"Límite acumulado para hoy: %@", limit];
}

- (void)toggleWindow:(id)sender {
    if (self.window.isKeyWindow) {
        [self.window orderOut:nil];
        return;
    }
    if (self.window.isMiniaturized) [self.window deminiaturize:nil];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return NO; }
@end

static void RTInstallMainMenu(void) {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    NSMenuItem *appItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Ritmo"];
    [appMenu addItemWithTitle:@"Acerca de Ritmo" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Ocultar Ritmo" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItemWithTitle:@"Salir de Ritmo" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    NSApp.mainMenu = mainMenu;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        application.activationPolicy = NSApplicationActivationPolicyRegular;
        application.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
        RTInstallMainMenu();
        RitmoAppDelegate *delegate = [[RitmoAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
