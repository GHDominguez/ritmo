#import <Foundation/Foundation.h>
#import "RitmoCore.h"

static void RTExpect(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FALLÓ: %s\n", message.UTF8String);
        exit(1);
    }
}

static NSDate *RTDate(NSCalendar *calendar, NSInteger year, NSInteger month, NSInteger day) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    return [calendar dateFromComponents:components];
}

int main(void) {
    @autoreleasepool {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"America/Argentina/Buenos_Aires"];
        NSDate *cutoff = RTDate(calendar, 2026, 8, 7);
        NSDate *holiday = RTDate(calendar, 2026, 8, 17);
        RTSpendingSnapshot *snapshot = [RTCalendarEngine snapshotForBudget:750
                                                               throughDate:cutoff
                                                                  holidays:[NSSet setWithObject:holiday]
                                                                  calendar:calendar];
        RTExpect(snapshot.totalBusinessDays == 20, @"agosto debe tener 20 jornadas hábiles");
        RTExpect(snapshot.elapsedBusinessDays == 5, @"el 7/8 debe ser la quinta jornada hábil");
        RTExpect(fabs(snapshot.dailyAllowance - 37.5) < 0.001, @"la asignación diaria debe ser 37,5");
        RTExpect(fabs(snapshot.allowedThroughDate - 187.5) < 0.001, @"el límite debe ser 187,5");

        RTSpendingSnapshot *friday = [RTCalendarEngine snapshotForBudget:750 throughDate:cutoff holidays:NSSet.set calendar:calendar];
        RTSpendingSnapshot *sunday = [RTCalendarEngine snapshotForBudget:750 throughDate:RTDate(calendar, 2026, 8, 9) holidays:NSSet.set calendar:calendar];
        RTExpect(friday.elapsedBusinessDays == sunday.elapsedBusinessDays, @"el fin de semana no debe avanzar el límite");

        BOOL foundSanMartin = NO;
        for (RTHoliday *item in [RTCalendarEngine argentinaHolidaysForYear:2026 calendar:calendar]) {
            if ([item.name containsString:@"San Martín"] && [calendar isDate:item.date inSameDayAsDate:holiday]) foundSanMartin = YES;
        }
        RTExpect(foundSanMartin, @"debe incluir el feriado de San Martín");

        puts("OK: 3 pruebas del cálculo de jornadas y límites pasaron");
    }
    return 0;
}
