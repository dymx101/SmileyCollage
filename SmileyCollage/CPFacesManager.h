//
//  CPFacesManager.h
//  Smiley
//
//  Created by wangyw on 3/2/14.
//  Copyright (c) 2014 codingpotato. All rights reserved.
//

@class CPFace;

@interface CPFacesManager : NSObject

@property (strong, nonatomic) NSFetchedResultsController *facesController;

@property (nonatomic) BOOL isScanning;
@property (nonatomic) BOOL isScanCancelled;

@property (nonatomic) NSUInteger numberOfScannedPhotos;

@property (nonatomic) NSUInteger numberOfTotalPhotos;

+ (NSString *)cameraOwnerName;

- (void)scanFaces;

- (void)stopScan;

- (BOOL)isObjectExisting:(NSManagedObjectID *)objectID;

- (UIImage *)thumbnailOfFace:(CPFace *)face;

- (void)assertForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock;

- (void)saveStitchedImage:(UIImage *)image;

@end
