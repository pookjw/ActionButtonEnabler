#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <cstring>
#import <algorithm>
#import <ranges>
#import <substrate.h>

namespace AE_SBHomeHardwareButton {
    namespace singlePressUp {
        void custom(id self, SEL _cmd, UIPressesEvent *event) {
            // SBSystemActionControl
            id systemActionControl = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)([UIApplication sharedApplication], NSSelectorFromString(@"systemActionControl"));

            // SBRingerHardwareButton
            id ringerHardwareButton = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)([UIApplication sharedApplication], NSSelectorFromString(@"ringerHardwareButton"));

            // SBSystemActionSuppressionManager
            unsigned int ivarsCount;
            Ivar *ivars = class_copyIvarList([ringerHardwareButton class], &ivarsCount);
            
            auto ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
                auto name = ivar_getName(ivar);
                return !std::strcmp(name, "_suppressionManager");
            });
            
            uintptr_t base = reinterpret_cast<uintptr_t>(ringerHardwareButton);
            ptrdiff_t offset = ivar_getOffset(*ivar);
            delete ivars;
        
            auto location = reinterpret_cast<void *>(base + offset);
            id suppressionManager = *static_cast<id *>(location);
            
            MSImageRef image = MSGetImageByName("/System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard");
            auto f1 = reinterpret_cast<id (*)(id)>(MSFindSymbol(image, "-[SBSystemActionSuppressionManager suppressionStatus]"));
            auto f2 = reinterpret_cast<void (*)(id, id, id)>(MSFindSymbol(image, "-[SBSystemActionControl previewSelectedActionFromSource:withSuppressionStatus:]"));

            //

            id suppressionStatus = f1(suppressionManager);
            f2(systemActionControl, @"SBRingerHardwareButton", suppressionStatus);
        }
    }

    namespace longPress {
        void custom(id self, SEL _cmd, UIPressesEvent *event) {
            // SBSystemActionControl
            id systemActionControl = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)([UIApplication sharedApplication], NSSelectorFromString(@"systemActionControl"));

            // SBRingerHardwareButton
            id ringerHardwareButton = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)([UIApplication sharedApplication], NSSelectorFromString(@"ringerHardwareButton"));

            // SBSystemActionSuppressionManager
            unsigned int ivarsCount;
            Ivar *ivars = class_copyIvarList([ringerHardwareButton class], &ivarsCount);
            
            auto ivar = std::ranges::find_if(ivars, ivars + ivarsCount, [](Ivar ivar) {
                auto name = ivar_getName(ivar);
                return !std::strcmp(name, "_suppressionManager");
            });
            
            uintptr_t base = reinterpret_cast<uintptr_t>(ringerHardwareButton);
            ptrdiff_t offset = ivar_getOffset(*ivar);
            delete ivars;
        
            auto location = reinterpret_cast<void *>(base + offset);
            id suppressionManager = *static_cast<id *>(location);
            
            MSImageRef image = MSGetImageByName("/System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard");
            auto f1 = reinterpret_cast<id (*)(id)>(MSFindSymbol(image, "-[SBSystemActionSuppressionManager suppressionStatus]"));
            auto f2 = reinterpret_cast<void (*)(id, id, id)>(MSFindSymbol(image, "-[SBSystemActionControl previewSelectedActionFromSource:withSuppressionStatus:]"));
            auto f3 = reinterpret_cast<void (*)(id, id, id)>(MSFindSymbol(image, "-[SBSystemActionControl performSelectedActionFromSource:withContext:]"));
            auto f4 = reinterpret_cast<id (*)(id, id, long, id)>(MSFindSymbol(image, "-[SBSystemActionInteractionContext initWithPreciseTimestamp:type:suppressionStatus:]"));

            //

            id suppressionStatus = f1(suppressionManager);
            f2(systemActionControl, @"SBRingerHardwareButton", suppressionStatus);
            id context = f4([NSClassFromString(@"SBSystemActionInteractionContext") alloc], [NSDate now], 0, suppressionStatus);
            f3(systemActionControl, @"SBRingerHardwareButton", context);
            [context release];
        }
    }
}

namespace AE_os_feature_enabled_impl {
    BOOL (*original)(const char *arg0, const char *arg1);
    BOOL custom(const char *arg0, const char *arg1) {
        if (!std::strcmp(arg0, "SpringBoard") && !std::strcmp(arg1, "ButtonInteractionClassic")) {
            return YES;
        } else {
            return original(arg0, arg1);
        }
    }
}

namespace AE_BSSimpleAssertion {
    namespace dealloc {
        void (*original)(id self, SEL _cmd);
        void custom(id self, SEL _cmd) {
            // SpringBoard tries to dealloc BSSimpleAssertion without invalidating. This will occur assertion.
            if (reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(self, NSSelectorFromString(@"isValid"))) {
                reinterpret_cast<void (*)(id, SEL)>(objc_msgSend)(self, NSSelectorFromString(@"invalidate"));
            }
            
            original(self, _cmd);
        }
    }
}

__attribute__((constructor)) static void init() {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    void *handle = dlopen("/usr/lib/system/libsystem_featureflags.dylib", RTLD_NOW);
    void *symbol = dlsym(handle, "_os_feature_enabled_impl");
    MSHookFunction(symbol, reinterpret_cast<void *>(&AE_os_feature_enabled_impl::custom), reinterpret_cast<void **>(&AE_os_feature_enabled_impl::original));
    dlclose(handle);

    MSHookMessageEx(
        NSClassFromString(@"SBHomeHardwareButton"),
        NSSelectorFromString(@"singlePressUp:"),
        reinterpret_cast<IMP>(&AE_SBHomeHardwareButton::singlePressUp::custom),
        nullptr
    );

    MSHookMessageEx(
        NSClassFromString(@"SBHomeHardwareButton"),
        NSSelectorFromString(@"longPress:"),
        reinterpret_cast<IMP>(&AE_SBHomeHardwareButton::longPress::custom),
        nullptr
    );

    MSHookMessageEx(
        NSClassFromString(@"BSSimpleAssertion"),
        NSSelectorFromString(@"dealloc"),
        reinterpret_cast<IMP>(&AE_BSSimpleAssertion::dealloc::custom),
        reinterpret_cast<IMP *>(&AE_BSSimpleAssertion::dealloc::original)
    );

    [pool release];
}
