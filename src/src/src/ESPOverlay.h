#import <UIKit/UIKit.h>
@interface ESPOverlay : UIView
@property (nonatomic, strong) NSMutableArray *enemies;
- (void)updateEnemies:(NSArray *)list;
@end
