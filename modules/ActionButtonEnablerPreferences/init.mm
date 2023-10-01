#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <substrate.h>
#import <cstdint>

namespace AE_PSUIPrefsListController {
    namespace viewDidLoad {
        void (*original)(__kindof UIViewController *self, SEL _cmd);
        void custom(__kindof UIViewController *self, SEL _cmd) {
            original(self, _cmd);

            NSMutableArray<UIBarButtonItemGroup *> *leadingItemGroups = [self.navigationItem.leadingItemGroups mutableCopy];

            __block auto retainedSelf = self;
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithPrimaryAction:[UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"button.programmable"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                __kindof UIViewController *actionButtonSettings = [NSClassFromString(@"ActionButtonSettings") new];
                [retainedSelf presentViewController:actionButtonSettings animated:YES completion:nil];
                [actionButtonSettings release];
            }]];
            
            UIBarButtonItemGroup *group = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[item] representativeItem:nil];
            [item release];
            
            [leadingItemGroups addObject:group];
            [group release];
            
            self.navigationItem.leadingItemGroups = leadingItemGroups;
            [leadingItemGroups release];
        }
    }
}

namespace AE_NSBundle {
    namespace URLForResource_withExtension {
        NSURL *(*original)(NSBundle *self, SEL _cmd, NSString *name, NSString *text);
        NSURL *custom(NSBundle *self, SEL _cmd, NSString *name, NSString *text) {
            if (![self.bundleIdentifier isEqualToString:@"com.apple.settingsandcoreapps.ActionButtonSelector"]) {
                return original(self, _cmd, name, text);
            }

            if ([name isEqualToString:@"iPhone15_Pro_NaturalTitanium_v0005-D83-D84"] && [text isEqualToString:@"usdz"]) {
                return [NSURL fileURLWithPath:@"/var/jb/Library/Application Support/ActionButtonEnabler/iPhone15_Pro_NaturalTitanium_v0005-D83-D84.usdz"];
            } else if ([name isEqualToString:@"Action_Button_glow_modifier-D83-D84"] && [text isEqualToString:@"txt"]) {
                return [NSURL fileURLWithPath:@"/var/jb/Library/Application Support/ActionButtonEnabler/Action_Button_glow_modifier-D83-D84.txt"];
            } else {
                return original(self, _cmd, name, text);
            }
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    dlopen("/System/Library/PreferenceBundles/ActionButtonSettings.bundle/ActionButtonSettings", RTLD_NOW);

    MSHookMessageEx(
        NSClassFromString(@"PSUIPrefsListController"),
        @selector(viewDidLoad),
        reinterpret_cast<IMP>(&AE_PSUIPrefsListController::viewDidLoad::custom),
        reinterpret_cast<IMP *>(&AE_PSUIPrefsListController::viewDidLoad::original)
    );

    MSHookMessageEx(
        NSBundle.class,
        @selector(URLForResource:withExtension:),
        reinterpret_cast<IMP>(&AE_NSBundle::URLForResource_withExtension::custom),
        reinterpret_cast<IMP *>(&AE_NSBundle::URLForResource_withExtension::original)
    );

    [pool release];
}
