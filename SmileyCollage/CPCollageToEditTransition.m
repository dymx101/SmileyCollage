//
//  CPCollageToEditTransition.m
//  Smiley
//
//  Created by wangyw on 3/9/14.
//  Copyright (c) 2014 codingpotato. All rights reserved.
//

#import "CPCollageToEditTransition.h"

#import "CPCollageCell.h"
#import "CPCollageViewController.h"
#import "CPEditViewController.h"

@implementation CPCollageToEditTransition

- (void)animateForwardTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CPCollageViewController *collageViewController = (CPCollageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CPEditViewController *editViewController = (CPEditViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    CGRect finalFrame  = [transitionContext finalFrameForViewController:editViewController];
    
    [containerView addSubview:editViewController.view];
    editViewController.view.frame = finalFrame;
    editViewController.view.alpha = 0.0;
    
    UIView *selectedFace = collageViewController.selectedFace;
    UIView *snapshot = [selectedFace snapshotViewAfterScreenUpdates:NO];
    [containerView addSubview:snapshot];
    snapshot.frame = [containerView convertRect:selectedFace.bounds fromView:selectedFace];
    
    selectedFace.hidden = YES;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        snapshot.frame = [containerView convertRect:editViewController.faceIndicatorFrame fromView:editViewController.view];
    } completion:^(BOOL finished) {
        [snapshot removeFromSuperview];
        selectedFace.hidden = NO;
        [collageViewController.view removeFromSuperview];
        editViewController.view.alpha = 1.0;
        [transitionContext completeTransition:YES];
    }];
}

- (void)animateReverseTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CPEditViewController *editViewController = (CPEditViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CPCollageViewController *collageViewController = (CPCollageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    CGRect finalFrame  = [transitionContext finalFrameForViewController:collageViewController];
    
    [containerView addSubview:collageViewController.view];
    collageViewController.view.frame = finalFrame;
    [collageViewController reloadSelectedFace];
    UIView *selectedFace = collageViewController.selectedFace;
    selectedFace.hidden = YES;
    
    UIView *snapshot = editViewController.faceSnapshot;
    [containerView addSubview:snapshot];
    snapshot.frame = [containerView convertRect:editViewController.faceIndicatorFrame fromView:editViewController.view];
    
    [editViewController.view removeFromSuperview];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        snapshot.frame = [containerView convertRect:selectedFace.bounds fromView:selectedFace];
    } completion:^(BOOL finished) {
        [snapshot removeFromSuperview];
        selectedFace.hidden = NO;
        [transitionContext completeTransition:YES];
    }];
}

@end