__attribute__((constructor))
static void axiom_entry(void)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (axiomMenuController != nil) {
            return;
        }

        AxiomMenuController *controller = [[AxiomMenuController alloc] init];
        axiomMenuController = controller;
        
        // إجبار تحميل الـ View لضمان تنفيذ viewDidLoad وعرض الزر العائم والقائمة فوراً
        [controller loadViewIfNeeded];
    });
}
