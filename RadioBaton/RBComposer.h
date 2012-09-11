//
//  RBComposer.h
//  RadioBaton
//
//  Created by Greg Cerveny on 9/9/12.
//  Copyright (c) 2012 Artful Medium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface RBComposer : NSObject

@property (nonatomic, assign) Float64 scaleRate;

- (void)createAUGraph;
- (void)loadPreset;

- (void)loadMusicNamed:(NSString *)musicName;
- (void)createMusicPlayer;

- (void)togglePlay;
- (void)playWithScalerRate:(Float64)scalerRate;
- (void)playForBeats:(MusicTimeStamp)beats;


@end
