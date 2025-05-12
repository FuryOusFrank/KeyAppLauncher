/*
 KeyLaunchApp
 GNUstep application to launch a command with temporary 'us' keyboard layout,
 then revert to the full original XKB state after 2 seconds.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface KeyLaunchApp : NSObject
@end

@implementation KeyLaunchApp

- (void)launchWithTemporaryUSLayout:(NSString *)command {
    NSString *backupFile = @"/tmp/xkb-layout.bak";

    // Sauvegarder la configuration complète actuelle du clavier
    NSLog(@"[KeyLaunch] Saving current XKB config");
    system([[NSString stringWithFormat:@"xkbcomp $DISPLAY %@", backupFile] UTF8String]);

    // Appliquer temporairement le clavier 'us'
    NSLog(@"[KeyLaunch] Setting layout to 'us'");
    system("setxkbmap us");

    // Lancer l'application en arrière-plan
    NSLog(@"[KeyLaunch] Launching: %@", command);
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", command]];
    [task launch];

    // Restaurer le fichier XKB après 2 secondes avec NSTimer
    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     repeats:NO
                                       block:^(NSTimer * _Nonnull timer) {
        NSLog(@"[KeyLaunch] Restoring original XKB layout");
        system([[NSString stringWithFormat:@"xkbcomp %@ $DISPLAY", backupFile] UTF8String]);
    }];
}

@end

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (argc < 2) {
        NSLog(@"Usage: KeyLaunchApp <command to launch>");
        return 1;
    }

    NSMutableArray *args = [NSMutableArray arrayWithCapacity:argc - 1];
    for (int i = 1; i < argc; i++) {
        [args addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    NSString *command = [args componentsJoinedByString:@" "];

    KeyLaunchApp *app = [[KeyLaunchApp alloc] init];
    [app launchWithTemporaryUSLayout:command];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];

    [pool drain];
    return 0;
}

