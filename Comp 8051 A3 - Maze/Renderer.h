//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>


@interface Renderer : NSObject

- (void)setup:(GLKView *)view;
- (void)loadResources;
- (void)update;
- (void)translateRect:(float)xDelta secondDelta:(float)zDelta;
- (void)moveNME:(float)xDelta secondDelta:(float)zDelta;
- (void)reset;
- (NSString*)getPosition;
- (NSString*)getRotation;
- (NSString*)getMinimap;
- (void)draw:(CGRect)drawRect;

@property bool isDay;
@property bool spotlightToggle;
@property bool fogToggle;
@property bool fogUseExp;
@property bool sameCell;

@end

#endif /* Renderer_h */
