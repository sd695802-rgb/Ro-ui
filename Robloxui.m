#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <substrate.h>
#import <QuartzCore/QuartzCore.h>

static __strong id mxMenuController = nil;

@interface MXMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *mainPanel;
@property (nonatomic, strong) UIView *contentContainer;

@property (nonatomic, strong) UIButton *tabUseScriptBtn;
@property (nonatomic, strong) UIButton *tabSavedBtn;
@property (nonatomic, strong) UIButton *tabAboutBtn;

@property (nonatomic, strong) UIView *viewUseScript;
@property (nonatomic, strong) UIView *viewSaved;
@property (nonatomic, strong) UIView *viewAbout;

@property (nonatomic, strong) UITextView *scriptInputBox;
@property (nonatomic, strong) UITextField *scriptNameField;
@property (nonatomic, strong) UITableView *savedScriptsTable;
@property (nonatomic, strong) NSMutableArray *savedScriptsArray;

- (void)setupFloatingButton;
- (void)setupMainPanel;
- (void)setupUseScriptView;
- (void)setupSavedView;
- (void)setupAboutView;

- (void)switchTabToUseScript:(id)sender;
- (void)switchTabToSaved:(id)sender;
- (void)switchTabToAbout:(id)sender;

@end

@implementation MXMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    NSArray *storedScripts = [[NSUserDefaults standardUserDefaults] arrayForKey:@"MXSavedScripts"];
    if (storedScripts.count > 0) {
        self.savedScriptsArray = [NSMutableArray arrayWithArray:storedScripts];
    } else {
        self.savedScriptsArray = [NSMutableArray arrayWithArray:@[
            @{@"name": @"Welcome Script", @"code": @"print('Melux MX Loaded Successfully!');"}
        ]];
    }

    [self setupFloatingButton];
    [self setupMainPanel];
}

- (void)setupFloatingButton {
    if (self.floatingButton) return;

    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(40, 100, 48, 48);
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:0.95];
    self.floatingButton.layer.cornerRadius = 24.0f;
    self.floatingButton.layer.borderWidth = 2.0f;
    self.floatingButton.layer.borderColor = [UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0].CGColor; // لون بنفسجي مميز

    [self.floatingButton setTitle:@"MX" forState:UIControlStateNormal];
    [self.floatingButton setTitleColor:[UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];

    [self.floatingButton addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
    [self.floatingButton addGestureRecognizer:panGesture];

    UIWindow *window = [self activeWindow];
    if (window) {
        [window addSubview:self.floatingButton];
        [window bringSubviewToFront:self.floatingButton];
    }
}

- (UIWindow *)activeWindow {
    UIWindow *result = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) { result = window; break; }
            }
            if (result != nil) break;
            if (windowScene.windows.count > 0) { result = windowScene.windows.firstObject; }
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }
    return result;
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)gesture {
    UIWindow *window = [self activeWindow];
    CGPoint translation = [gesture translationInView:window];
    CGPoint recognizerCenter = gesture.view.center;
    
    gesture.view.center = CGPointMake(recognizerCenter.x + translation.x, recognizerCenter.y + translation.y);
    [gesture setTranslation:CGPointZero inView:window];
}

- (void)handlePanelPan:(UIPanGestureRecognizer *)gesture {
    UIWindow *window = [self activeWindow];
    CGPoint translation = [gesture translationInView:window];
    CGPoint recognizerCenter = gesture.view.center;
    
    gesture.view.center = CGPointMake(recognizerCenter.x + translation.x, recognizerCenter.y + translation.y);
    [gesture setTranslation:CGPointZero inView:window];
}

- (void)setupMainPanel {
    if (self.mainPanel) return;

    self.mainPanel = [[UIView alloc] initWithFrame:CGRectMake(80, 80, 330, 410)];
    self.mainPanel.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:0.98]; // أسود بالكامل وراقي
    self.mainPanel.layer.cornerRadius = 14.0f;
    self.mainPanel.layer.borderWidth = 1.5f;
    self.mainPanel.layer.borderColor = [UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0].CGColor;
    self.mainPanel.hidden = YES;

    UIPanGestureRecognizer *panelPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanelPan:)];
    [self.mainPanel addGestureRecognizer:panelPan];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 310, 25)];
    title.text = @"MELUX - MX EXECUTOR";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:14.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.mainPanel addSubview:title];

    CGFloat tabW = 100.0f;
    self.tabUseScriptBtn = [self createTabButton:@"Use script" frame:CGRectMake(10, 38, tabW, 32) action:@selector(switchTabToUseScript:)];
    self.tabSavedBtn = [self createTabButton:@"المنحفظة" frame:CGRectMake(115, 38, tabW, 32) action:@selector(switchTabToSaved:)];
    self.tabAboutBtn = [self createTabButton:@"About" frame:CGRectMake(220, 38, tabW, 32) action:@selector(switchTabToAbout:)];

    [self.mainPanel addSubview:self.tabUseScriptBtn];
    [self.mainPanel addSubview:self.tabSavedBtn];
    [self.mainPanel addSubview:self.tabAboutBtn];

    self.contentContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 78, 310, 320)];
    [self.mainPanel addSubview:self.contentContainer];

    [self setupUseScriptView];
    [self setupSavedView];
    [self setupAboutView];

    [self switchTabToUseScript:nil];

    UIWindow *window = [self activeWindow];
    if (window) {
        [window addSubview:self.mainPanel];
        [window bringSubviewToFront:self.mainPanel];
    }
}

- (UIButton *)createTabButton:(NSString *)title frame:(CGRect)frame action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0];
    btn.layer.cornerRadius = 6.0f;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)setupUseScriptView {
    self.viewUseScript = [[UIView alloc] initWithFrame:self.contentContainer.bounds];

    // خانة كتابة السكربت
    self.scriptInputBox = [[UITextView alloc] initWithFrame:CGRectMake(0, 5, 310, 155)];
    self.scriptInputBox.backgroundColor = [UIColor colorWithRed:0.03 green:0.03 blue:0.04 alpha:1.0];
    self.scriptInputBox.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.4 alpha:1.0];
    self.scriptInputBox.font = [UIFont fontWithName:@"Courier" size:12];
    self.scriptInputBox.text = @"-- Paste your Lua script here\nprint('Melux MX Running...');";
    self.scriptInputBox.layer.cornerRadius = 6.0f;
    self.scriptInputBox.layer.borderWidth = 1.0f;
    self.scriptInputBox.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:1.0].CGColor;

    UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    keyboardToolbar.barStyle = UIBarStyleDefault;
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done / Close" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard)];
    keyboardToolbar.items = @[flexSpace, doneBtn];
    [keyboardToolbar sizeToFit];
    self.scriptInputBox.inputAccessoryView = keyboardToolbar;

    [self.viewUseScript addSubview:self.scriptInputBox];

    // أزرار التنفيذ والتنظيف
    UIButton *execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    execBtn.frame = CGRectMake(0, 168, 150, 35);
    [execBtn setTitle:@"Execute" forState:UIControlStateNormal];
    [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    execBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:1.0];
    execBtn.layer.cornerRadius = 6.0f;
    [execBtn addTarget:self action:@selector(executeScriptAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewUseScript addSubview:execBtn];

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(160, 168, 150, 35);
    [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    clearBtn.backgroundColor = [UIColor colorWithRed:0.7 green:0.1 blue:0.1 alpha:1.0];
    clearBtn.layer.cornerRadius = 6.0f;
    [clearBtn addTarget:self action:@selector(clearScriptAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewUseScript addSubview:clearBtn];

    // قسم الحفظ (اختر اسم للسكربت + زر حفظ)
    self.scriptNameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 215, 195, 34)];
    self.scriptNameField.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0];
    self.scriptNameField.textColor = [UIColor whiteColor];
    self.scriptNameField.placeholder = @" اختر اسم السكربت...";
    self.scriptNameField.font = [UIFont systemFontOfSize:12];
    self.scriptNameField.layer.cornerRadius = 6.0f;
    self.scriptNameField.delegate = self;
    self.scriptNameField.inputAccessoryView = keyboardToolbar;
    [self.viewUseScript addSubview:self.scriptNameField];

    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(205, 215, 105, 34);
    [saveBtn setTitle:@"حفظ السكربت" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0];
    saveBtn.layer.cornerRadius = 6.0f;
    saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [saveBtn addTarget:self action:@selector(saveCurrentScript:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewUseScript addSubview:saveBtn];

    [self.contentContainer addSubview:self.viewUseScript];
}

- (void)dismissKeyboard {
    [self.scriptInputBox resignFirstResponder];
    [self.scriptNameField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)setupSavedView {
    self.viewSaved = [[UIView alloc] initWithFrame:self.contentContainer.bounds];

    UILabel *savedHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 310, 25)];
    savedHeader.text = @"السكربتات المحفوظة (اضغط Run لتشغيلها):";
    savedHeader.textColor = [UIColor lightGrayColor];
    savedHeader.font = [UIFont systemFontOfSize:11.0];
    [self.viewSaved addSubview:savedHeader];

    self.savedScriptsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, 310, 240) style:UITableViewStylePlain];
    self.savedScriptsTable.backgroundColor = [UIColor clearColor];
    self.savedScriptsTable.delegate = self;
    self.savedScriptsTable.dataSource = self;
    [self.viewSaved addSubview:self.savedScriptsTable];

    [self.contentContainer addSubview:self.viewSaved];
}

- (void)setupAboutView {
    self.viewAbout = [[UIView alloc] initWithFrame:self.contentContainer.bounds];

    CGFloat btnY = 20;
    
    // زر 1: قناة التليجرام
    UIButton *tgChannelBtn = [self createLinkButton:@"1- قناتي تيلجرام" frame:CGRectMake(10, btnY, 290, 45)];
    [tgChannelBtn addTarget:self action:@selector(openTgChannel) forControlEvents:UIControlEventTouchUpInside];
    [self.viewAbout addSubview:tgChannelBtn];

    btnY += 60;
    // زر 2: حسابي تيلجرام
    UIButton *tgAccountBtn = [self createLinkButton:@"2- حسابي تيلجرام" frame:CGRectMake(10, btnY, 290, 45)];
    [tgAccountBtn addTarget:self action:@selector(openTgAccount) forControlEvents:UIControlEventTouchUpInside];
    [self.viewAbout addSubview:tgAccountBtn];

    btnY += 60;
    // زر 3: مساعد المطور
    UIButton *devHelperBtn = [self createLinkButton:@"3- مساعد المطور" frame:CGRectMake(10, btnY, 290, 45)];
    [devHelperBtn addTarget:self action:@selector(openDevHelper) forControlEvents:UIControlEventTouchUpInside];
    [self.viewAbout addSubview:devHelperBtn];

    [self.contentContainer addSubview:self.viewAbout];
}

- (UIButton *)createLinkButton:(NSString *)title frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.16 alpha:1.0];
    btn.layer.cornerRadius = 8.0f;
    btn.layer.borderWidth = 1.0f;
    btn.layer.borderColor = [UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0].CGColor;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    return btn;
}

- (void)openTgChannel {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/Harper_chat"] options:@{} completionHandler:nil];
}

- (void)openTgAccount {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/oa4nq"] options:@{} completionHandler:nil];
}

- (void)openDevHelper {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/HRP_Harper"] options:@{} completionHandler:nil];
}

- (void)switchTabToUseScript:(id)sender {
    self.viewUseScript.hidden = NO;
    self.viewSaved.hidden = YES;
    self.viewAbout.hidden = YES;
    [self styleActiveTab:self.tabUseScriptBtn];
}

- (void)switchTabToSaved:(id)sender {
    self.viewUseScript.hidden = YES;
    self.viewSaved.hidden = NO;
    self.viewAbout.hidden = YES;
    [self styleActiveTab:self.tabSavedBtn];
    [self.savedScriptsTable reloadData];
}

- (void)switchTabToAbout:(id)sender {
    self.viewUseScript.hidden = YES;
    self.viewSaved.hidden = YES;
    self.viewAbout.hidden = NO;
    [self styleActiveTab:self.tabAboutBtn];
}

- (void)styleActiveTab:(UIButton *)activeBtn {
    NSArray *allTabs = @[self.tabUseScriptBtn, self.tabSavedBtn, self.tabAboutBtn];
    for (UIButton *b in allTabs) {
        if (b == activeBtn) {
            b.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:1.0];
            [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            b.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0];
            [b setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        }
    }
}

- (void)toggleMenuVisibility {
    self.mainPanel.hidden = !self.mainPanel.hidden;
    if (!self.mainPanel.hidden) {
        UIWindow *window = [self activeWindow];
        if (window) {
            [window bringSubviewToFront:self.mainPanel];
            [window bringSubviewToFront:self.floatingButton];
        }
    }
}

- (void)executeScriptAction:(id)sender {
    NSString *codeToRun = self.scriptInputBox.text;
    if (codeToRun.length > 0) {
        NSLog(@"[Melux MX] Executing script:\n%@", codeToRun);
        
        // الأوفست الفعلي الذي تم استخراجه من غيدرا
        uint64_t luauExecOffset = 0x10085ae58;
        
        // حساب الـ Slide لتجاوز حماية الـ ASLR في الآيفون
        uint64_t slide = _dyld_get_image_vmaddr_slide(0);
        uint64_t targetFunctionAddress = slide + luauExecOffset;
        
        if (targetFunctionAddress != 0) {
            // ربط دالة التنفيذ مع العنوان الفعلي في الذاكرة
            typedef void (*LuauExecuteFunction)(const char *script);
            LuauExecuteFunction executeLua = (LuauExecuteFunction)targetFunctionAddress;
            
            // تنفيذ السكربت
            const char *utf8Script = [codeToRun UTF8String];
            executeLua(utf8Script);
            
            NSLog(@"[Melux MX] Script executed at address: 0x%llx", targetFunctionAddress);
        } else {
            NSLog(@"[Melux MX] Error: Failed to resolve target memory address.");
        }
    }
}

- (void)clearScriptAction:(id)sender {
    self.scriptInputBox.text = @"";
}

- (void)saveCurrentScript:(id)sender {
    NSString *name = [self.scriptNameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *code = self.scriptInputBox.text;
    if (name.length == 0 || code.length == 0) return;

    NSDictionary *scriptDict = @{@"name": name, @"code": code};
    [self.savedScriptsArray addObject:scriptDict];
    [[NSUserDefaults standardUserDefaults] setObject:self.savedScriptsArray forKey:@"MXSavedScripts"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.savedScriptsTable reloadData];
    
    self.scriptNameField.text = @"";
    [self dismissKeyboard];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.savedScriptsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"MXCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:1.0];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
        
        // زر Run السريع لكل سكربت محفوظ
        UIButton *runBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        runBtn.frame = CGRectMake(0, 0, 65, 26);
        [runBtn setTitle:@"Run" forState:UIControlStateNormal];
        [runBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        runBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:1.0];
        runBtn.layer.cornerRadius = 4.0f;
        [runBtn addTarget:self action:@selector(runSavedScriptFromButton:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = runBtn;
    }
    
    if (indexPath.row < self.savedScriptsArray.count) {
        NSDictionary *item = self.savedScriptsArray[indexPath.row];
        cell.textLabel.text = item[@"name"];
    }
    return cell;
}

- (void)runSavedScriptFromButton:(UIButton *)sender {
    UITableViewCell *cell = (UITableViewCell *)[sender superview];
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)[cell superview];
    }
    if (cell) {
        NSIndexPath *indexPath = [self.savedScriptsTable indexPathForCell:cell];
        if (indexPath && indexPath.row < self.savedScriptsArray.count) {
            NSDictionary *item = self.savedScriptsArray[indexPath.row];
            self.scriptInputBox.text = item[@"code"];
            [self switchTabToUseScript:nil];
            [self executeScriptAction:nil];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= self.savedScriptsArray.count) return;
    NSDictionary *item = self.savedScriptsArray[indexPath.row];
    self.scriptInputBox.text = item[@"code"];
    [self switchTabToUseScript:nil];
}

@end

__attribute__((constructor))
static void mx_entry(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (mxMenuController != nil) {
            return;
        }

        MXMenuController *controller = [[MXMenuController alloc] init];
        mxMenuController = controller;
        [controller loadViewIfNeeded];
    });
}
