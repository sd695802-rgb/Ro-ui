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

static inline float AxiomGetInfJumpHeight(void)
{
    return infJumpHeight;
}

static float customSpeed = 16.0f;
static BOOL saveRespawnEnabled = NO;

// Keep the controller alive.
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

- (void)setupFloatingButton;
- (void)setupMainPanel;

@end

// ============================================================
// Implementation
// ============================================================

@implementation AxiomMenuController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    NSArray *storedScripts = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AxiomSavedScripts"];
    if (storedScripts.count > 0) {
        self.savedScriptsArray = [NSMutableArray arrayWithArray:storedScripts];
    } else {
        self.savedScriptsArray = [NSMutableArray arrayWithArray:@[
            @{@"name": @"Script 1", @"code": @"print('Axiom Script 1');"},
            @{@"name": @"Script 2", @"code": @"print('Axiom Script 2');"}
        ]];
    }

    [self setupFloatingButton];
    [self setupMainPanel];
}

#pragma mark - Floating Button (Small, Circular & Draggable)

- (void)setupFloatingButton
{
    if (self.floatingButton) return;

    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(40, 100, 44, 44);
    
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.90];
    self.floatingButton.layer.cornerRadius = 22.0f;
    self.floatingButton.layer.borderWidth = 2.0f;
    self.floatingButton.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0].CGColor;

    [self.floatingButton setTitle:@"AX" forState:UIControlStateNormal];
    [self.floatingButton setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0] forState:UIControlStateNormal];
    self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];

    [self.floatingButton addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
    [self.floatingButton addGestureRecognizer:panGesture];

    UIWindow *window = [self activeWindow];
    if (window) {
        [window addSubview:self.floatingButton];
        [window bringSubviewToFront:self.floatingButton];
    }
}

- (UIWindow *)activeWindow
{
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

- (void)handleButtonPan:(UIPanGestureRecognizer * _Nonnull)gesture
{
    UIWindow *window = [self activeWindow];
    CGPoint translation = [gesture translationInView:window];
    CGPoint recognizerCenter = gesture.view.center;
    
    gesture.view.center = CGPointMake(recognizerCenter.x + translation.x, recognizerCenter.y + translation.y);
    [gesture setTranslation:CGPointZero inView:window];
}

#pragma mark - Main Panel

- (void)setupMainPanel
{
    if (self.mainPanel) return;

    self.mainPanel = [[UIView alloc] initWithFrame:CGRectMake(80, 80, 320, 390)];
    self.mainPanel.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.12 alpha:0.96];
    self.mainPanel.layer.cornerRadius = 14.0f;
    self.mainPanel.layer.borderWidth = 1.5f;
    self.mainPanel.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
    self.mainPanel.hidden = YES;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 300, 25)];
    title.text = @"AXIOM'S ROBLOX CORE V1.0";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:13.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.mainPanel addSubview:title];

    CGFloat tabW = 96.0f;
    self.tabTogglesBtn = [self createTabButton:@"Toggles" frame:CGRectMake(10, 38, tabW, 30) action:@selector(switchTabToToggles:)];
    self.tabExecutorBtn = [self createTabButton:@"Executor" frame:CGRectMake(112, 38, tabW, 30) action:@selector(switchTabToExecutor:)];
    self.tabSaverBtn = [self createTabButton:@"Saved" frame:CGRectMake(214, 38, tabW, 30) action:@selector(switchTabToSaver:)];

    [self.mainPanel addSubview:self.tabTogglesBtn];
    [self.mainPanel addSubview:self.tabExecutorBtn];
    [self.mainPanel addSubview:self.tabSaverBtn];

    self.contentContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 75, 300, 305)];
    [self.mainPanel addSubview:self.contentContainer];

    UIWindow *window = [self activeWindow];
    if (window) {
        [window addSubview:self.mainPanel];
        [window bringSubviewToFront:self.mainPanel];
    }
}

- (UIButton *)createTabButton:(NSString *)title frame:(CGRect)frame action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    btn.layer.cornerRadius = 6.0f;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)toggleMenuVisibility
{
    self.mainPanel.hidden = !self.mainPanel.hidden;
    if (!self.mainPanel.hidden) {
        UIWindow *window = [self activeWindow];
        if (window) {
            [window bringSubviewToFront:self.mainPanel];
            [window bringSubviewToFront:self.floatingButton];
        }
    }
}

- (void)switchTabToToggles:(id)sender {}
- (void)switchTabToExecutor:(id)sender {}
- (void)switchTabToSaver:(id)sender {}

#pragma mark - UITableView DataSource (Fixing missing protocol methods)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.savedScriptsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"AxiomCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
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

@end

// ============================================================
// Constructor & Entry Hook
// ============================================================

__attribute__((constructor))
static void axiom_entry(void)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *candidate in windowScene.windows) {
                        if (candidate.isKeyWindow) { window = candidate; break; }
                    }
                }
                if (window) break;
            }
        }
        if (!window) {
            window = [UIApplication sharedApplication].keyWindow;
        }

        if (window && axiomMenuController == nil) {
            AxiomMenuController *controller = [[AxiomMenuController alloc] init];
            axiomMenuController = controller;
            NSLog(@"[Axiom] Menu successfully loaded and attached!");
        }
    });
}
