#import "RitmoCore.h"

@implementation RTSpendingSnapshot
- (instancetype)initWithBudget:(double)budget
                dailyAllowance:(double)dailyAllowance
             allowedThroughDate:(double)allowedThroughDate
             totalBusinessDays:(NSInteger)totalBusinessDays
           elapsedBusinessDays:(NSInteger)elapsedBusinessDays {
    self = [super init];
    if (self) {
        _monthlyBudget = budget;
        _dailyAllowance = dailyAllowance;
        _allowedThroughDate = allowedThroughDate;
        _totalBusinessDays = totalBusinessDays;
        _elapsedBusinessDays = elapsedBusinessDays;
        _remainingBudget = MAX(budget - allowedThroughDate, 0);
    }
    return self;
}
@end

@implementation RTHoliday
- (instancetype)initWithName:(NSString *)name date:(NSDate *)date {
    self = [super init];
    if (self) {
        _name = [name copy];
        _date = [date copy];
    }
    return self;
}
@end

@implementation RTCalendarEngine

+ (NSArray<NSDate *> *)businessDaysInMonthContaining:(NSDate *)date
                                            holidays:(NSSet<NSDate *> *)holidays
                                            calendar:(NSCalendar *)calendar {
    NSDate *monthStart = nil;
    NSTimeInterval interval = 0;
    if (![calendar rangeOfUnit:NSCalendarUnitMonth startDate:&monthStart interval:&interval forDate:date]) {
        return @[];
    }

    NSRange days = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    NSMutableSet<NSDate *> *normalizedHolidays = [NSMutableSet set];
    for (NSDate *holiday in holidays) {
        [normalizedHolidays addObject:[calendar startOfDayForDate:holiday]];
    }

    NSMutableArray<NSDate *> *result = [NSMutableArray array];
    for (NSInteger offset = 0; offset < (NSInteger)days.length; offset++) {
        NSDate *candidate = [calendar dateByAddingUnit:NSCalendarUnitDay value:offset toDate:monthStart options:0];
        NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:candidate];
        BOOL weekend = weekday == 1 || weekday == 7;
        BOOL holiday = [normalizedHolidays containsObject:[calendar startOfDayForDate:candidate]];
        if (!weekend && !holiday) {
            [result addObject:candidate];
        }
    }
    return result;
}

+ (RTSpendingSnapshot *)snapshotForBudget:(double)budget
                              throughDate:(NSDate *)date
                                 holidays:(NSSet<NSDate *> *)holidays
                                 calendar:(NSCalendar *)calendar {
    NSArray<NSDate *> *days = [self businessDaysInMonthContaining:date holidays:holidays calendar:calendar];
    NSDate *cutoff = [calendar startOfDayForDate:date];
    NSInteger elapsed = 0;
    for (NSDate *businessDay in days) {
        if ([[calendar startOfDayForDate:businessDay] compare:cutoff] != NSOrderedDescending) {
            elapsed++;
        }
    }

    double safeBudget = isfinite(budget) ? MAX(budget, 0) : 0;
    double daily = days.count == 0 ? 0 : safeBudget / (double)days.count;
    double allowed = MIN(daily * (double)elapsed, safeBudget);
    return [[RTSpendingSnapshot alloc] initWithBudget:safeBudget
                                      dailyAllowance:daily
                                   allowedThroughDate:allowed
                                   totalBusinessDays:days.count
                                 elapsedBusinessDays:elapsed];
}

+ (NSArray<RTHoliday *> *)argentinaHolidaysForYear:(NSInteger)year
                                           calendar:(NSCalendar *)calendar {
    NSDate *(^makeDate)(NSInteger, NSInteger) = ^NSDate *(NSInteger month, NSInteger day) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = year;
        components.month = month;
        components.day = day;
        return [calendar dateFromComponents:components];
    };

    NSDate *easter = [self easterSundayForYear:year calendar:calendar];
    NSDate *carnivalMonday = [calendar dateByAddingUnit:NSCalendarUnitDay value:-48 toDate:easter options:0];
    NSDate *carnivalTuesday = [calendar dateByAddingUnit:NSCalendarUnitDay value:-47 toDate:easter options:0];
    NSDate *goodFriday = [calendar dateByAddingUnit:NSCalendarUnitDay value:-2 toDate:easter options:0];

    NSMutableArray<RTHoliday *> *result = [NSMutableArray arrayWithArray:@[
        [[RTHoliday alloc] initWithName:@"Año Nuevo" date:makeDate(1, 1)],
        [[RTHoliday alloc] initWithName:@"Carnaval" date:carnivalMonday],
        [[RTHoliday alloc] initWithName:@"Carnaval" date:carnivalTuesday],
        [[RTHoliday alloc] initWithName:@"Día de la Memoria" date:makeDate(3, 24)],
        [[RTHoliday alloc] initWithName:@"Veteranos y Caídos en Malvinas" date:makeDate(4, 2)],
        [[RTHoliday alloc] initWithName:@"Viernes Santo" date:goodFriday],
        [[RTHoliday alloc] initWithName:@"Día del Trabajador" date:makeDate(5, 1)],
        [[RTHoliday alloc] initWithName:@"Revolución de Mayo" date:makeDate(5, 25)],
        [[RTHoliday alloc] initWithName:@"Manuel Belgrano" date:makeDate(6, 20)],
        [[RTHoliday alloc] initWithName:@"Día de la Independencia" date:makeDate(7, 9)],
        [[RTHoliday alloc] initWithName:@"Inmaculada Concepción" date:makeDate(12, 8)],
        [[RTHoliday alloc] initWithName:@"Navidad" date:makeDate(12, 25)]
    ]];

    NSArray<NSArray *> *movable = @[
        @[@"Martín Miguel de Güemes", makeDate(6, 17)],
        @[@"José de San Martín", makeDate(8, 17)],
        @[@"Diversidad Cultural", makeDate(10, 12)],
        @[@"Soberanía Nacional", makeDate(11, 20)]
    ];
    for (NSArray *item in movable) {
        NSDate *observed = [self observedDateForDate:item[1] calendar:calendar];
        [result addObject:[[RTHoliday alloc] initWithName:item[0] date:observed]];
    }

    [result sortUsingComparator:^NSComparisonResult(RTHoliday *left, RTHoliday *right) {
        return [left.date compare:right.date];
    }];
    return result;
}

+ (NSDate *)observedDateForDate:(NSDate *)date calendar:(NSCalendar *)calendar {
    NSInteger weekday = [calendar component:NSCalendarUnitWeekday fromDate:date];
    if (weekday == 3 || weekday == 4) {
        return [calendar dateByAddingUnit:NSCalendarUnitDay value:-(weekday - 2) toDate:date options:0];
    }
    if (weekday == 5 || weekday == 6) {
        return [calendar dateByAddingUnit:NSCalendarUnitDay value:(9 - weekday) toDate:date options:0];
    }
    return date;
}

+ (NSDate *)easterSundayForYear:(NSInteger)year calendar:(NSCalendar *)calendar {
    NSInteger a = year % 19;
    NSInteger b = year / 100;
    NSInteger c = year % 100;
    NSInteger d = b / 4;
    NSInteger e = b % 4;
    NSInteger f = (b + 8) / 25;
    NSInteger g = (b - f + 1) / 3;
    NSInteger h = (19 * a + b - d - g + 15) % 30;
    NSInteger i = c / 4;
    NSInteger k = c % 4;
    NSInteger l = (32 + 2 * e + 2 * i - h - k) % 7;
    NSInteger m = (a + 11 * h + 22 * l) / 451;
    NSInteger month = (h + l - 7 * m + 114) / 31;
    NSInteger day = ((h + l - 7 * m + 114) % 31) + 1;

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    return [calendar dateFromComponents:components];
}
@end
