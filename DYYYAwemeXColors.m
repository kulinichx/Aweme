#import "DYYYAwemeXColors.h"
#import "DYYYAwemeXPalette.h"
#import "DYYYUtils.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>
#import <stdlib.h>

static const void *kDYYYAwemeXTimestampStateKey = &kDYYYAwemeXTimestampStateKey;
static NSHashTable<UILabel *> *DYYYAwemeXTimestampLabels;

@interface DYYYAwemeXTimestampState : NSObject
@property(nonatomic, strong) CAGradientLayer *gradient;
@property(nonatomic, copy) NSArray *colors;
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSAttributedString *attributedText;
@property(nonatomic, strong) UIFont *font;
@property(nonatomic, strong) UIColor *textColor;
@property(nonatomic, assign) CGRect bounds;
@property(nonatomic, assign) BOOL needsPalette;
@property(nonatomic, assign) BOOL rendering;
@end
@implementation DYYYAwemeXTimestampState
@end

@interface DYYYAwemeXColors ()
+ (void)renderLabel:(UILabel *)label state:(DYYYAwemeXTimestampState *)state;
@end

static BOOL DYYYAwemeXGradientEnabled(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"DYYYEnableArea"] && [defaults boolForKey:@"DYYYAwemeXTimestampGradient"];
}

static void DYYYAwemeXRemoveGradient(DYYYAwemeXTimestampState *state) {
    [state.gradient removeFromSuperlayer];
    state.gradient = nil;
}

@implementation DYYYAwemeXColors

+ (UIColor *)randomDanmakuColor {
    // AwemeX 0x2c9594: three independent uniform(128) draws, not HSV/rainbow.
    double red = DYYYAwemeXDanmakuChannel(arc4random_uniform(128));
    double green = DYYYAwemeXDanmakuChannel(arc4random_uniform(128));
    double blue = DYYYAwemeXDanmakuChannel(arc4random_uniform(128));
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

+ (void)applyTimestampColorToLabel:(UILabel *)label {
    if (!label) return;
    if (![NSThread isMainThread]) {
        __weak UILabel *weakLabel = label;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self applyTimestampColorToLabel:weakLabel];
        });
        return;
    }

    DYYYAwemeXTimestampState *state = objc_getAssociatedObject(label, kDYYYAwemeXTimestampStateKey);
    if (state.rendering) return;
    if (!state) {
        state = [DYYYAwemeXTimestampState new];
        objc_setAssociatedObject(label, kDYYYAwemeXTimestampStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ DYYYAwemeXTimestampLabels = [NSHashTable weakObjectsHashTable]; });
        [DYYYAwemeXTimestampLabels addObject:label];
    }

    if (DYYYAwemeXGradientEnabled()) {
        // Ordinary getter/IP-completion applications draw a new palette.
        // Layout-only repairs reuse it to avoid introducing per-frame flicker.
        state.needsPalette = YES;
        [self renderLabel:label state:state];
        if (!state.gradient) [label setNeedsLayout];
        return;
    }

    // Compatibility repair: remove only our own layer, never App-owned layers.
    DYYYAwemeXRemoveGradient(state);
    state.colors = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"DYYYEnableArea"]) return;
    NSString *scheme = nil; // DYYYLabelColor hex input removed; nil = white.
    if ([defaults boolForKey:@"DYYYEnableRandomGradient"]) scheme = @"random_gradient";
    [DYYYUtils applyColorSettingsToLabel:label colorHexString:scheme];
}

+ (void)layoutTimestampLabel:(UILabel *)label {
    if (![NSThread isMainThread]) return;
    DYYYAwemeXTimestampState *state = objc_getAssociatedObject(label, kDYYYAwemeXTimestampStateKey);
    if (!state || state.rendering) return;
    if (!DYYYAwemeXGradientEnabled()) {
        if (state.gradient || state.colors) [self applyTimestampColorToLabel:label];
        return;
    }

    BOOL sameText = [state.text isEqualToString:label.text ?: @""];
    BOOL sameAttributes = state.attributedText == label.attributedText ||
        (state.attributedText && label.attributedText && [state.attributedText isEqualToAttributedString:label.attributedText]);
    BOOL sameFont = state.font == label.font || [state.font isEqual:label.font];
    BOOL sameColor = state.textColor == label.textColor || [state.textColor isEqual:label.textColor];
    if (state.gradient.superlayer == label.layer && CGRectEqualToRect(state.bounds, label.bounds) &&
        sameText && sameAttributes && sameFont && sameColor && !state.needsPalette) return;
    [self renderLabel:label state:state];
}

+ (void)renderLabel:(UILabel *)label state:(DYYYAwemeXTimestampState *)state {
    if (state.rendering) return;
    CGRect bounds = label.bounds;
    CGFloat scale = label.window.screen.scale ?: [UIScreen mainScreen].scale;
    // Do not copy AwemeX's unbounded main-queue retry on an empty label.
    // A subsequent real layout/getter will retry; invalid sizes keep native text.
    if (CGRectIsEmpty(bounds) || !isfinite(bounds.size.width) || !isfinite(bounds.size.height) ||
        bounds.size.width * bounds.size.height * scale * scale > 16.0 * 1024.0 * 1024.0 ||
        (label.text.length == 0 && label.attributedText.length == 0)) {
        DYYYAwemeXRemoveGradient(state);
        return;
    }

    state.rendering = YES;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    BOOL contextOpen = NO;
    @try {
        DYYYAwemeXRemoveGradient(state);
        if (state.needsPalette || state.colors.count == 0) {
            uint32_t count = DYYYAwemeXGradientStopCount(arc4random_uniform(2));
            NSMutableArray *colors = [NSMutableArray arrayWithCapacity:count];
            for (uint32_t i = 0; i < count; ++i) {
                // AwemeX 0x2e6988: preserve masks, divisor 256, and modulo 102.
                double hue = DYYYAwemeXGradientHue(arc4random());
                double saturation = DYYYAwemeXGradientSaturation(arc4random());
                double brightness = DYYYAwemeXGradientBrightness(arc4random());
                UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
                [colors addObject:(__bridge id)color.CGColor];
            }
            state.colors = colors;
            state.needsPalette = NO;
        }

        // Same core rendering as AwemeX 0x2ccdd0: existing layer alpha -> mask.
        // Do NOT hide the label or clear/force-white its original text first.
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0.0);
        contextOpen = YES;
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) return;
        [label.layer renderInContext:context];
        UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        contextOpen = NO;
        if (!snapshot.CGImage) return;

        CALayer *mask = [CALayer layer];
        mask.contents = (__bridge id)snapshot.CGImage;
        mask.frame = bounds;
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.name = @"DYYY.AwemeX.TimestampGradient";
        gradient.frame = bounds;
        gradient.startPoint = CGPointMake(0.0, 0.5);
        gradient.endPoint = CGPointMake(1.0, 0.5);
        gradient.colors = state.colors;
        if (state.colors.count == 3) gradient.locations = @[@0, @0.5, @1];
        gradient.mask = mask;
        [label.layer addSublayer:gradient];
        state.gradient = gradient;
        state.bounds = bounds;
        state.text = label.text ?: @"";
        state.attributedText = label.attributedText;
        state.font = label.font;
        state.textColor = label.textColor;
    } @catch (NSException *exception) {
        // A rendering failure must not remove native text or break playback.
        DYYYAwemeXRemoveGradient(state);
        NSLog(@"[DYYY/AwemeX] Timestamp mask skipped: %@", exception.name);
    } @finally {
        if (contextOpen) UIGraphicsEndImageContext();
        [CATransaction commit];
        state.rendering = NO;
    }
}

+ (void)refreshTimestampLabels {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self refreshTimestampLabels]; });
        return;
    }
    for (UILabel *label in DYYYAwemeXTimestampLabels.allObjects) {
        [self applyTimestampColorToLabel:label];
    }
}
@end
