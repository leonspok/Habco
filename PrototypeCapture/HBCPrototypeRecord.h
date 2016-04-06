//
//  HBCPrototypeRecord.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBCPrototypeRecord : NSManagedObject

- (NSDictionary *)jsonRepresentation;

@end

NS_ASSUME_NONNULL_END

#import "HBCPrototypeRecord+CoreDataProperties.h"
