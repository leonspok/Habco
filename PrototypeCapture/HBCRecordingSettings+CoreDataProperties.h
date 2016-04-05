//
//  HBCRecordingSettings+CoreDataProperties.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "HBCRecordingSettings.h"

NS_ASSUME_NONNULL_BEGIN

@class HBCPrototype;

@interface HBCRecordingSettings (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *withTouches;
@property (nullable, nonatomic, retain) NSNumber *withFrontCamera;
@property (nullable, nonatomic, retain) NSNumber *maxFPS;
@property (nullable, nonatomic, retain) NSNumber *downscale;
@property (nullable, nonatomic, retain) HBCPrototype *prototype;

@end

NS_ASSUME_NONNULL_END
