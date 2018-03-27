//
//  LocationFormatter.m
//  PhotosTest
//
//  Created by Nick on 25/03/2018.
//  Copyright © 2018 Nick Dowell. All rights reserved.
//

#import "LocationFormatter.h"

#import <CoreLocation/CoreLocation.h>

@implementation LocationFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    NSParameterAssert([obj isKindOfClass:[CLLocation class]]);
    CLLocation *location = obj;
    return [NSString stringWithFormat:@"%+f,%+f", location.coordinate.latitude, location.coordinate.longitude];
}

@end
