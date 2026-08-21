#import "RitmoModel.h"

static NSString *const RTBudgetKey = @"monthlyBudget";
static NSString *const RTExtraDaysKey = @"extraDaysOff";
static NSString *const RTIgnoredHolidaysKey = @"ignoredAutomaticHolidays";

@interface RitmoModel ()
@property(nonatomic, copy, readwrite) NSDate *referenceDate;
@property(nonatomic, strong) NSMutableSet<NSDate *> *extraDaysOff;
@property(nonatomic, strong) NSMutableSet<NSDate *> *ignoredAutomaticHolidays;
@end

@implementation RitmoModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        _calendar.locale = [NSLocale localeWithLocaleIdentifier:@"es_AR"];
        _calendar.timeZone = NSTimeZone.localTimeZone;
        _referenceDate = [_calendar startOfDayForDate:NSDate.date];

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        _monthlyBudget = [defaults objectForKey:RTBudgetKey] ? [defaults doubleForKey:RTBudgetKey] : 750.0;
        _extraDaysOff = [[self datesFromStoredStrings:[defaults stringArrayForKey:RTExtraDaysKey] ?: @[]] mutableCopy];
        _ignoredAutomaticHolidays = [[self datesFromStoredStrings:[defaults stringArrayForKey:RTIgnoredHolidaysKey] ?: @[]] mutableCopy];
    }
    return self;
}

- (BOOL)updateReferenceDateToToday {
    self.calendar.timeZone = NSTimeZone.localTimeZone;
    NSDate *today = [self.calendar startOfDayForDate:NSDate.date];
    if ([self.calendar isDate:today inSameDayAsDate:self.referenceDate]) return NO;
    self.referenceDate = today;
    return YES;
}

- (void)setMonthlyBudget:(double)monthlyBudget {
    _monthlyBudget = isfinite(monthlyBudget) ? MAX(monthlyBudget, 0) : 0;
    [NSUserDefaults.standardUserDefaults setDouble:_monthlyBudget forKey:RTBudgetKey];
}

- (NSArray<RTHoliday *> *)automaticHolidaysThisMonth {
    NSInteger year = [self.calendar component:NSCalendarUnitYear fromDate:self.referenceDate];
    NSMutableArray<RTHoliday *> *result = [NSMutableArray array];
    for (RTHoliday *holiday in [RTCalendarEngine argentinaHolidaysForYear:year calendar:self.calendar]) {
        if ([self.calendar isDate:holiday.date equalToDate:self.referenceDate toUnitGranularity:NSCalendarUnitMonth]) {
            [result addObject:holiday];
        }
    }
    return result;
}

- (NSArray<NSDate *> *)extraDaysOffThisMonth {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDate *date, NSDictionary *_) {
        return [self.calendar isDate:date equalToDate:self.referenceDate toUnitGranularity:NSCalendarUnitMonth];
    }];
    return [[self.extraDaysOff.allObjects filteredArrayUsingPredicate:predicate]
            sortedArrayUsingSelector:@selector(compare:)];
}

- (NSSet<NSDate *> *)activeHolidays {
    NSMutableSet<NSDate *> *result = [NSMutableSet setWithSet:self.extraDaysOff];
    for (RTHoliday *holiday in self.automaticHolidaysThisMonth) {
        NSDate *normalized = [self.calendar startOfDayForDate:holiday.date];
        if (![self.ignoredAutomaticHolidays containsObject:normalized]) {
            [result addObject:normalized];
        }
    }
    return result;
}

- (NSArray<NSDate *> *)businessDays {
    return [RTCalendarEngine businessDaysInMonthContaining:self.referenceDate
                                                  holidays:self.activeHolidays
                                                  calendar:self.calendar];
}

- (RTSpendingSnapshot *)snapshot {
    return [RTCalendarEngine snapshotForBudget:self.monthlyBudget
                                   throughDate:self.referenceDate
                                      holidays:self.activeHolidays
                                      calendar:self.calendar];
}

- (BOOL)isAutomaticHolidayEnabled:(RTHoliday *)holiday {
    return ![self.ignoredAutomaticHolidays containsObject:[self.calendar startOfDayForDate:holiday.date]];
}

- (void)setAutomaticHoliday:(RTHoliday *)holiday enabled:(BOOL)enabled {
    NSDate *date = [self.calendar startOfDayForDate:holiday.date];
    if (enabled) {
        [self.ignoredAutomaticHolidays removeObject:date];
    } else {
        [self.ignoredAutomaticHolidays addObject:date];
    }
    [self persistDates:self.ignoredAutomaticHolidays key:RTIgnoredHolidaysKey];
}

- (void)addExtraDayOff:(NSDate *)date {
    [self.extraDaysOff addObject:[self.calendar startOfDayForDate:date]];
    [self persistDates:self.extraDaysOff key:RTExtraDaysKey];
}

- (void)removeExtraDayOff:(NSDate *)date {
    [self.extraDaysOff removeObject:[self.calendar startOfDayForDate:date]];
    [self persistDates:self.extraDaysOff key:RTExtraDaysKey];
}

- (NSDateFormatter *)storageFormatter {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.calendar = self.calendar;
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = self.calendar.timeZone;
    formatter.dateFormat = @"yyyy-MM-dd";
    return formatter;
}

- (NSSet<NSDate *> *)datesFromStoredStrings:(NSArray<NSString *> *)strings {
    NSDateFormatter *formatter = self.storageFormatter;
    NSMutableSet<NSDate *> *dates = [NSMutableSet set];
    for (NSString *value in strings) {
        NSDate *date = [formatter dateFromString:value];
        if (date) [dates addObject:[self.calendar startOfDayForDate:date]];
    }
    return dates;
}

- (void)persistDates:(NSSet<NSDate *> *)dates key:(NSString *)key {
    NSDateFormatter *formatter = self.storageFormatter;
    NSArray<NSDate *> *sorted = [dates.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:sorted.count];
    for (NSDate *date in sorted) [values addObject:[formatter stringFromDate:date]];
    [NSUserDefaults.standardUserDefaults setObject:values forKey:key];
}
@end
