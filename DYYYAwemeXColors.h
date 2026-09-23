#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Opt-in adapter: leaves DYYY's global random/gradient schemes unchanged.
@interface DYYYAwemeXColors : NSObject
+ (UIColor *)randomDanmakuColor;
// Called only for the publication/IP label, including IP lookup completions.
// Reads current preferences; never applies a color captured by an old request.
+ (void)applyTimestampColorToLabel:(nullable UILabel *)label;
// Cheap associated-state check for other UILabels; repairs only managed masks.
+ (void)layoutTimestampLabel:(UILabel *)label;
+ (void)refreshTimestampLabels;
@end

NS_ASSUME_NONNULL_END
