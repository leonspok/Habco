//
//  HBHeatmap.m
//  Habco
//
//  Created by Игорь Савельев on 11/05/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBHeatmap.h"

@implementation HBHeatmap

- (id)initWithName:(NSString *)name baseFolder:(NSString *)baseFolder {
    if (name.length == 0 || baseFolder.length == 0) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        self.name = name;
        self.baseFolder = baseFolder;
    }
    return self;
}

- (void)setHash:(NSString *)hash {
    NSError *error;
    [hash writeToFile:self.pathToHashFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        DDLogError(@"Save hash file: %@", error);
    }
}

- (NSString *)hash {
    return [NSString stringWithContentsOfFile:self.pathToHashFile encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)pathToHashFile {
    return [self.baseFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.hash", self.name]];
}

- (NSString *)pathToScreenshot {
    return [self.baseFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_screenshot.png", self.name]];
}

- (NSString *)pathToHeatmap {
    return [self.baseFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_heatmap.png", self.name]];
}

@end
