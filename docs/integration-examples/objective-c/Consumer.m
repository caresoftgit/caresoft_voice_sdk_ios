#import <UIKit/UIKit.h>
@import CaresoftVoice;
@interface ConsumerApp : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ConsumerApp
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
 CSVoiceConfiguration *config=[CSVoiceConfiguration new];
 config.domain=@"tenant"; config.appId=@"app"; config.apiBaseURL=[NSURL URLWithString:@"https://api.example.test"]; config.installationId=@"test-install";
 NSError *error=nil;
 CSVoiceClient *client=[[CSVoiceClient alloc] initWithConfiguration:config error:&error tokenProvider:^(void (^completion)(NSString *,NSError *)){completion(@"example",nil);}];
 NSDictionary *snapshot=client.snapshot;
 NSCAssert(snapshot != nil || error != nil,@"Typed consumer returns a snapshot or error");
 [client disposeWithCompletion:^{}];
 return YES;
}
@end
int main(int argc,char *argv[]){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(ConsumerApp.class));}}
