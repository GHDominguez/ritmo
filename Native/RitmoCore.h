#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSpendingSnapshot : NSObject
@property(nonatomic, readonly) double monthlyBudget;
@property(nonatomic, readonly) double dailyAllowance;
@property(nonatomic, readonly) double allowedThroughDate;
@property(nonatomic, readonly) NSInteger totalBusinessDays;
@property(nonatomic, readonly) NSInteger elapsedBusinessDays;
@property(nonatomic, readonly) double remainingBudget;
- (instancetype)initWithBudget:(double)budget
                dailyAllowance:(double)dailyAllowance
             allowedThroughDate:(double)allowedThroughDate
             totalBusinessDays:(NSInteger)totalBusinessDays
           elapsedBusinessDays:(NSInteger)elapsedBusinessDays;
@end

@interface RTHoliday : NSObject
@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, copy, readonly) NSDate *date;
- (instancetype)initWithName:(NSString *)name date:(NSDate *)date;
@end

@interface RTCalendarEngine : NSObject
+ (NSArray<NSDate *> *)businessDaysInMonthContaining:(NSDate *)date
                                            holidays:(NSSet<NSDate *> *)holidays
                                            calendar:(NSCalendar *)calendar;
+ (RTSpendingSnapshot *)snapshotForBudget:(double)budget
                              throughDate:(NSDate *)date
                                 holidays:(NSSet<NSDate *> *)holidays
                                 calendar:(NSCalendar *)calendar;
+ (NSArray<RTHoliday *> *)argentinaHolidaysForYear:(NSInteger)year
                                           calendar:(NSCalendar *)calendar;
@end

NS_ASSUME_NONNULL_END
