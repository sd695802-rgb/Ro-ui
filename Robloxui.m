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

    // زر دائري صغير (مثلاً 44x44 بكسل)
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(40, 100, 44, 44);
    
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.90];
    self.floatingButton.layer.cornerRadius = 22.0f; // نصف العرض ليكون دائرياً تماماً
    self.floatingButton.layer.borderWidth = 2.0f;
    self.floatingButton.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0].CGColor;

    [self.floatingButton setTitle:@"AX" forState:UIControlStateNormal];
    [self.floatingButton setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.5 alpha:1.0] forState:UIControlStateNormal];
    self.floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];

    // إضافة إجراء الضغط لإظهار/إخفاء القائمة
    [self.floatingButton addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];

    // إضافة خاصية السحب (Pan Gesture) لتحريك الزر في أي مكان بالشاشة
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
    [self.floatingButton addGestureRecognizer:panGesture];

    // إضافته فوق نافذة التطبيق النشطة
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

// دالة تحريك الزر العائم بالإصبع
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
    self.mainPanel.hidden = YES; // مخفية افتراضياً حتى تضغط الزر العائم

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
