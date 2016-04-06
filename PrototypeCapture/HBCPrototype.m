//
//  HBCPrototype.m
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"
#import "HBCRecordingSettings.h"

@implementation HBCPrototype

- (NSDictionary *)jsonRepresentation {
    NSMutableDictionary *jsonRep = [NSMutableDictionary dictionary];
    if (self.uid) {
        [jsonRep setObject:self.uid forKey:@"uid"];
    }
    if (self.name) {
        [jsonRep setObject:self.name forKey:@"name"];
    }
    if (self.prototypeDescription) {
        [jsonRep setObject:self.prototypeDescription forKey:@"bio"];
    }
    if (self.dateCreated) {
        [jsonRep setObject:self.dateCreated forKey:@"date_created"];
    }
    if (self.url) {
        [jsonRep setObject:self.url forKey:@"url"];
    }
    return jsonRep;
}

@end
