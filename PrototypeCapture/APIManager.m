//
//  APIManager.m
//  Habco
//
//  Created by Ildar Zalyalov on 05.01.17.
//  Copyright © 2017 Leonspok. All rights reserved.
//

#import "APIManager.h"

@implementation APIManager

+ (instancetype)sharedInstance{
    static id _singleTon = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _singleTon = [[self alloc] init];
    });
    return _singleTon;
}

- (NSString *)apiURL:(NSString *)node {
    if(node != nil)
        return [NSString stringWithFormat:@"%@%@", API_BASE_URL, node];
    else
        return API_BASE_URL;
}

- (AFHTTPRequestOperationManager *)getManager {
    AFHTTPRequestOperationManager *_manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:API_BASE_URL]];
    _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    _manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",@"text/html", @"text/plain"]];
        
    _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    return _manager;
}

- (void)sendUserData:(NSDictionary *)data sucess:(void (^)(BOOL sucess))success
                     failure:(void (^)(NSError *error))failure{
    
    NSDictionary *parameters = @{
                           @"user_name":data[appDataDictString(UserName)],
                           @"app_name" :data[appDataDictString(AppName)],
                           @"data"     :data[appDataDictString(AppRecords)],
                           };
    NSString *endpoint = [NSString stringWithFormat:@"v1/record"];
    NSString *url = [self apiURL:endpoint];
    AFHTTPRequestOperationManager *manager = [self getManager];
    [manager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(true);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

@end
