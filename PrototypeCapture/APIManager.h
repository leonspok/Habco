//
//  APIManager.h
//  Habco
//
//  Created by Ildar Zalyalov on 05.01.17.
//  Copyright © 2017 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface APIManager : NSObject
+ (instancetype)sharedInstance;
- (void)sendUserData:(NSDictionary *)data sucess:(void (^)(BOOL sucess))success
             failure:(void (^)(NSError *error))failure;

@end
