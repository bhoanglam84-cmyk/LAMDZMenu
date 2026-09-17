#import "AimbotCore.h"

@implementation AimbotCore

+ (instancetype)shared {
    static AimbotCore *i;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ i = [AimbotCore new]; });
    return i;
}

- (instancetype)init {
    self = [super init];
    _enabled = NO;
    _mode    = AimModeHead;
    _fov     = 80.0f;
    _smooth  = 0.15f;
    return self;
}

- (NSString *)modeName {
    switch (_mode) {
        case AimModeHead: return @"💀 Head";
        case AimModeNeck: return @"🦴 Neck";
        case AimModeBody: return @"🫁 Body";
    }
}

- (CGPoint)targetPointFromEnemy:(NSDictionary *)enemy
                     screenSize:(CGSize)screen {
    CGRect body = CGRectFromString(enemy[@"rect"]);
    CGPoint target;
    switch (_mode) {
        case AimModeHead:
            target = CGPointMake(CGRectGetMidX(body),
                body.origin.y + body.size.height * 0.08f);
            break;
        case AimModeNeck:
            target = CGPointMake(CGRectGetMidX(body),
                body.origin.y + body.size.height * 0.22f);
            break;
        case AimModeBody:
            target = CGPointMake(CGRectGetMidX(body),
                body.origin.y + body.size.height * 0.45f);
            break;
    }
    CGPoint center = CGPointMake(screen.width/2, screen.height/2);
    float dx = target.x - center.x;
    float dy = target.y - center.y;
    float dist = sqrtf(dx*dx + dy*dy);
    float fovRadius = (screen.width/2.0f) *
        tanf(_fov * M_PI / 180.0f / 2.0f);
    if (dist > fovRadius) return CGPointMake(-1,-1);
    return CGPointMake(
        center.x + (target.x - center.x) * _smooth,
        center.y + (target.y - center.y) * _smooth
    );
}
@end
