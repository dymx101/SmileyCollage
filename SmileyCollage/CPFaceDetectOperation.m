//
//  CPFaceDetectOperation.m
//  Smiley
//
//  Created by wangyw on 3/25/14.
//  Copyright (c) 2014 codingpotato. All rights reserved.
//

#import "CPFaceDetectOperation.h"

#import "CPConfig.h"
#import "CPUtility.h"

#import "CPFace.h"
#import "CPFacesManager.h"
#import "CPPhoto.h"

@interface CPFaceDetectOperation ()

@property (strong, nonatomic) ALAsset *asset;

@end

@implementation CPFaceDetectOperation

- (id)initWithAsset:(ALAsset *)asset persistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    self = [super initWithPersistentStoreCoordinator:persistentStoreCoordinator];
    if (self) {
        self.asset = asset;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        NSAssert(self.asset, @"");
        
        NSTimeInterval scanTime = [NSDate timeIntervalSinceReferenceDate];
        NSURL *assetURL = [self.asset valueForProperty:ALAssetPropertyAssetURL];
        CPPhoto *photo = [CPPhoto photoOfURL:assetURL inManagedObjectContext:self.managedObjectContext];
        if (photo) {
            photo.scanTime = [NSNumber numberWithDouble:scanTime];
        } else {
            NSMutableDictionary *exifDictionary = [self.asset.defaultRepresentation.metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary];
            NSString *cameraOwnerName = [exifDictionary objectForKey:(NSString *)kCGImagePropertyExifCameraOwnerName];
            if (![cameraOwnerName isEqualToString:[CPFacesManager cameraOwnerName]]) {
                NSTimeInterval createTime = [[self.asset valueForProperty:ALAssetPropertyDate] timeIntervalSinceReferenceDate];
                photo = [CPPhoto photoWithURL:assetURL createTime:createTime scanTime:scanTime inManagedObjectContext:self.managedObjectContext];
                
                CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
                NSDictionary *options = @{CIDetectorSmile: @(YES), CIDetectorEyeBlink: @(YES)};
                
                CGImageRef image = self.asset.defaultRepresentation.fullScreenImage;
                CGFloat width = CGImageGetWidth(image);
                CGFloat height = CGImageGetHeight(image);
                NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image] options:options];
                for (CIFeature *feature in features) {
                    // reverse rectangle in y, because coordinate system of core image is different
                    CGRect bounds = CGRectMake(feature.bounds.origin.x, height - feature.bounds.origin.y - feature.bounds.size.height, feature.bounds.size.width, feature.bounds.size.height);
                    // enlarge maximum 1/3 bounds
                    CGFloat enlargeSize = bounds.size.width / 3;
                    enlargeSize = MIN(enlargeSize, bounds.origin.x);
                    enlargeSize = MIN(enlargeSize, bounds.origin.y);
                    enlargeSize = MIN(enlargeSize, width - bounds.origin.x - bounds.size.width);
                    enlargeSize = MIN(enlargeSize, height - bounds.origin.y - bounds.size.height);
                    bounds = CGRectInset(bounds, -enlargeSize, -enlargeSize);
                    
                    CPFace *face = [CPFace faceWithPhoto:photo bounds:bounds inManagedObjectContext:self.managedObjectContext];
                    [self writeThumbnailOfName:face.thumbnail fromImage:image bounds:bounds];
                }
            }
        }
        
        [self save];
    }
}

- (void)writeThumbnailOfName:(NSString *)name fromImage:(CGImageRef)image bounds:(CGRect)bounds {
    CGImageRef faceImage = CGImageCreateWithImageInRect(image, bounds);
    
    CGFloat size = MIN(bounds.size.width, [CPConfig thumbnailSize]);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, size, size), faceImage);
    UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(faceImage);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *thumbnailPath = [CPUtility thumbnailPath];
    if (![fileManager fileExistsAtPath:thumbnailPath]) {
        [fileManager createDirectoryAtPath:thumbnailPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *imagePath = [thumbnailPath stringByAppendingPathComponent:name];
    static const float compressionQuality = 0.6;
    NSData *imageJPEGRepresentationData = UIImageJPEGRepresentation(thumbnail, compressionQuality);
    [imageJPEGRepresentationData writeToFile:imagePath atomically:YES];
}

@end
