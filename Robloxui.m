#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <substrate.h>
#import <QuartzCore/QuartzCore.h>

// ============================================================
// Global Mod Variables
// ============================================================

static BOOL enableESP = NO;
static int espType = 0; // 0: Box, 1: Skeleton, 2: Line
static BOOL enableAimbot = NO;
static BOOL enableInfJump = YES;
static float infJumpHeight = 10.0f;

// منع -Werror,-Wunused-variable
static inline float AxiomGetInfJumpHeight(void)
{
    return infJumpHeight;
}

static float customSpeed = 16.0f;
static BOOL saveRespawnEnabled = NO;

// Keep the controller alive after creation.
static __strong id axiomMenuController = nil;


// ============================================================
// Forward Declarations
// ============================================================

@interface AxiomMenuController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *mainPanel;
@property (nonatomic, strong) UIView *contentContainer;

// Tabs
@property (nonatomic, strong) UIButton *tabTogglesBtn;
@property (nonatomic, strong) UIButton *tabExecutorBtn;
@property (nonatomic, strong) UIButton *tabSaverBtn;

// Views for tabs
@property (nonatomic, strong) UIView *viewToggles;
@property (nonatomic, strong) UIView *viewExecutor;
@property (nonatomic, strong) UIView *viewSaver;

// Executor components
@property (nonatomic, strong) UITextView *scriptInputBox;

// Saved Scripts Table
@property (nonatomic, strong) UITableView *savedScriptsTable;
@property (nonatomic, strong) NSMutableArray *savedScriptsArray;
@property (nonatomic, strong) UITextField *scriptNameField;

@end


// ============================================================
// Implementation
// ============================================================

@implementation AxiomMenuController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];

    NSArray *storedScripts =
    [[NSUserDefaults standardUserDefaults]
     arrayForKey:@"AxiomSavedScripts"];

    if (storedScripts.count > 0) {
        self.savedScriptsArray =
        [NSMutableArray arrayWithArray:storedScripts];
    } else {
        self.savedScriptsArray =
        [NSMutableArray arrayWithArray:@[
            @{@"name": @"Script 1", @"code": @"print('Axiom Script 1');"},
            @{@"name": @"Script 2", @"code": @"print('Axiom Script 2');"}
        ]];
    }

    [self setupFloatingButton];
    [self setupMainPanel];
}

#pragma mark - Window Helper

- (UIWindow *)activeWindow
{
    UIWindow *result = nil;

    if (@available(iOS 13.0, *)) {

        for (UIScene *scene in
             [UIApplication sharedApplication].connectedScenes) {

            if (scene.activationState !=
                UISceneActivationStateForegroundActive) {
                continue;
            }

            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene =
            (UIWindowScene *)scene;

            for (UIWindow *window in windowScene.windows) {

                if (window.isKeyWindow) {
                    result = window;
                    break;
                }
            }

            if (result != nil) {
                break;
            }

            if (windowScene.windows.count > 0) {
                result = windowScene.windows.firstObject;
            }
        }

    } else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }

    return result;
}

#pragma mark - Floating Button

- (void)setupFloatingButton
{
    self.floatingButton =
    [UIButton buttonWithType:UIButtonTypeCustom];

    self.floatingButton.frame =
    CGRectMake(30, 80, 45, 45);

    self.floatingButton.backgroundColor =
    [UIColor colorWithRed:0.05
                    green:0.05
                     blue:0.05
                    alpha:0.90];

    self.floatingButton.layer.cornerRadius = 22.5f;
    self.floatingButton.layer.borderWidth = 2.0f;

    self.floatingButton.layer.borderColor =
    [UIColor colorWithRed:0.0
                    green:1.0
                     blue:0.5
                    alpha:1.0].CGColor;

    [self.floatingButton
     setTitle:@"AX"
     forState:UIControlStateNormal];

    [self.floatingButton
     setTitleColor:[UIColor colorWithRed:0.0
                                  green:1.0
                                   blue:0.5
                                  alpha:1.0]
     forState:UIControlStateNormal];

    self.floatingButton.titleLabel.font =
    [UIFont boldSystemFontOfSize:14.0];

    [self.floatingButton
     addTarget:self
     action:@selector(toggleMenuVisibility)
     forControlEvents:UIControlEventTouchUpInside];

    UIWindow *window = [self activeWindow];

    if (window != nil) {
        [window addSubview:self.floatingButton];
    }
}

#pragma mark - Main Panel

- (void)setupMainPanel
{
    self.mainPanel =
    [[UIView alloc]
     initWithFrame:CGRectMake(80, 70, 320, 390)];

    self.mainPanel.backgroundColor =
    [UIColor colorWithRed:0.10
                    green:0.10
                     blue:0.12
                    alpha:0.96];

    self.mainPanel.layer.cornerRadius = 14.0f;
    self.mainPanel.layer.borderWidth = 1.5f;

    self.mainPanel.layer.borderColor =
    [UIColor colorWithRed:0.0
                    green:0.8
                     blue:1.0
                    alpha:1.0].CGColor;

    self.mainPanel.hidden = YES;

    UILabel *title =
    [[UILabel alloc]
     initWithFrame:CGRectMake(10, 8, 300, 25)];

    title.text = @"AXIOM'S ROBLOX CORE V1.0";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:13.0];
    title.textAlignment = NSTextAlignmentCenter;

    [self.mainPanel addSubview:title];

    CGFloat tabW = 96.0f;

    self.tabTogglesBtn =
    [self createTabButton:@"Toggles"
                     frame:CGRectMake(10, 38, tabW, 30)
                    action:@selector(switchTabToToggles:)];

    self.tabExecutorBtn =
    [self createTabButton:@"Executor"
                     frame:CGRectMake(112, 38, tabW, 30)
                    action:@selector(switchTabToExecutor:)];

    self.tabSaverBtn =
    [self createTabButton:@"Saved"
                     frame:CGRectMake(214, 38, tabW, 30)
                    action:@selector(switchTabToSaver:)];

    [self.mainPanel addSubview:self.tabTogglesBtn];
    [self.mainPanel addSubview:self.tabExecutorBtn];
    [self.mainPanel addSubview:self.tabSaverBtn];

    self.contentContainer =
    [[UIView alloc]
     initWithFrame:CGRectMake(10, 75, 300, 305)];

    [self.mainPanel addSubview:self.contentContainer];

    [self setupTogglesView];
    [self setupExecutorView];
    [self setupSaverView];

    [self switchTabToToggles:nil];

    UIWindow *window = [self activeWindow];

    if (window != nil) {
        [window addSubview:self.mainPanel];
    }
}

#pragma mark - Tab Button

- (UIButton *)createTabButton:(NSString *)title
                         frame:(CGRect)frame
                        action:(SEL)action
{
    UIButton *btn =
    [UIButton buttonWithType:UIButtonTypeSystem];

    btn.frame = frame;

    [btn setTitle:title
         forState:UIControlStateNormal];

    [btn setTitleColor:[UIColor lightGrayColor]
             forState:UIControlStateNormal];

    btn.backgroundColor =
    [UIColor colorWithWhite:0.2 alpha:1.0];

    btn.layer.cornerRadius = 6.0f;

    btn.titleLabel.font =
    [UIFont systemFontOfSize:12.0
                      weight:UIFontWeightMedium];

    [btn addTarget:self
            action:action
  forControlEvents:UIControlEventTouchUpInside];

    return btn;
}

#pragma mark - Toggles View

- (void)setupTogglesView
{
    self.viewToggles =
    [[UIView alloc]
     initWithFrame:self.contentContainer.bounds];

    UIScrollView *scroll =
    [[UIScrollView alloc]
     initWithFrame:self.viewToggles.bounds];

    scroll.contentSize =
    CGSizeMake(300, 420);

    CGFloat yPos = 10.0f;

    UISwitch *espSw =
    [[UISwitch alloc]
     initWithFrame:CGRectMake(10, yPos, 51, 31)];

    espSw.on = enableESP;

    [espSw addTarget:self
              action:@selector(onEspToggle:)
    forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:espSw];

    UILabel *espLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(75, yPos, 210, 31)];

    espLbl.text = @"Enable ESP All Players";
    espLbl.textColor = [UIColor whiteColor];
    espLbl.font = [UIFont systemFontOfSize:13];

    [scroll addSubview:espLbl];

    yPos += 45;

    UISegmentedControl *espSeg =
    [[UISegmentedControl alloc]
     initWithItems:@[@"Box", @"Skeleton", @"Line"]];

    espSeg.frame =
    CGRectMake(10, yPos, 280, 30);

    espSeg.selectedSegmentIndex = espType;

    [espSeg addTarget:self
               action:@selector(onEspTypeChange:)
     forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:espSeg];

    yPos += 45;

    UISwitch *aimSw =
    [[UISwitch alloc]
     initWithFrame:CGRectMake(10, yPos, 51, 31)];

    aimSw.on = enableAimbot;

    [aimSw addTarget:self
              action:@selector(onAimbotToggle:)
    forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:aimSw];

    UILabel *aimLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(75, yPos, 210, 31)];

    aimLbl.text = @"Aimbot (Nearest Enemy)";
    aimLbl.textColor = [UIColor whiteColor];
    aimLbl.font = [UIFont systemFontOfSize:13];

    [scroll addSubview:aimLbl];

    yPos += 45;

    UISwitch *jumpSw =
    [[UISwitch alloc]
     initWithFrame:CGRectMake(10, yPos, 51, 31)];

    [jumpSw setOn:enableInfJump];

    [jumpSw addTarget:self
               action:@selector(onInfJumpToggle:)
     forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:jumpSw];

    UILabel *jumpLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(75, yPos, 210, 31)];

    jumpLbl.text = @"Infinite Jump";
    jumpLbl.textColor = [UIColor whiteColor];
    jumpLbl.font = [UIFont systemFontOfSize:13];

    [scroll addSubview:jumpLbl];

    yPos += 40;

    UILabel *spdLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(10, yPos, 280, 20)];

    spdLbl.text = @"Speed Multiplier";
    spdLbl.textColor = [UIColor lightGrayColor];
    spdLbl.tag = 888;
    spdLbl.font = [UIFont systemFontOfSize:11];

    [scroll addSubview:spdLbl];

    yPos += 20;

    UISlider *spdSlider =
    [[UISlider alloc]
     initWithFrame:CGRectMake(10, yPos, 280, 30)];

    spdSlider.minimumValue = 16.0f;
    spdSlider.maximumValue = 150.0f;
    spdSlider.value = customSpeed;

    [spdSlider addTarget:self
                  action:@selector(onSpeedChange:)
        forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:spdSlider];

    yPos += 45;

    UISwitch *respawnSw =
    [[UISwitch alloc]
     initWithFrame:CGRectMake(10, yPos, 51, 31)];

    respawnSw.on = saveRespawnEnabled;

    [respawnSw addTarget:self
                  action:@selector(onRespawnToggle:)
        forControlEvents:UIControlEventValueChanged];

    [scroll addSubview:respawnSw];

    UILabel *respawnLbl =
    [[UILabel alloc]
     initWithFrame:CGRectMake(75, yPos, 210, 31)];

    respawnLbl.text = @"Save Respawn Position";
    respawnLbl.textColor = [UIColor whiteColor];
    respawnLbl.font = [UIFont systemFontOfSize:13];

    [scroll addSubview:respawnLbl];

    [self.viewToggles addSubview:scroll];

    [self.contentContainer addSubview:self.viewToggles];
}

#pragma mark - Executor View

- (void)setupExecutorView
{
    self.viewExecutor =
    [[UIView alloc]
     initWithFrame:self.contentContainer.bounds];

    self.scriptInputBox =
    [[UITextView alloc]
     initWithFrame:CGRectMake(10, 10, 280, 200)];

    self.scriptInputBox.backgroundColor =
    [UIColor colorWithWhite:0.05 alpha:1.0];

    self.scriptInputBox.textColor = [UIColor greenColor];

    self.scriptInputBox.font =
    [UIFont fontWithName:@"Courier"
                    size:12];

    self.scriptInputBox.text =
    @"-- Type or paste your Lua script here\n"
     "print('Axiom Executor Ready');";

    self.scriptInputBox.layer.cornerRadius = 6.0f;

    [self.viewExecutor addSubview:self.scriptInputBox];

    UIButton *execBtn =
    [UIButton buttonWithType:UIButtonTypeSystem];

    execBtn.frame =
    CGRectMake(10, 225, 135, 35);

    [execBtn setTitle:@"Execute"
             forState:UIControlStateNormal];

    [execBtn setTitleColor:[UIColor whiteColor]
                  forState:UIControlStateNormal];

    execBtn.backgroundColor =
    [UIColor colorWithRed:0.0
                    green:0.5
                     blue:0.2
                    alpha:1.0];

    execBtn.layer.cornerRadius = 6.0f;

    [execBtn addTarget:self
                action:@selector(executeScriptAction:)
      forControlEvents:UIControlEventTouchUpInside];

    [self.viewExecutor addSubview:execBtn];

    UIButton *clearBtn =
    [UIButton buttonWithType:UIButtonTypeSystem];

    clearBtn.frame =
    CGRectMake(155, 225, 135, 35);

    [clearBtn setTitle:@"Clear"
              forState:UIControlStateNormal];

    [clearBtn setTitleColor:[UIColor whiteColor]
                   forState:UIControlStateNormal];

    clearBtn.backgroundColor =
    [UIColor colorWithRed:0.6
                    green:0.1
                     blue:0.1
                    alpha:1.0];

    clearBtn.layer.cornerRadius = 6.0f;

    [clearBtn addTarget:self
                 action:@selector(clearScriptAction:)
       forControlEvents:UIControlEventTouchUpInside];

    [self.viewExecutor addSubview:clearBtn];

    [self.contentContainer addSubview:self.viewExecutor];
}

#pragma mark - Saver View

- (void)setupSaverView
{
    self.viewSaver =
    [[UIView alloc]
     initWithFrame:self.contentContainer.bounds];

    self.scriptNameField =
    [[UITextField alloc]
     initWithFrame:CGRectMake(10, 10, 180, 30)];

    self.scriptNameField.backgroundColor =
    [UIColor colorWithWhite:0.2 alpha:1.0];

    self.scriptNameField.textColor =
    [UIColor whiteColor];

    self.scriptNameField.placeholder =
    @" Script Name";

    self.scriptNameField.font =
    [UIFont systemFontOfSize:12];

    self.scriptNameField.layer.cornerRadius = 4.0f;

    [self.viewSaver addSubview:self.scriptNameField];

    UIButton *saveBtn =
    [UIButton buttonWithType:UIButtonTypeSystem];

    saveBtn.frame =
    CGRectMake(200, 10, 90, 30);

    [saveBtn setTitle:@"Save Current"
             forState:UIControlStateNormal];

    [saveBtn setTitleColor:[UIColor whiteColor]
                  forState:UIControlStateNormal];

    saveBtn.backgroundColor =
    [UIColor colorWithRed:0.0
                    green:0.4
                     blue:0.8
                    alpha:1.0];

    saveBtn.layer.cornerRadius = 4.0f;

    saveBtn.titleLabel.font =
    [UIFont systemFontOfSize:11];

    [saveBtn addTarget:self
                action:@selector(saveCurrentScript:)
      forControlEvents:UIControlEventTouchUpInside];

    [self.viewSaver addSubview:saveBtn];

    self.savedScriptsTable =
    [[UITableView alloc]
     initWithFrame:CGRectMake(10, 50, 280, 240)
             style:UITableViewStylePlain];

    self.savedScriptsTable.backgroundColor =
    [UIColor clearColor];

    self.savedScriptsTable.delegate = self;
    self.savedScriptsTable.dataSource = self;

    [self.viewSaver addSubview:self.savedScriptsTable];

    [self.contentContainer addSubview:self.viewSaver];
}

#pragma mark - Tabs

- (void)switchTabToToggles:(id)sender
{
    self.viewToggles.hidden = NO;
    self.viewExecutor.hidden = YES;
    self.viewSaver.hidden = YES;

    [self styleActiveTab:self.tabTogglesBtn];
}

- (void)switchTabToExecutor:(id)sender
{
    self.viewToggles.hidden = YES;
    self.viewExecutor.hidden = NO;
    self.viewSaver.hidden = YES;

    [self styleActiveTab:self.tabExecutorBtn];
}

- (void)switchTabToSaver:(id)sender
{
    self.viewToggles.hidden = YES;
    self.viewExecutor.hidden = YES;
    self.viewSaver.hidden = NO;

    [self styleActiveTab:self.tabSaverBtn];
}

- (void)styleActiveTab:(UIButton *)activeBtn
{
    NSArray *allTabs = @[
        self.tabTogglesBtn,
        self.tabExecutorBtn,
        self.tabSaverBtn
    ];

    for (UIButton *b in allTabs) {

        if (b == activeBtn) {

            b.backgroundColor =
            [UIColor colorWithRed:0.0
                            green:0.6
                             blue:0.8
                            alpha:1.0];

            [b setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];

        } else {

            b.backgroundColor =
            [UIColor colorWithWhite:0.2 alpha:1.0];

            [b setTitleColor:[UIColor lightGrayColor]
                    forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Menu

- (void)toggleMenuVisibility
{
    self.mainPanel.hidden =
    !self.mainPanel.hidden;
}

#pragma mark - Toggle Callbacks

- (void)onEspToggle:(UISwitch *)sender
{
    enableESP = sender.isOn;
}

- (void)onEspTypeChange:(UISegmentedControl *)sender
{
    espType =
    (int)sender.selectedSegmentIndex;
}

- (void)onAimbotToggle:(UISwitch *)sender
{
    enableAimbot = sender.isOn;
}

- (void)onInfJumpToggle:(UISwitch *)sender
{
    enableInfJump = sender.isOn;
    float jumpHeight = AxiomGetInfJumpHeight();
    (void)jumpHeight;
}

- (void)onSpeedChange:(UISlider *)sender
{
    customSpeed = sender.value;
}

- (void)onRespawnToggle:(UISwitch *)sender
{
    saveRespawnEnabled = sender.isOn;
}

#pragma mark - Script UI

- (void)executeScriptAction:(id)sender
{
    NSString *codeToRun = self.scriptInputBox.text;
    if (codeToRun.length > 0) {
        NSLog(@"[Axiom] Executing script: %@", codeToRun);
    }
}

- (void)clearScriptAction:(id)sender
{
    self.scriptInputBox.text = @"";
}

- (void)saveCurrentScript:(id)sender
{
    NSString *name =
    [self.scriptNameField.text
     stringByTrimmingCharactersInSet:
     [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *code = self.scriptInputBox.text;

    if (name.length == 0) {
        return;
    }

    NSDictionary *scriptDict = @{
        @"name": name,
        @"code": code ? code : @""
    };

    [self.savedScriptsArray addObject:scriptDict];

    [[NSUserDefaults standardUserDefaults]
     setObject:self.savedScriptsArray
     forKey:@"AxiomSavedScripts"];

    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.savedScriptsTable reloadData];

    self.scriptNameField.text = @"";
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.savedScriptsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"AxiomCell";

    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:cellID];

    if (cell == nil) {
        cell =
        [[UITableViewCell alloc]
         initWithStyle:UITableViewCellStyleDefault
         reuseIdentifier:cellID];

        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }

    if (indexPath.row < self.savedScriptsArray.count) {
        NSDictionary *item = self.savedScriptsArray[indexPath.row];
        cell.textLabel.text = item[@"name"];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];

    if (indexPath.row >= self.savedScriptsArray.count) {
        return;
    }

    NSDictionary *item = self.savedScriptsArray[indexPath.row];
    self.scriptInputBox.text = item[@"code"];

    [self switchTabToExecutor:nil];
}

@end


// ============================================================
// Constructor
// ============================================================

__attribute__((constructor))
static void axiom_entry(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{

        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(3.0 * NSEC_PER_SEC)
            ),
            dispatch_get_main_queue(),
            ^{

                UIWindow *window = nil;

                if (@available(iOS 13.0, *)) {

                    for (UIScene *scene in
                         [UIApplication sharedApplication].connectedScenes) {

                        if (scene.activationState !=
                            UISceneActivationStateForegroundActive) {
                            continue;
                        }

                        if (![scene
                              isKindOfClass:[UIWindowScene class]]) {
                            continue;
                        }

                        UIWindowScene *windowScene =
                        (UIWindowScene *)scene;

                        for (UIWindow *candidate
                             in windowScene.windows) {

                            if (candidate.isKeyWindow) {
                                window = candidate;
                                break;
                            }
                        }

                        if (window != nil) {
                            break;
                        }
                    }

                } else {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    window =
                    [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
                }

                if (window == nil) {
                    return;
                }

                if (axiomMenuController != nil) {
                    return;
                }

                AxiomMenuController *controller =
                [[AxiomMenuController alloc] init];

                axiomMenuController = controller;

                (void)controller;
            }
        );
    });
}
