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
- (void)rotateRectHorizontal:(float) angle; 
- (void)rotateRectVertical:(float) angle;
- (void)scaleRect:(float) scale;
- (void)translateRect:(float)xDelta secondDelta:(float)zDelta;
- (void)reset;
- (NSString*)getPosition;
- (NSString*)getRotation;
- (void)draw:(CGRect)drawRect;


@property int _isRotating;

@end

#endif /* Renderer_h */
