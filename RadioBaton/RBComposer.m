//
//  RBComposer.m
//  RadioBaton
//
//  Created by Greg Cerveny on 9/9/12.
//  Copyright (c) 2012 Artful Medium. All rights reserved.
//

#import "RBComposer.h"

#define kPresetNumber 0
#define kSoundFont @"8mbGeneralMIDI"

@interface RBComposer()

@property (nonatomic, assign) MusicSequence myMusicSequence;
@property (nonatomic, assign) MusicPlayer myMusicPlayer;

@property (nonatomic, assign) AUGraph myGraph;
@property (nonatomic, assign) AudioUnit mySamplerUnit;

@property (nonatomic, assign) MusicTimeStamp nextPosition;
@property (nonatomic, retain) NSTimer *myTimer;

@end

@implementation RBComposer

@synthesize myMusicSequence, myMusicPlayer;
@synthesize myGraph, mySamplerUnit;

@synthesize myTimer, nextPosition;

- (id)init
{
    self = [super init];
    if (self) {
        self.nextPosition = 0.0;
    }
    return self;
}

#pragma mark - Sequence Methods

- (void)loadMusicNamed:(NSString *)musicName
{
    MusicSequence aMusicSequence;
    NewMusicSequence(&aMusicSequence);
    
    CFURLRef fileURL = (__bridge CFURLRef)([[NSBundle mainBundle] URLForResource:musicName withExtension:@"mid"]);
    MusicSequenceFileLoad(aMusicSequence, fileURL, 0, 0);
    
    MusicSequenceSetAUGraph(aMusicSequence, self.myGraph);
    
    self.myMusicSequence = aMusicSequence;
}

- (void)createMusicPlayer
{
    MusicPlayer aMusicPlayer;
    NewMusicPlayer(&aMusicPlayer);
    
    MusicPlayerSetSequence(aMusicPlayer, self.myMusicSequence);
    
    MusicPlayerPreroll(aMusicPlayer);
    self.myMusicPlayer = aMusicPlayer;
}

#pragma mark - Graph Methods

-(void)loadPreset
{
    NSURL *sf2 = [[NSBundle mainBundle] URLForResource:kSoundFont withExtension:@"SF2"];
    [self loadFromDLSOrSoundFont:(__bridge CFURLRef)sf2 withPatch:kPresetNumber];
}


-(OSStatus) loadFromDLSOrSoundFont:(CFURLRef)bankURL withPatch:(int)presetNumber
{
    OSStatus result = noErr;
    
    // fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = bankURL;
    bpdata.bankMSB  = kAUSampler_DefaultMelodicBankMSB;
    //    bpdata.bankMSB  = kAUSampler_DefaultPercussionBankMSB;
    bpdata.bankLSB = kAUSampler_DefaultBankLSB;
    bpdata.presetID = (UInt8) presetNumber;
    
    // set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(self.mySamplerUnit,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(bpdata));
    
    // check for errors
    NSCAssert (result == noErr,
               @"Unable to set the preset property on the Sampler. Error code:%d '%.4s'",
               (int) result,
               (const char *)&result);
    
    return result;
}


-(void)createAUGraph
{
    AUGraph aGraph;
    NewAUGraph(&aGraph);
    
    AudioComponentDescription componentDescription;
    
    componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDescription.componentFlags = 0;
    componentDescription.componentFlagsMask = 0;
    
    AUNode ioNode, samplerNode, dynamicsNode;
    
    componentDescription.componentType = kAudioUnitType_Output;
    componentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    
    AUGraphAddNode(aGraph, &componentDescription, &ioNode);
    
    componentDescription.componentType = kAudioUnitType_MusicDevice;
    componentDescription.componentSubType = kAudioUnitSubType_Sampler;
    
    AUGraphAddNode(aGraph, &componentDescription, &samplerNode);
    
    componentDescription.componentType = kAudioUnitType_Effect;
    componentDescription.componentSubType = kAudioUnitSubType_DynamicsProcessor;
    
    AUGraphAddNode(aGraph, &componentDescription, &dynamicsNode);
    
    AUGraphOpen(aGraph);
    
    AudioUnit ioUnit, samplerUnit, dynamicsUnit;
    
    AUGraphNodeInfo(aGraph, ioNode, NULL, &ioUnit);
    AUGraphNodeInfo(aGraph, samplerNode, NULL, &samplerUnit);
    AUGraphNodeInfo(aGraph, dynamicsNode, NULL, &dynamicsUnit);
    
    self.mySamplerUnit = samplerUnit;
    
    AUGraphConnectNodeInput(aGraph, samplerNode, 0, dynamicsNode, 0);
    AUGraphConnectNodeInput(aGraph, dynamicsNode, 0, ioNode, 0);
    
    AUGraphInitialize(aGraph);
    AUGraphStart(aGraph);
    
    self.myGraph = aGraph;
}


#pragma mark - Control Methods

- (void)togglePlay
{
    Boolean isPlaying;
    MusicPlayerIsPlaying(self.myMusicPlayer, &isPlaying);
    
    if (isPlaying)
        MusicPlayerStop(self.myMusicPlayer);
    else
        MusicPlayerStart(self.myMusicPlayer);
}

- (void)playWithScalerRate:(Float64)scalerRate
{
    MusicPlayerSetPlayRateScalar(self.myMusicPlayer, scalerRate);
    
    Boolean isPlaying;
    MusicPlayerIsPlaying(self.myMusicPlayer, &isPlaying);
    
    if (!isPlaying)
        MusicPlayerStart(self.myMusicPlayer);
    
}



- (void)stop
{
    MusicPlayerStop(self.myMusicPlayer);
}

- (void)playForBeats:(MusicTimeStamp)beats
{
    if ([self.myTimer isValid])
        return;
    
    Boolean isPlaying;
    MusicPlayerIsPlaying(self.myMusicPlayer, &isPlaying);
    
    if (isPlaying)
        return;
    
    MusicPlayerSetTime(self.myMusicPlayer, self.nextPosition);
    
    Float64 secondsPerBeat = 0;
    MusicSequenceGetSecondsForBeats(self.myMusicSequence, beats, &secondsPerBeat);
    
    MusicPlayerStart(self.myMusicPlayer);
    self.myTimer = [NSTimer scheduledTimerWithTimeInterval:secondsPerBeat-.05 target:self selector:@selector(stop) userInfo:nil repeats:NO];
    
    self.nextPosition += beats;
}

@end
