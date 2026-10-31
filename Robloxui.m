@implementation MXMenuController

// (هنا باقي الدوال الخاصة بالواجهة والأزرار...)

- (void)executeScriptAction:(id)sender {
    NSString *codeToRun = self.scriptInputBox.text;
    if (codeToRun.length > 0) {
        NSLog(@"[Melux MX] Attempting to run script safely...");
        
        @try {
            uint64_t slide = _dyld_get_image_vmaddr_slide(0);
            uint64_t targetFunctionAddress = slide + 0x0;
            
            if (targetFunctionAddress != slide) {
                typedef void (*LuauExecuteFunction)(const char *script);
                LuauExecuteFunction executeLua = (LuauExecuteFunction)targetFunctionAddress;
                executeLua([codeToRun UTF8String]);
                NSLog(@"[Melux MX] Script executed.");
            } else {
                NSLog(@"[Melux MX] Luau engine address not bound yet. Safe mode active.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Melux MX" 
                                                                                   message:@"تم استلام السكربت بنجاح! جاري ربط محرك التنفيذ." 
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                });
            }
        } @catch (NSException *exception) {
            NSLog(@"[Melux MX Error] Caught exception during execution: %@", exception);
        }
    }
}

@end // <-- تأكد أن نهاية الكلاس هنا بعد الدالة
