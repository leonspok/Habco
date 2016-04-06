//
//  HBCRecordingSettings+Converting.h
//  Habco
//
//  Created by Игорь Савельев on 06/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBCRecordingSettings.h"

@class HBRecordingSettings;

@interface HBCRecordingSettings (Converting)

+ (HBCRecordingSettings *)createOrUpdateFrom:(HBRecordingSettings *)recordingSettings inContext:(NSManagedObjectContext *)context;
- (HBRecordingSettings *)toHBRecordingSettings;

@end
