
// Shortcuts
#define APP ((AppDelegate *)[[UIApplication sharedApplication] delegate])
#define ASYNC_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define SCREEN_SIZE ([[UIScreen mainScreen] bounds].size)
#define IS_OLD_IPHONE ([[UIScreen mainScreen] bounds].size.height < 568)
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define IS_NEW_IPHONE ([[UIScreen mainScreen] bounds].size.height > 568)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IOS7 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
#define IS_IOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

// Helpers
#ifdef DEBUG
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else
#define DLog(...)
#ifndef NS_BLOCK_ASSERTIONS
#define NS_BLOCK_ASSERTIONS
#endif
#define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif

// API
#define API_BASE_URL [[[NSBundle mainBundle] infoDictionary] valueForKey:@"API_BASE_URL"]

// Colors
#define RGB(r, g, b) [UIColor colorWithRed:r/256.0 green:g/256.0 blue:b/256.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/256.0 green:g/256.0 blue:b/256.0 alpha:a]
#define PPRED [UIColor colorWithRed:211.0/256.0 green:21.0/256.0 blue:13.0/256.0 alpha:1];

// Contacts
#define CONTACT_PHONE @""
#define CONTACT_EMAIL @""

// Fonts
#define FONT_DEFAULT_NAME @"HelveticaNeue"
#define FONT_DEFAULT_BOLD_NAME @"HelveticaNeue-Bold"
#define FONT_DEFAULT [UIFont fontWithName:FONT_DEFAULT_NAME size:18.0]
#define FONT_DEFAULT_BOLD [UIFont fontWithName:FONT_DEFAULT_BOLD_NAME size:18.0]


typedef enum {
    UserName,
    AppName,
    AppRecords,
} MenuControllers;

#define appDataDictString(enum) [@[@"userName",@"appName",@"appRecords"] objectAtIndex:enum]

