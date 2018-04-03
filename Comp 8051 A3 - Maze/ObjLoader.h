//
//  ObjLoader.h
//  Comp 8051 A3 - Maze
//
//  Created by Markus  on 2018-04-01.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#ifndef ObjLoader_h
#define ObjLoader_h
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ObjLoader : NSObject

- (void)ReadFile:(NSString *)fileName;

@property float *verticesPointer;
@property float *texCoordsPointer;
@property float *normalsPointer;
@property int *indicesPointer;
@property int numIndices;

@end

#endif /* ObjLoader_h */
