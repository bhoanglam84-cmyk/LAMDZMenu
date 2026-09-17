#import "ESPOverlay.h"

@implementation ESPOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = NO;
    _enemies = [NSMutableArray new];
    CADisplayLink *link = [CADisplayLink
        displayLinkWithTarget:self selector:@selector(tick)];
    [link addToRunLoop:NSRunLoop.mainRunLoop
               forMode:NSRunLoopCommonModes];
    return self;
}

- (void)tick { [self setNeedsDisplay]; }

- (void)updateEnemies:(NSArray *)list {
    _enemies = [list mutableCopy];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    for (NSDictionary *enemy in _enemies) {
        CGRect box   = CGRectFromString(enemy[@"rect"]);
        float  hp    = [enemy[@"hp"] floatValue];
        float  dist  = [enemy[@"dist"] floatValue];
        NSString *name = enemy[@"name"] ?: @"Enemy";

        UIColor *color;
        if (hp > 0.6f)      color = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.9];
        else if (hp > 0.3f) color = [UIColor colorWithRed:1 green:1 blue:0 alpha:0.9];
        else                color = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.9];

        // Box
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        CGContextSetLineWidth(ctx, 1.8f);
        CGContextStrokeRect(ctx, box);

        // Corners
        float len = MIN(box.size.width, box.size.height) * 0.2f;
        CGContextSetLineWidth(ctx, 2.5f);
        // TL
        CGContextMoveToPoint(ctx, box.origin.x, box.origin.y + len);
        CGContextAddLineToPoint(ctx, box.origin.x, box.origin.y);
        CGContextAddLineToPoint(ctx, box.origin.x + len, box.origin.y);
        // TR
        CGContextMoveToPoint(ctx, CGRectGetMaxX(box)-len, box.origin.y);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(box), box.origin.y);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(box), box.origin.y+len);
        // BL
        CGContextMoveToPoint(ctx, box.origin.x, CGRectGetMaxY(box)-len);
        CGContextAddLineToPoint(ctx, box.origin.x, CGRectGetMaxY(box));
        CGContextAddLineToPoint(ctx, box.origin.x+len, CGRectGetMaxY(box));
        // BR
        CGContextMoveToPoint(ctx, CGRectGetMaxX(box)-len, CGRectGetMaxY(box));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(box), CGRectGetMaxY(box));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(box), CGRectGetMaxY(box)-len);
        CGContextStrokePath(ctx);

        // HP Bar
        CGRect hpBg = CGRectMake(box.origin.x-6, box.origin.y, 4, box.size.height);
        CGRect hpBar = CGRectMake(box.origin.x-6,
            box.origin.y + box.size.height*(1-hp),
            4, box.size.height*hp);
        CGContextSetFillColorWithColor(ctx,
            [UIColor colorWithWhite:0 alpha:0.5].CGColor);
        CGContextFillRect(ctx, hpBg);
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        CGContextFillRect(ctx, hpBar);

        // Snapline
        CGContextSetStrokeColorWithColor(ctx,
            [UIColor colorWithWhite:1 alpha:0.3].CGColor);
        CGContextSetLineWidth(ctx, 0.8f);
        CGContextMoveToPoint(ctx, rect.size.width/2, rect.size.height);
        CGContextAddLineToPoint(ctx,
            CGRectGetMidX(box), CGRectGetMaxY(box));
        CGContextStrokePath(ctx);

        // Label
        NSString *label = [NSString stringWithFormat:
            @"%@ %.0fm", name, dist];
        NSDictionary *attrs = @{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:9],
            NSForegroundColorAttributeName: UIColor.whiteColor,
            NSBackgroundColorAttributeName:
                [UIColor colorWithWhite:0 alpha:0.4]
        };
        [label drawAtPoint:CGPointMake(box.origin.x,
            box.origin.y-13) withAttributes:attrs];
    }
}
@end
