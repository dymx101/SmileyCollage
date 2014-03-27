//
//  CPPhoto.m
//  Smiley
//
//  Created by wangyw on 3/15/14.
//  Copyright (c) 2014 codingpotato. All rights reserved.
//

#import "CPFace.h"
#import "CPPhoto.h"

@implementation CPPhoto

@dynamic timestamp;
@dynamic url;
@dynamic faces;

+ (CPPhoto *)createPhotoInManagedObjectContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
}

+ (NSArray *)photosInManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:context];
    request.sortDescriptors = [[NSArray alloc] initWithObjects:[[NSSortDescriptor alloc] initWithKey:@"url" ascending:YES], nil];
    return [context executeFetchRequest:request error:nil];
}

+ (CPPhoto *)photoOfAssetURL:(NSString *)assetURL inManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:context]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", assetURL];
    [request setPredicate:predicate];
    
    NSArray *array = [context executeFetchRequest:request error:nil];
    if (array.count > 0) {
        return [array objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (NSArray *)expiredPhotosWithTimestamp:(NSTimeInterval)timestamp fromManagedObjectContext:(NSManagedObjectContext *)context {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CPPhoto" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timestamp < %lf", timestamp];
    [request setPredicate:predicate];
    return [context executeFetchRequest:request error:nil];
}

@end
