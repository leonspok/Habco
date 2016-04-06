//
//  HBCPrototypeUser.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototypeUser.h"
#import "HBCPrototype.h"
#import "HBCPrototypeRecord.h"

@implementation HBCPrototypeUser

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *jsonRep = [NSMutableDictionary dictionary];
    if (self.uid) {
        [jsonRep setObject:self.uid forKey:@"uid"];
    }
    if (self.name) {
        [jsonRep setObject:self.name forKey:@"name"];
    }
    if (self.bio) {
        [jsonRep setObject:self.bio forKey:@"bio"];
    }
    if (self.dateAdded) {
        [jsonRep setObject:self.dateAdded forKey:@"date_added"];
    }
    return jsonRep;
}

@end
