#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    [infoDict setValue: @"com.revolverolver.flipmania" forKey: @"CFBundleIdentifier"];
    
    [GeneratedPluginRegistrant registerWithRegistry: self];
    
    // Override point for customization after application launch.
    return [super application: application didFinishLaunchingWithOptions: launchOptions];
}

@end
