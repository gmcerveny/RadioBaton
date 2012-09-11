//
//  RBViewController.m
//  RadioBaton
//
//  Created by Greg Cerveny on 9/7/12.
//  Copyright (c) 2012 Artful Medium. All rights reserved.
//

#import "RBViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "RBComposer.h"


@interface RBViewController ()

@property (nonatomic, strong) RBComposer *myComposer;

@end

@implementation RBViewController

@synthesize myComposer;

- (void)animateView
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionAutoreverse
                     animations:^(void){
                         self.view.backgroundColor = [UIColor greenColor];
                     }
                     completion:^(BOOL finished){
                         self.view.backgroundColor = [UIColor whiteColor];
                     }];
}

-(void)handleTap:(UIGestureRecognizer*)gestureRecognizer
{
//    [self.myComposer togglePlay];
//    [self.myComposer playForBeats:1.0];

    CGPoint location = [gestureRecognizer locationInView:self.view];
    Float64 vector = 1 - location.y / self.view.bounds.size.height;
    [self.myComposer playWithScalerRate:vector*2.0];
    
    
    [self animateView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.myComposer = [[RBComposer alloc] init];
    
    [self.myComposer createAUGraph];
    [self.myComposer loadPreset];
    
    [self.myComposer loadMusicNamed:@"moonlight1"];
    [self.myComposer createMusicPlayer];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
