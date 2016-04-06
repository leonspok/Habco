//
//  HBCPrototype.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HBCPrototypeUser, HBCRecordingSettings;

NS_ASSUME_NONNULL_BEGIN

@interface HBCPrototype : NSManagedObject

- (NSDictionary *)jsonRepresentation;

@end

NS_ASSUME_NONNULL_END

#import "HBCPrototype+CoreDataProperties.h"
