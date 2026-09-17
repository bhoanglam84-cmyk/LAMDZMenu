#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <sys/sysctl.h>

static BOOL detectScanner() {
    NSArray *bad = @[
        @"frida",@"frida-server",@"lldb",@"gdb",
        @"GameGuardian",@"iGameGuardian",
        @"cycript",@"clutch",@"Liberty",@"Flex3"
    ];
    int mib[4] = {CTL_KERN,KERN_PROC,KERN_PROC_ALL,0};
    size_t size;
    sysctl(mib,4,NULL,&size,NULL,0);
    struct kinfo_proc *procs = malloc(size);
    sysctl(mib,4,procs,&size,NULL,0);
    int count = (int)(size/sizeof(struct kinfo_proc));
    BOOL found = NO;
    for (int i=0;i<count;i++) {
        NSString *pname = [NSString stringWithUTF8String:
            procs[i].kp_proc.p_comm];
        for (NSString *b in bad) {
            if ([pname.lowercaseString
                containsString:b.lowercaseString]) {
                found = YES; break;
            }
        }
        if (found) break;
    }
    free(procs);
    return found;
}

static void antiDebug() {
    typedef int (*ptrace_t)(int,pid_t,caddr_t,int);
    ptrace_t pt = (ptrace_t)dlsym(RTLD_DEFAULT,"ptrace");
    if (pt) pt(31,0,0,0);
}

void initAntiDetect() {
    antiDebug();
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
            (arc4random_uniform(25)+15)*NSEC_PER_SEC/10),
        dispatch_get_main_queue(), ^{
            if (detectScanner()) {
                NSLog(@"[LAMDZ] Scanner detected");
            }
        });
    dispatch_source_t timer = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_TIMER,0,0,
        dispatch_get_global_queue(0,0));
    dispatch_source_set_timer(timer,
        dispatch_time(DISPATCH_TIME_NOW,30*NSEC_PER_SEC),
        30*NSEC_PER_SEC,1*NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (detectScanner())
            NSLog(@"[LAMDZ] Scanner running");
    });
    dispatch_resume(timer);
}
