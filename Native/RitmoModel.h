#import <Foundation/Foundation.h>
#import "RitmoCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface RitmoModel : NSObject
@property(nonatomic) double monthlyBudget;
@property(nonatomic, copy, readonly) NSDate *referenceDate;
@property(nonatomic, strong, readonly) NSCalendar *calendar;
@property(nonatomic, readonly) NSArray<RTHoliday *> *automaticHolidaysThisMonth;
@property(nonatomic, readonly) NSArray<NSDate *> *extraDaysOffThisMonth;
@property(nonatomic, readonly) NSSet<NSDate *> *activeHolidays;
@property(nonatomic, readonly) NSArray<NSDate *> *businessDays;
@property(nonatomic, readonly) RTSpendingSnapshot *snapshot;
- (BOOL)updateReferenceDateToToday;
- (BOOL)isAutomaticHolidayEnabled:(RTHoliday *)holiday;
- (void)setAutomaticHoliday:(RTHoliday *)holiday enabled:(BOOL)enabled;
- (void)addExtraDayOff:(NSDate *)date;
- (void)removeExtraDayOff:(NSDate *)date;
@end

NS_ASSUME_NONNULL_END
