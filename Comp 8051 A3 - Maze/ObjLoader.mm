//
//  ObjLoader.m
//  Comp 8051 A3 - Maze
//
//  Created by Markus  on 2018-04-01.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#import "ObjLoader.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <vector>

@implementation ObjLoader {
    // in order read from file
    std::vector<GLKVector3> tempVertices;
    std::vector<GLKVector2> tempTexCoords;
    std::vector<GLKVector3> tempNormals;
}

- (void)ReadFile:(NSString *)fileName {
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if(content != nil) {
        NSArray *lines = [content componentsSeparatedByString:@"\n"];
        for(NSString *line in lines) {
            if([line hasPrefix:@"v "]) {
                [self ReadVertex:line];
            } else if([line hasPrefix:@"vt "]) {
                [self ReadTexture:line];
            } else if([line hasPrefix:@"vn "]) {
                [self ReadNormal:line];
            } else if([line hasPrefix:@"f "]) {
                [self ReadFace:line];
            }
        }
    } else {
        NSLog(@"Error loading file: %@", error.localizedDescription);
    }
}

- (void)ReadVertex:(NSString *)_line {
    GLKVector3 vertex;
    sscanf([_line UTF8String], "%*s %f %f %f\n", &vertex.x, &vertex.y, &vertex.z );
    tempVertices.push_back(vertex);
}

- (void)ReadTexture:(NSString *)_line {
    GLKVector2 texCoord;
    sscanf([_line UTF8String], "%*s %f %f\n", &texCoord.x, &texCoord.y);
    tempTexCoords.push_back(texCoord);
}

- (void)ReadNormal:(NSString *)_line {
    GLKVector3 normal;
    sscanf([_line UTF8String], "%*s %f %f %f\n", &normal.x, &normal.y, &normal.z );
    tempNormals.push_back(normal);
}

- (void)ReadFace:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    for (int i = 0; i < 3; i++) {
        NSString *string = strings[i + 1];
        NSArray *a = [string componentsSeparatedByString:@"/"];
        int vertexIndex = [a[0] intValue] - 1;
        _vertices.push_back(tempVertices[vertexIndex]);
        int texCoordIndex = [a[1] intValue] - 1;
        _texCoords.push_back(tempTexCoords[texCoordIndex]);
        int normalIndex = [a[2] intValue] - 1;
        _normals.push_back(tempNormals[normalIndex]);
        _indices.push_back(_indices.size());
    }
}

@end
