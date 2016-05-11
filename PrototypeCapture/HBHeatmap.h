//
//  HBHeatmap.h
//  Habco
//
//  Created by Игорь Савельев on 11/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HBHeatmap : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *baseFolder;
@property (nonatomic, strong) NSString *hash;

@property (nonatomic, strong, readonly) NSString *pathToScreenshot;
@property (nonatomic, strong, readonly) NSString *pathToHeatmap;
@property (nonatomic, strong, readonly) NSString *pathToHashFile;

- (id)initWithName:(NSString *)name baseFolder:(NSString *)baseFolder;

@end
