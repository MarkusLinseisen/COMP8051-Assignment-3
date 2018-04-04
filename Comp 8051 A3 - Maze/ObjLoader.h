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
#import <vector>

@interface ObjLoader : NSObject

- (void)ReadFile:(NSString *)fileName;

@property std::vector<GLKVector3> vertices;
@property std::vector<GLKVector2> texCoords;
@property std::vector<GLKVector3> normals;
@property std::vector<GLuint> indices;
@property int numIndices;

@end

#endif /* ObjLoader_h */
