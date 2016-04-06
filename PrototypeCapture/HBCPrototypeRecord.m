//
//  HBCPrototypeRecord.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototypeRecord.h"

@implementation HBCPrototypeRecord

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *jsonRep = [NSMutableDictionary dictionary];
    if (self.uid) {
        [jsonRep setObject:self.uid forKey:@"uid"];
    }
    if (self.date) {
        [jsonRep setObject:self.date forKey:@"date"];
    }
    if (self.pathToVideo) {
        [jsonRep setObject:[self.pathToVideo lastPathComponent] forKey:@"video_filename"];
    }
    return jsonRep;
}

@end
