//
//  CPFacesViewController.m
//  Smiley
//
//  Created by wangyw on 3/2/14.
//  Copyright (c) 2014 codingpotato. All rights reserved.
//

#import "CPFacesViewController.h"

#import "CPConfig.h"
#import "CPUtility.h"

#import "CPPhotoCell.h"
#import "CPStitchViewController.h"

#import "CPFace.h"
#import "CPFaceEditInformation.h"
#import "CPFacesManager.h"
#import "CPPhoto.h"

@interface CPFacesViewController ()

@property (strong, nonatomic) CPFacesManager *facesManager;

@property (strong, nonatomic) NSMutableArray *selectedFaces;

@property (nonatomic) BOOL isScanCancelled;

@property (strong, nonatomic) UIView *bubbleView;
@property (strong, nonatomic) UILabel *bubbleLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notificationViewBottomConstraint;

@end

@implementation CPFacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.isScanCancelled = NO;
    self.facesManager.facesController.delegate = self;
    self.navigationItem.title = [NSString stringWithFormat:@"Faces: %d", (int)self.facesManager.facesController.fetchedObjects.count];
    
    [self showNotificationViewWithAnimation];
    [self.facesManager scanFaces];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewDidLayoutSubviews {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (self.facesManager.isScanning) {
        [self.facesManager stopScan];
        self.isScanCancelled = YES;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CPStitchViewControllerSegue"]) {
        CPStitchViewController *stitchViewController = (CPStitchViewController *)segue.destinationViewController;
        stitchViewController.facesManager = self.facesManager;
        
        stitchViewController.stitchedFaces = [[NSMutableArray alloc] initWithCapacity:self.selectedFaces.count];
        for (CPFace *face in self.selectedFaces) {
            CPFaceEditInformation *stitchedFace = [[CPFaceEditInformation alloc] init];
            stitchedFace.face = face;
            stitchedFace.asset = nil;
            [stitchViewController.stitchedFaces addObject:stitchedFace];
        }
    }
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notification {
    [self.facesManager addObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfScannedPhotos)) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [self.facesManager addObserver:self forKeyPath:NSStringFromSelector(@selector(isScanning)) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    
    if (self.isScanCancelled) {
        [self showNotificationViewWithAnimation];
        [self.facesManager scanFaces];
        self.isScanCancelled = NO;
    }
}

- (void)handleApplicationDidEnterBackgroundNotification:(NSNotification *)notification {
    [self.facesManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfScannedPhotos))];
    [self.facesManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(isScanning))];
    
    [self hideNotificationView];
    
    if (self.facesManager.isScanning) {
        [self.facesManager stopScan];
        self.isScanCancelled = YES;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(numberOfScannedPhotos))]) {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        if (![oldValue isEqual:newValue]) {
            self.progressView.progress = newValue.floatValue / self.facesManager.numberOfTotalPhotos;
            self.message.text = [NSString stringWithFormat:@"Scanned %d of %d photos", (int)self.facesManager.numberOfScannedPhotos, (int)self.facesManager.numberOfTotalPhotos];
        }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(isScanning))]) {
        NSNumber *oldValue = change[NSKeyValueChangeOldKey];
        NSNumber *newValue = change[NSKeyValueChangeNewKey];
        if (oldValue.boolValue && !newValue.boolValue) {
            [self hideNotificationViewWithAnimation];
        }
    }
}

- (void)showNotificationViewWithAnimation {
    self.progressView.progress = 0.0;
    self.message.text = @"Scanning photos......";
    self.notificationViewBottomConstraint.constant = 0.0;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)hideNotificationView {
    self.notificationViewBottomConstraint.constant = self.notificationView.bounds.size.height;
    [self.view layoutIfNeeded];
}

- (void)hideNotificationViewWithAnimation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        self.notificationViewBottomConstraint.constant = self.notificationView.bounds.size.height;
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
    });
}

- (void)showBubbleViewAtPosition:(CGPoint)position withSelectedNumber:(NSUInteger)selectedNumber maxSelectedNumber:(NSUInteger)maxSelectedNumber {
    if (!self.bubbleView) {
        self.bubbleView = [[UIView alloc] init];
        self.bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
        self.bubbleView.alpha = 0.9;
        self.bubbleView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.bubbleView];
        [self.view addConstraints:[CPUtility constraintsWithView:self.bubbleView alignToView:self.collectionView attributes:NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeNotAnAttribute]];
        [self.view addConstraint:[CPUtility constraintWithView:self.bubbleView attribute:NSLayoutAttributeTop alignToView:self.topLayoutGuide attribute:NSLayoutAttributeBaseline]];
        [self.view addConstraint:[CPUtility constraintWithView:self.bubbleView height:[CPConfig thumbnailSize] / 2]];
        
        self.bubbleLabel = [[UILabel alloc] init];
        self.bubbleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.bubbleLabel.textAlignment = NSTextAlignmentCenter;
        [self.bubbleView addSubview:self.bubbleLabel];
        [self.bubbleView addConstraints:[CPUtility constraintsWithView:self.bubbleLabel edgesAlignToView:self.bubbleView]];
    }
    self.bubbleLabel.text = [NSString stringWithFormat:@"Selected: %d   Maxium: %d ", (int)selectedNumber, (int)maxSelectedNumber];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBubbleView) object:nil];
    [self performSelector:@selector(hideBubbleView) withObject:nil afterDelay:2.0];
}

- (void)hideBubbleView {
    [self.bubbleView removeFromSuperview];
    self.bubbleView = nil;
    self.bubbleLabel = nil;
}

#pragma mark - NSFetchedResultsControllerDelegate implement

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    self.navigationItem.title = [NSString stringWithFormat:@"Faces: %d", (int)controller.fetchedObjects.count];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource implement

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.facesManager.facesController.fetchedObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CPPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CPPhotoCell" forIndexPath:indexPath];
    CPFace *face = [self.facesManager.facesController.fetchedObjects objectAtIndex:indexPath.row];
    cell.image = [self.facesManager thumbnailOfFace:face];
    cell.isSelected = [self.selectedFaces containsObject:face];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate implement

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    CPFace *face = [self.facesManager.facesController.fetchedObjects objectAtIndex:indexPath.row];
    NSAssert(face, @"");

    if ([self.selectedFaces containsObject:face]) {
        [self.selectedFaces removeObject:face];
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        if (self.selectedFaces.count < [CPStitchViewController maxNumberOfStitchedFaces]) {
            [self.selectedFaces addObject:face];
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    }
    UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
    CGPoint position = attributes.frame.origin;
    position.y += self.topLayoutGuide.length;
    [self showBubbleViewAtPosition:position withSelectedNumber:self.selectedFaces.count maxSelectedNumber:[CPStitchViewController maxNumberOfStitchedFaces]];
}

#pragma mark - UICollectionViewDelegateFlowLayout implement

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    int number = collectionView.bounds.size.width / [CPConfig thumbnailSize];
    CGFloat width = (collectionView.bounds.size.width - (number + 1) * 1.0) / number;
    return CGSizeMake(width, width);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 1.0;
}

#pragma mark - lazy init

- (CPFacesManager *)facesManager {
    if (!_facesManager) {
        _facesManager = [[CPFacesManager alloc] init];
    }
    return _facesManager;
}

- (NSMutableArray *)selectedFaces {
    if (!_selectedFaces) {
        _selectedFaces = [[NSMutableArray alloc] initWithCapacity:[CPStitchViewController maxNumberOfStitchedFaces]];
    }
    return _selectedFaces;
}

@end
