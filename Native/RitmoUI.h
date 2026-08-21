#import <Cocoa/Cocoa.h>
#import "RitmoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RitmoViewController : NSViewController
- (instancetype)initWithModel:(RitmoModel *)model;
- (void)refresh;
@end

NS_ASSUME_NONNULL_END
