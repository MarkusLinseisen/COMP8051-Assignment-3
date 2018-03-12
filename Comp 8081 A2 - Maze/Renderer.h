//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>


@interface Renderer : NSObject

- (void)setup:(GLKView *)view;
- (void)loadModels;
- (void)update;
- (void)translateRect:(float)xDelta secondDelta:(float)zDelta;
- (void)reset;
- (NSString*)getPosition;
- (NSString*)getRotation;
- (NSString*)getMinimap;
- (void)draw:(CGRect)drawRect;
- (void)generateMaze;

@property int _isRotating;
@property bool isDay;
@property bool spotlightToggle;
@property bool fogToggle;

@end

#endif /* Renderer_h */
