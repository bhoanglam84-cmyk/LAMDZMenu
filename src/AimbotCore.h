#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AimMode) {
    AimModeHead = 0,
    AimModeNeck = 1,
    AimModeBody = 2,
};

@interface AimbotCore : NSObject
@property (nonatomic, assign) BOOL     enabled;
@property (nonatomic, assign) AimMode  mode;
@property (nonatomic, assign) float    fov;
@property (nonatomic, assign) float    smooth;
+ (instancetype)shared;
- (NSString *)modeName;
- (CGPoint)targetPointFromEnemy:(NSDictionary *)enemy
                     screenSize:(CGSize)screen;
@end
