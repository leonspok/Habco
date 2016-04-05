//
//  HBPrototypeRecord.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBPrototypeUser;

@interface HBPrototypeRecord : NSObject

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *pathToVideo;
@property (nonatomic, strong) HBPrototypeUser *user;

@end
