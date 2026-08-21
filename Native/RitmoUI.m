#import "RitmoUI.h"
#import <QuartzCore/QuartzCore.h>

static NSColor *RTInk(void) { return [NSColor colorWithSRGBRed:0.09 green:0.13 blue:0.17 alpha:1]; }
static NSColor *RTPaper(void) { return [NSColor colorWithSRGBRed:0.95 green:0.97 blue:0.98 alpha:1]; }
static NSColor *RTBlue(void) { return [NSColor colorWithSRGBRed:0.12 green:0.43 blue:0.74 alpha:1]; }
static NSColor *RTMint(void) { return [NSColor colorWithSRGBRed:0.42 green:0.83 blue:0.70 alpha:1]; }
static NSColor *RTPaleBlue(void) { return [NSColor colorWithSRGBRed:0.85 green:0.92 blue:0.97 alpha:1]; }
static NSColor *RTRule(void) { return [NSColor colorWithSRGBRed:0.80 green:0.85 blue:0.88 alpha:1]; }

static NSTextField *RTLabel(NSString *text, CGFloat size, NSFontWeight weight, NSColor *color) {
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = [NSFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

static NSDateFormatter *RTDateFormatter(NSString *format) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"es_AR"];
    formatter.dateFormat = format;
    return formatter;
}

static NSNumberFormatter *RTCurrencyFormatter(void) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"es_AR"];
    formatter.currencySymbol = @"$";
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    return formatter;
}

static NSView *RTView(NSView *root, NSString *identifier) {
    if ([root.identifier isEqualToString:identifier]) return root;
    for (NSView *child in root.subviews) {
        NSView *match = RTView(child, identifier);
        if (match) return match;
    }
    return nil;
}

@interface RTDayTrackView : NSView
@property(nonatomic) NSInteger total;
@property(nonatomic) NSInteger elapsed;
@end

@implementation RTDayTrackView
- (BOOL)isFlipped { return YES; }
- (void)setTotal:(NSInteger)total { _total = total; self.needsDisplay = YES; }
- (void)setElapsed:(NSInteger)elapsed { _elapsed = elapsed; self.needsDisplay = YES; }
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (self.total <= 0) return;
    CGFloat gap = 5;
    CGFloat segmentWidth = (NSWidth(self.bounds) - gap * (self.total - 1)) / self.total;
    for (NSInteger index = 0; index < self.total; index++) {
        CGFloat height = index == self.elapsed - 1 ? 14 : 8;
        CGFloat y = (NSHeight(self.bounds) - height) / 2;
        NSRect rect = NSMakeRect(index * (segmentWidth + gap), y, MAX(segmentWidth, 2), height);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:height / 2 yRadius:height / 2];
        NSColor *color = index < self.elapsed ? RTMint() : [NSColor colorWithWhite:1 alpha:0.15];
        [color setFill];
        [path fill];
    }
}
@end

@interface RTAllowanceCard : NSView
@property(nonatomic, strong) NSTextField *amountLabel;
@property(nonatomic, strong) NSTextField *budgetLabel;
@property(nonatomic, strong) NSTextField *dayCountLabel;
@property(nonatomic, strong) NSTextField *dayCaptionLabel;
@property(nonatomic, strong) RTDayTrackView *track;
- (void)updateWithSnapshot:(RTSpendingSnapshot *)snapshot;
@end

@implementation RTAllowanceCard
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = RTInk().CGColor;
        self.layer.cornerRadius = 24;
        self.layer.masksToBounds = YES;

        NSTextField *eyebrow = RTLabel(@"LÍMITE ACUMULADO PARA HOY", 11, NSFontWeightBold, RTMint());
        eyebrow.frame = NSMakeRect(28, 185, 240, 18);
        [self addSubview:eyebrow];

        _amountLabel = RTLabel(@"$ 0", 50, NSFontWeightBold, NSColor.whiteColor);
        _amountLabel.font = [NSFont monospacedDigitSystemFontOfSize:50 weight:NSFontWeightBold];
        [self addSubview:_amountLabel];

        _budgetLabel = RTLabel(@"", 15, NSFontWeightMedium, [NSColor colorWithWhite:1 alpha:0.62]);
        [self addSubview:_budgetLabel];

        _dayCountLabel = RTLabel(@"0", 40, NSFontWeightBold, RTMint());
        _dayCountLabel.font = [NSFont monospacedDigitSystemFontOfSize:40 weight:NSFontWeightBold];
        _dayCountLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_dayCountLabel];

        _dayCaptionLabel = RTLabel(@"de 0 días", 11, NSFontWeightSemibold, [NSColor colorWithWhite:1 alpha:0.55]);
        _dayCaptionLabel.alignment = NSTextAlignmentCenter;
        [self addSubview:_dayCaptionLabel];

        _track = [[RTDayTrackView alloc] initWithFrame:NSZeroRect];
        [_track setAccessibilityLabel:@"Progreso de jornadas hábiles"];
        [self addSubview:_track];

        NSTextField *start = RTLabel(@"Inicio", 10, NSFontWeightMedium, [NSColor colorWithWhite:1 alpha:0.40]);
        start.frame = NSMakeRect(28, 22, 70, 14);
        [self addSubview:start];
        NSTextField *legend = RTLabel(@"Cada marca es una jornada hábil", 10, NSFontWeightMedium, [NSColor colorWithWhite:1 alpha:0.40]);
        legend.alignment = NSTextAlignmentCenter;
        legend.frame = NSMakeRect(185, 22, 260, 14);
        [self addSubview:legend];
        NSTextField *end = RTLabel(@"Fin de mes", 10, NSFontWeightMedium, [NSColor colorWithWhite:1 alpha:0.40]);
        end.alignment = NSTextAlignmentRight;
        end.autoresizingMask = NSViewMinXMargin;
        [self addSubview:end];
        end.identifier = @"endLabel";
    }
    return self;
}

- (void)layout {
    [super layout];
    CGFloat width = NSWidth(self.bounds);
    self.amountLabel.frame = NSMakeRect(25, 118, width - 190, 64);
    self.budgetLabel.frame = NSMakeRect(29, 95, width - 190, 22);
    self.dayCountLabel.frame = NSMakeRect(width - 145, 128, 110, 52);
    self.dayCaptionLabel.frame = NSMakeRect(width - 145, 110, 110, 18);
    self.track.frame = NSMakeRect(28, 44, width - 56, 22);
    NSView *end = RTView(self, @"endLabel");
    end.frame = NSMakeRect(width - 108, 22, 80, 14);
}

- (void)updateWithSnapshot:(RTSpendingSnapshot *)snapshot {
    NSNumberFormatter *currency = RTCurrencyFormatter();
    self.amountLabel.stringValue = [currency stringFromNumber:@(snapshot.allowedThroughDate)] ?: @"$ 0";
    self.amountLabel.font = [NSFont monospacedDigitSystemFontOfSize:50 weight:NSFontWeightBold];
    self.budgetLabel.stringValue = [NSString stringWithFormat:@"de %@ asignados para el mes",
                                    [currency stringFromNumber:@(snapshot.monthlyBudget)]];
    self.dayCountLabel.stringValue = [NSString stringWithFormat:@"%ld / %ld",
                                      snapshot.elapsedBusinessDays,
                                      snapshot.totalBusinessDays];
    self.dayCountLabel.font = [NSFont monospacedDigitSystemFontOfSize:25 weight:NSFontWeightBold];
    self.dayCountLabel.textColor = RTMint();
    self.dayCaptionLabel.stringValue = @"jornadas hábiles";
    self.track.total = snapshot.totalBusinessDays;
    self.track.elapsed = snapshot.elapsedBusinessDays;
    [self.track setAccessibilityValue:[NSString stringWithFormat:@"%ld de %ld", snapshot.elapsedBusinessDays, snapshot.totalBusinessDays]];
}
@end

@interface RTStatCard : NSView
@property(nonatomic, strong) NSTextField *valueLabel;
@property(nonatomic, strong) NSTextField *captionLabel;
- (instancetype)initWithSymbol:(NSString *)symbol caption:(NSString *)caption;
@end


@implementation RTStatCard
- (instancetype)initWithSymbol:(NSString *)symbol caption:(NSString *)caption {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.82].CGColor;
        self.layer.cornerRadius = 18;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [RTRule() colorWithAlphaComponent:0.75].CGColor;

        NSView *tile = [[NSView alloc] initWithFrame:NSZeroRect];
        tile.wantsLayer = YES;
        tile.layer.backgroundColor = RTPaleBlue().CGColor;
        tile.layer.cornerRadius = 8;
        tile.identifier = @"tile";
        [self addSubview:tile];

        NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:caption];
        NSImageView *icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
        icon.image = image;
        icon.contentTintColor = RTBlue();
        icon.imageScaling = NSImageScaleProportionallyDown;
        icon.identifier = @"icon";
        [tile addSubview:icon];

        _valueLabel = RTLabel(@"—", 16, NSFontWeightBold, RTInk());
        _valueLabel.font = [NSFont monospacedDigitSystemFontOfSize:16 weight:NSFontWeightBold];
        [self addSubview:_valueLabel];
        _captionLabel = RTLabel(caption, 11, NSFontWeightMedium, NSColor.secondaryLabelColor);
        [self addSubview:_captionLabel];
    }
    return self;
}
- (void)layout {
    [super layout];
    NSView *tile = RTView(self, @"tile");
    tile.frame = NSMakeRect(16, NSHeight(self.bounds) - 47, 30, 30);
    RTView(tile, @"icon").frame = NSMakeRect(7, 7, 16, 16);
    self.valueLabel.frame = NSMakeRect(16, 34, NSWidth(self.bounds) - 28, 23);
    self.captionLabel.frame = NSMakeRect(16, 15, NSWidth(self.bounds) - 28, 18);
}
@end

@interface RTSettingsPanel : NSView
@property(nonatomic, strong) RitmoModel *model;
@property(nonatomic, copy) void (^onChange)(void);
@property(nonatomic, strong) NSTextField *budgetField;
@property(nonatomic, strong) NSDatePicker *extraPicker;
@property(nonatomic, strong) NSPopUpButton *extraPopup;
@property(nonatomic, strong) NSTextField *dailyValue;
@property(nonatomic, strong) NSMutableArray<NSButton *> *holidayButtons;
- (instancetype)initWithModel:(RitmoModel *)model;
- (void)refresh;
@end

@implementation RTSettingsPanel
- (instancetype)initWithModel:(RitmoModel *)model {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        _model = model;
        _holidayButtons = [NSMutableArray array];
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.88].CGColor;
        self.layer.cornerRadius = 22;
        self.layer.borderColor = [RTRule() colorWithAlphaComponent:0.75].CGColor;
        self.layer.borderWidth = 1;

        NSTextField *title = RTLabel(@"Ajustes del mes", 20, NSFontWeightBold, RTInk());
        title.frame = NSMakeRect(22, 570, 230, 28);
        [self addSubview:title];
        NSTextField *subtitle = RTLabel(@"El cálculo se actualiza al instante.", 12, NSFontWeightRegular, NSColor.secondaryLabelColor);
        subtitle.frame = NSMakeRect(22, 547, 240, 19);
        [self addSubview:subtitle];

        [self addSectionLabel:@"SALDO ASIGNADO" y:511];
        _budgetField = [[NSTextField alloc] initWithFrame:NSMakeRect(22, 473, 236, 30)];
        _budgetField.font = [NSFont monospacedDigitSystemFontOfSize:16 weight:NSFontWeightSemibold];
        _budgetField.placeholderString = @"750";
        _budgetField.target = self;
        _budgetField.action = @selector(budgetChanged:);
        [_budgetField setAccessibilityLabel:@"Saldo mensual asignado"];
        [self addSubview:_budgetField];

        _dailyValue = RTLabel(@"", 12, NSFontWeightSemibold, RTBlue());
        _dailyValue.frame = NSMakeRect(22, 445, 236, 18);
        [self addSubview:_dailyValue];

        NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(22, 420, 236, 1)];
        divider.boxType = NSBoxSeparator;
        [self addSubview:divider];

        [self addSectionLabel:@"FERIADOS ARGENTINOS" y:391];

        NSTextField *extraTitle = RTLabel(@"DÍA NO LABORABLE PROPIO", 10, NSFontWeightBold, NSColor.secondaryLabelColor);
        extraTitle.frame = NSMakeRect(22, 245, 236, 16);
        extraTitle.identifier = @"extraTitle";
        [self addSubview:extraTitle];

        _extraPicker = [[NSDatePicker alloc] initWithFrame:NSMakeRect(22, 209, 150, 28)];
        _extraPicker.datePickerElements = NSDatePickerElementFlagYearMonthDay;
        _extraPicker.datePickerStyle = NSDatePickerStyleTextFieldAndStepper;
        [self addSubview:_extraPicker];

        NSButton *add = [NSButton buttonWithTitle:@"Agregar" target:self action:@selector(addExtraDay:)];
        add.bezelStyle = NSBezelStyleRounded;
        add.frame = NSMakeRect(178, 208, 80, 30);
        add.identifier = @"addExtra";
        [self addSubview:add];

        _extraPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(22, 169, 184, 28) pullsDown:NO];
        [_extraPopup setAccessibilityLabel:@"Días no laborables propios"];
        [self addSubview:_extraPopup];
        NSButton *remove = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"minus" accessibilityDescription:@"Quitar día"]
                                              target:self
                                              action:@selector(removeExtraDay:)];
        remove.bezelStyle = NSBezelStyleRounded;
        remove.frame = NSMakeRect(214, 169, 44, 28);
        remove.identifier = @"removeExtra";
        [self addSubview:remove];

        _extraPicker.dateValue = model.referenceDate;
        [self refresh];
    }
    return self;
}

- (void)addSectionLabel:(NSString *)text y:(CGFloat)y {
    NSTextField *label = RTLabel(text, 10, NSFontWeightBold, NSColor.secondaryLabelColor);
    label.frame = NSMakeRect(22, y, 236, 16);
    [self addSubview:label];
}

- (void)refresh {
    self.budgetField.doubleValue = self.model.monthlyBudget;
    self.extraPicker.dateValue = self.model.referenceDate;
    NSNumberFormatter *currency = RTCurrencyFormatter();
    self.dailyValue.stringValue = [NSString stringWithFormat:@"%@ por jornada hábil", [currency stringFromNumber:@(self.model.snapshot.dailyAllowance)]];

    for (NSButton *button in self.holidayButtons) [button removeFromSuperview];
    [self.holidayButtons removeAllObjects];
    CGFloat y = 360;
    NSDateFormatter *shortDate = RTDateFormatter(@"d 'de' MMMM");
    NSArray<RTHoliday *> *holidays = self.model.automaticHolidaysThisMonth;
    if (holidays.count == 0) {
        NSButton *empty = [NSButton checkboxWithTitle:@"Sin feriados base este mes" target:nil action:nil];
        empty.enabled = NO;
        empty.frame = NSMakeRect(22, y - 2, 236, 24);
        [self addSubview:empty];
        [self.holidayButtons addObject:empty];
        y -= 30;
    } else {
        for (RTHoliday *holiday in holidays) {
            NSString *title = [NSString stringWithFormat:@"%@ · %@", [shortDate stringFromDate:holiday.date], holiday.name];
            NSButton *button = [NSButton checkboxWithTitle:title target:self action:@selector(holidayToggled:)];
            button.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
            button.state = [self.model isAutomaticHolidayEnabled:holiday] ? NSControlStateValueOn : NSControlStateValueOff;
            button.identifier = [self storageStringForDate:holiday.date];
            button.frame = NSMakeRect(22, y, 236, 22);
            button.lineBreakMode = NSLineBreakByTruncatingTail;
            [self addSubview:button];
            [self.holidayButtons addObject:button];
            y -= 27;
        }
    }

    CGFloat extraTitleY = MIN(245, y - 18);
    RTView(self, @"extraTitle").frame = NSMakeRect(22, extraTitleY, 236, 16);
    self.extraPicker.frame = NSMakeRect(22, extraTitleY - 37, 150, 28);
    RTView(self, @"addExtra").frame = NSMakeRect(178, extraTitleY - 38, 80, 30);
    self.extraPopup.frame = NSMakeRect(22, extraTitleY - 77, 184, 28);
    RTView(self, @"removeExtra").frame = NSMakeRect(214, extraTitleY - 77, 44, 28);

    [self.extraPopup removeAllItems];
    NSArray<NSDate *> *extraDates = self.model.extraDaysOffThisMonth;
    NSDateFormatter *fullDate = RTDateFormatter(@"EEEE d 'de' MMMM");
    if (extraDates.count == 0) {
        [self.extraPopup addItemWithTitle:@"Ninguno agregado"];
        self.extraPopup.enabled = NO;
        RTView(self, @"removeExtra").hidden = YES;
    } else {
        self.extraPopup.enabled = YES;
        RTView(self, @"removeExtra").hidden = NO;
        for (NSDate *date in extraDates) {
            [self.extraPopup addItemWithTitle:[fullDate stringFromDate:date]];
            self.extraPopup.lastItem.representedObject = date;
        }
    }
}

- (NSString *)storageStringForDate:(NSDate *)date {
    NSDateFormatter *formatter = RTDateFormatter(@"yyyy-MM-dd");
    formatter.timeZone = self.model.calendar.timeZone;
    return [formatter stringFromDate:date];
}

- (void)budgetChanged:(NSTextField *)sender {
    self.model.monthlyBudget = sender.doubleValue;
    if (self.onChange) self.onChange();
}
- (void)holidayToggled:(NSButton *)sender {
    for (RTHoliday *holiday in self.model.automaticHolidaysThisMonth) {
        if ([[self storageStringForDate:holiday.date] isEqualToString:sender.identifier]) {
            [self.model setAutomaticHoliday:holiday enabled:sender.state == NSControlStateValueOn];
            break;
        }
    }
    if (self.onChange) self.onChange();
}
- (void)addExtraDay:(id)sender {
    [self.model addExtraDayOff:self.extraPicker.dateValue];
    if (self.onChange) self.onChange();
}
- (void)removeExtraDay:(id)sender {
    NSDate *date = self.extraPopup.selectedItem.representedObject;
    if (date) [self.model removeExtraDayOff:date];
    if (self.onChange) self.onChange();
}
@end

@interface RitmoViewController ()
@property(nonatomic, strong) RitmoModel *model;
@property(nonatomic, strong) NSTextField *monthLabel;
@property(nonatomic, strong) NSTextField *dateLabel;
@property(nonatomic, strong) RTAllowanceCard *allowanceCard;
@property(nonatomic, strong) RTStatCard *dailyCard;
@property(nonatomic, strong) RTStatCard *daysCard;
@property(nonatomic, strong) RTStatCard *remainingCard;
@property(nonatomic, strong) NSTextField *holidaySummary;
@property(nonatomic, strong) RTSettingsPanel *settingsPanel;
@end

@implementation RitmoViewController
- (instancetype)initWithModel:(RitmoModel *)model {
    self = [super initWithNibName:nil bundle:nil];
    if (self) _model = model;
    return self;
}
- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1000, 650)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = RTPaper().CGColor;
    self.view = root;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSView *logoTile = [[NSView alloc] initWithFrame:NSZeroRect];
    logoTile.wantsLayer = YES;
    logoTile.layer.backgroundColor = RTInk().CGColor;
    logoTile.layer.cornerRadius = 10;
    logoTile.identifier = @"logoTile";
    [self.view addSubview:logoTile];
    NSImageView *logo = [[NSImageView alloc] initWithFrame:NSZeroRect];
    logo.image = [NSImage imageWithSystemSymbolName:@"calendar" accessibilityDescription:@"Ritmo"];
    logo.contentTintColor = RTMint();
    logo.imageScaling = NSImageScaleProportionallyDown;
    logo.identifier = @"logo";
    [logoTile addSubview:logo];

    NSTextField *brand = RTLabel(@"RITMO", 12, NSFontWeightHeavy, RTBlue());
    brand.identifier = @"brand";
    [self.view addSubview:brand];
    _monthLabel = RTLabel(@"", 19, NSFontWeightSemibold, RTInk());
    [self.view addSubview:_monthLabel];
    _dateLabel = RTLabel(@"", 13, NSFontWeightMedium, NSColor.secondaryLabelColor);
    _dateLabel.alignment = NSTextAlignmentRight;
    [self.view addSubview:_dateLabel];

    _allowanceCard = [[RTAllowanceCard alloc] initWithFrame:NSZeroRect];
    [self.view addSubview:_allowanceCard];
    _dailyCard = [[RTStatCard alloc] initWithSymbol:@"banknote" caption:@"Por jornada hábil"];
    _daysCard = [[RTStatCard alloc] initWithSymbol:@"calendar.badge.checkmark" caption:@"Jornadas transcurridas"];
    _remainingCard = [[RTStatCard alloc] initWithSymbol:@"arrow.forward.circle" caption:@"Por distribuir este mes"];
    [self.view addSubview:_dailyCard];
    [self.view addSubview:_daysCard];
    [self.view addSubview:_remainingCard];

    NSImageView *sparkle = [[NSImageView alloc] initWithFrame:NSZeroRect];
    sparkle.image = [NSImage imageWithSystemSymbolName:@"sparkles" accessibilityDescription:nil];
    sparkle.contentTintColor = RTBlue();
    sparkle.identifier = @"sparkle";
    [self.view addSubview:sparkle];
    _holidaySummary = RTLabel(@"", 12, NSFontWeightMedium, NSColor.secondaryLabelColor);
    [self.view addSubview:_holidaySummary];

    _settingsPanel = [[RTSettingsPanel alloc] initWithModel:self.model];
    __weak typeof(self) weakSelf = self;
    _settingsPanel.onChange = ^{ [weakSelf refresh]; };
    [self.view addSubview:_settingsPanel];
    [self refresh];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    CGFloat width = NSWidth(self.view.bounds);
    CGFloat height = NSHeight(self.view.bounds);
    CGFloat margin = 34;
    CGFloat panelWidth = 280;
    CGFloat gap = 26;
    CGFloat leftWidth = width - margin * 2 - panelWidth - gap;

    NSView *logoTile = RTView(self.view, @"logoTile");
    logoTile.frame = NSMakeRect(margin, height - 71, 38, 38);
    RTView(logoTile, @"logo").frame = NSMakeRect(9, 9, 20, 20);
    RTView(self.view, @"brand").frame = NSMakeRect(margin + 50, height - 52, 100, 16);
    self.monthLabel.frame = NSMakeRect(margin + 50, height - 73, 250, 24);
    self.dateLabel.frame = NSMakeRect(margin + leftWidth - 250, height - 62, 250, 20);

    self.allowanceCard.frame = NSMakeRect(margin, height - 332, leftWidth, 232);
    CGFloat statY = height - 466;
    CGFloat statGap = 12;
    CGFloat statWidth = (leftWidth - statGap * 2) / 3;
    self.dailyCard.frame = NSMakeRect(margin, statY, statWidth, 112);
    self.daysCard.frame = NSMakeRect(margin + statWidth + statGap, statY, statWidth, 112);
    self.remainingCard.frame = NSMakeRect(margin + (statWidth + statGap) * 2, statY, statWidth, 112);
    RTView(self.view, @"sparkle").frame = NSMakeRect(margin + 2, statY - 42, 16, 16);
    self.holidaySummary.frame = NSMakeRect(margin + 25, statY - 44, leftWidth - 25, 20);

    self.settingsPanel.frame = NSMakeRect(margin + leftWidth + gap, 24, panelWidth, height - 48);
}

- (void)refresh {
    RTSpendingSnapshot *snapshot = self.model.snapshot;
    NSDateFormatter *month = RTDateFormatter(@"MMMM yyyy");
    NSDateFormatter *date = RTDateFormatter(@"EEEE d 'de' MMMM");
    NSString *monthString = [month stringFromDate:self.model.referenceDate];
    self.monthLabel.stringValue = monthString.capitalizedString;
    self.dateLabel.stringValue = [date stringFromDate:self.model.referenceDate];
    [self.allowanceCard updateWithSnapshot:snapshot];

    NSNumberFormatter *currency = RTCurrencyFormatter();
    self.dailyCard.valueLabel.stringValue = [currency stringFromNumber:@(snapshot.dailyAllowance)];
    self.daysCard.valueLabel.stringValue = [NSString stringWithFormat:@"%ld de %ld",
                                             snapshot.elapsedBusinessDays,
                                             snapshot.totalBusinessDays];
    self.remainingCard.valueLabel.stringValue = [currency stringFromNumber:@(snapshot.remainingBudget)];

    NSInteger holidayCount = 0;
    for (NSDate *date in self.model.activeHolidays) {
        if ([self.model.calendar isDate:date
                            equalToDate:self.model.referenceDate
                      toUnitGranularity:NSCalendarUnitMonth]) {
            holidayCount++;
        }
    }
    NSString *holidayText = holidayCount == 1 ? @"1 día no laborable contemplado" : [NSString stringWithFormat:@"%ld días no laborables contemplados", holidayCount];
    self.holidaySummary.stringValue = [NSString stringWithFormat:@"%ld jornadas hábiles este mes · %@",
                                        snapshot.totalBusinessDays,
                                        holidayText];
    [self.settingsPanel refresh];
    [NSNotificationCenter.defaultCenter postNotificationName:@"RitmoSnapshotDidChange" object:self.model];
}
@end
