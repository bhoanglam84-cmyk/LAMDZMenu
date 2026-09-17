#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AimbotCore.h"
#import "ESPOverlay.h"

// ══ CONFIG ══
#define MENU_NAME   @"⚡ LAMDZ Menu"
// Đổi URL này sau khi deploy Railway
#define KEY_SERVER  @"https://lamdz-key.up.railway.app/verify"
#define STORAGE_KEY @"lamdz_key_verified"

extern void initAntiDetect();

static ESPOverlay   *espOverlay;

// ════════════════════
// Key Verify Online
// ════════════════════
void verifyKeyOnline(NSString *key,
    void(^cb)(BOOL ok, NSString *msg)) {
    NSString *urlStr = [NSString stringWithFormat:
        @"%@?key=%@", KEY_SERVER,
        [key stringByAddingPercentEncodingWithAllowedCharacters:
            NSCharacterSet.URLQueryAllowedCharacterSet]];
    NSURLSessionDataTask *task = [NSURLSession.sharedSession
        dataTaskWithURL:[NSURL URLWithString:urlStr]
        completionHandler:^(NSData *d, NSURLResponse *r,
                            NSError *e) {
            if (e || !d) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cb(NO, @"❌ Server offline");
                });
                return;
            }
            NSDictionary *json = [NSJSONSerialization
                JSONObjectWithData:d options:0 error:nil];
            BOOL valid = [json[@"valid"] boolValue];
            NSString *msg = json[@"msg"] ?: @"Unknown";
            dispatch_async(dispatch_get_main_queue(), ^{
                cb(valid, msg);
            });
        }];
    [task resume];
}

// ════════════════════
// Main Window
// ════════════════════
@interface LamdzWindow : UIWindow
@end

@implementation LamdzWindow {
    UIButton *_btn;
}

- (instancetype)init {
    self = [super initWithFrame:UIScreen.mainScreen.bounds];
    self.windowLevel = UIWindowLevelAlert + 200;
    self.backgroundColor = UIColor.clearColor;
    self.hidden = NO;

    // ESP overlay
    espOverlay = [[ESPOverlay alloc]
        initWithFrame:UIScreen.mainScreen.bounds];
    espOverlay.hidden = YES;
    [self addSubview:espOverlay];

    // Floating button
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    _btn.frame = CGRectMake(15, 180, 58, 58);
    _btn.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.92];
    _btn.layer.cornerRadius = 29;
    _btn.layer.borderWidth  = 2.5f;
    _btn.layer.borderColor  =
        [UIColor colorWithRed:1 green:0.2 blue:0.2 alpha:1].CGColor;
    [_btn setTitle:@"⚡" forState:UIControlStateNormal];
    _btn.titleLabel.font = [UIFont systemFontOfSize:22];
    [_btn addTarget:self action:@selector(onTap)
        forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(drag:)];
    [_btn addGestureRecognizer:pan];
    [self addSubview:_btn];
    return self;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self];
    g.view.center = CGPointMake(
        g.view.center.x + t.x,
        g.view.center.y + t.y);
    [g setTranslation:CGPointZero inView:self];
}

- (void)onTap {
    BOOL ok = [[NSUserDefaults standardUserDefaults]
        boolForKey:STORAGE_KEY];
    ok ? [self showMenu] : [self showKeyInput];
}

// ── Key Input ──
- (void)showKeyInput {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:MENU_NAME
        message:@"🔑 Nhập key để mở menu\n(Vượt link để lấy key)"
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"LAMDZ-XXXX-XXXX";
        tf.autocorrectionType = UITextAutocorrectionTypeNo;
        tf.autocapitalizationType =
            UITextAutocapitalizationTypeAllCharacters;
    }];
    [a addAction:[UIAlertAction
        actionWithTitle:@"✅ Verify"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *ac) {
            NSString *key = a.textFields.firstObject.text;
            [self verifyKey:key];
        }]];
    [a addAction:[UIAlertAction actionWithTitle:@"❌ Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:a animated:YES completion:nil];
    }];
}

- (void)verifyKey:(NSString *)key {
    UIAlertController *loading = [UIAlertController
        alertControllerWithTitle:@"⏳ Đang kiểm tra..."
        message:nil
        preferredStyle:UIAlertControllerStyleAlert];
    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:loading animated:YES completion:nil];
    }];
    verifyKeyOnline(key, ^(BOOL ok, NSString *msg) {
        [loading dismissViewControllerAnimated:YES completion:^{
            if (ok) {
                [[NSUserDefaults standardUserDefaults]
                    setBool:YES forKey:STORAGE_KEY];
                [[NSUserDefaults standardUserDefaults]
                    setObject:key forKey:@"lamdz_key_value"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showMenu];
            } else {
                UIAlertController *fail = [UIAlertController
                    alertControllerWithTitle:@"❌ Key không hợp lệ"
                    message:msg
                    preferredStyle:UIAlertControllerStyleAlert];
                [fail addAction:[UIAlertAction
                    actionWithTitle:@"OK"
                    style:UIAlertActionStyleDefault handler:nil]];
                [self topVC:^(UIViewController *vc) {
                    [vc presentViewController:fail
                        animated:YES completion:nil];
                }];
            }
        }];
    });
}

// ── Main Menu ──
- (void)showMenu {
    AimbotCore *aim = AimbotCore.shared;
    UIAlertController *menu = [UIAlertController
        alertControllerWithTitle:MENU_NAME
        message:@"Select feature"
        preferredStyle:UIAlertControllerStyleActionSheet];

    // Aimbot toggle
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"%@ Aimbot — %@ | FOV:%.0f°",
            aim.enabled ? @"✅":@"❌",
            aim.modeName, aim.fov]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            aim.enabled = !aim.enabled;
        }]];

    // Aim Mode selector
    [menu addAction:[UIAlertAction
        actionWithTitle:@"🎯 Aim Mode"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [self showAimModeSelector];
        }]];

    // FOV
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"📐 FOV — %.0f°", aim.fov]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [self showFOVPicker];
        }]];

    // Smooth
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"🌊 Smooth — %.2f", aim.smooth]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            [self showSmoothPicker];
        }]];

    // ESP
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"%@ ESP Wallhack",
            espOverlay.hidden ? @"❌":@"✅"]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            espOverlay.hidden = !espOverlay.hidden;
            if (!espOverlay.hidden) {
                [espOverlay updateEnemies:@[
                    @{@"rect":NSStringFromCGRect(
                        CGRectMake(120,200,80,160)),
                      @"hp":@0.75,@"dist":@45.5,
                      @"name":@"Enemy1"},
                    @{@"rect":NSStringFromCGRect(
                        CGRectMake(280,150,70,140)),
                      @"hp":@0.25,@"dist":@87.0,
                      @"name":@"Enemy2"}
                ]];
            }
        }]];

    // No Recoil
    static BOOL noRecoil = NO;
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"%@ No Recoil", noRecoil?@"✅":@"❌"]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            noRecoil = !noRecoil;
        }]];

    // Speed
    static BOOL speed = NO;
    [menu addAction:[UIAlertAction
        actionWithTitle:[NSString stringWithFormat:
            @"%@ Speed Hack", speed?@"✅":@"❌"]
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            speed = !speed;
        }]];

    // Logout
    [menu addAction:[UIAlertAction
        actionWithTitle:@"🔓 Logout Key"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction *a) {
            [[NSUserDefaults standardUserDefaults]
                setBool:NO forKey:STORAGE_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }]];

    [menu addAction:[UIAlertAction
        actionWithTitle:@"❌ Close"
        style:UIAlertActionStyleCancel handler:nil]];

    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:menu
            animated:YES completion:nil];
    }];
}

// ── Aim Mode ──
- (void)showAimModeSelector {
    UIAlertController *s = [UIAlertController
        alertControllerWithTitle:@"🎯 Aim Mode"
        message:@"Chọn vị trí aim"
        preferredStyle:UIAlertControllerStyleActionSheet];
    NSDictionary *modes = @{
        @"💀 Head  — Headshot max dmg": @(AimModeHead),
        @"🦴 Neck  — Stable, high dmg": @(AimModeNeck),
        @"🫁 Body  — Easy hit, lag ok": @(AimModeBody),
    };
    for (NSString *t in modes) {
        AimMode m = [modes[t] integerValue];
        BOOL cur = (AimbotCore.shared.mode == m);
        [s addAction:[UIAlertAction
            actionWithTitle:cur ?
                [NSString stringWithFormat:@"✅ %@",t] : t
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a) {
                AimbotCore.shared.mode = m;
            }]];
    }
    [s addAction:[UIAlertAction actionWithTitle:@"❌ Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:s animated:YES completion:nil];
    }];
}

// ── FOV Picker ──
- (void)showFOVPicker {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"📐 Set FOV"
        message:@"10° - 180°"
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.placeholder = [NSString stringWithFormat:
            @"%.0f", AimbotCore.shared.fov];
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"Set"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *ac) {
            float v = [a.textFields.firstObject.text floatValue];
            if (v >= 10 && v <= 180)
                AimbotCore.shared.fov = v;
        }]];
    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:a animated:YES completion:nil];
    }];
}

// ── Smooth Picker ──
- (void)showSmoothPicker {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"🌊 Set Smooth"
        message:@"0.05=instant  1.0=chậm"
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeDecimalPad;
        tf.placeholder = [NSString stringWithFormat:
            @"%.2f", AimbotCore.shared.smooth];
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"Set"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *ac) {
            float v = [a.textFields.firstObject.text floatValue];
            if (v >= 0.01f && v <= 1.0f)
                AimbotCore.shared.smooth = v;
        }]];
    [self topVC:^(UIViewController *vc) {
        [vc presentViewController:a animated:YES completion:nil];
    }];
}

// ── Helper ──
- (void)topVC:(void(^)(UIViewController*))cb {
    UIViewController *vc =
        UIApplication.sharedApplication.keyWindow.rootViewController;
    while (vc.presentedViewController)
        vc = vc.presentedViewController;
    cb(vc);
}

@end

// ════════════════════
// Constructor
// ════════════════════
static LamdzWindow *menuWindow;

__attribute__((constructor))
static void lamdzInit() {
    initAntiDetect();
    double delay = 1.5 + (arc4random_uniform(25)/10.0);
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(delay * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            menuWindow = [[LamdzWindow alloc] init];
            [menuWindow makeKeyAndVisible];
        });
}
