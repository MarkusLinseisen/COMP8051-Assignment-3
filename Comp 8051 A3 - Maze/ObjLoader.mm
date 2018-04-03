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
#include <vector>

@implementation ObjLoader {
    // in order read from file
    std::vector<float> tempVertices;
    std::vector<float> tempTexCoords;
    std::vector<float> tempNormals;
    
    // in order defined by faces
    std::vector<float> vertices;
    std::vector<float> texCoords;
    std::vector<float> normals;
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
        [self CreateArrays];
    } else {
        NSLog(@"Error loading file: %@", error.localizedDescription);
    }
}

- (void)ReadVertex:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    tempVertices.push_back([strings[1] floatValue]);
    tempVertices.push_back([strings[2] floatValue]);
    tempVertices.push_back([strings[3] floatValue]);
}

- (void)ReadTexture:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    tempTexCoords.push_back([strings[1] floatValue]);
    tempTexCoords.push_back([strings[2] floatValue]);
}

- (void)ReadNormal:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    tempNormals.push_back([strings[1] floatValue]);
    tempNormals.push_back([strings[2] floatValue]);
    tempNormals.push_back([strings[3] floatValue]);
}

- (void)ReadFace:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    for (int i = 0; i < 3; i++) {
        NSString *string = strings[i + 1];
        NSArray *a = [string componentsSeparatedByString:@"/"];
        int vertexIndex = 3 * ([a[0] intValue] - 1);
        vertices.push_back(tempVertices[vertexIndex]);
        vertices.push_back(tempVertices[vertexIndex + 1]);
        vertices.push_back(tempVertices[vertexIndex + 2]);
        int texCoordIndex = 2 * ([a[1] intValue] - 1);
        texCoords.push_back(tempTexCoords[texCoordIndex]);
        texCoords.push_back(tempTexCoords[texCoordIndex + 1]);
        int normalIndex = 3 * ([a[2] intValue] - 1);
        normals.push_back(tempNormals[normalIndex]);
        normals.push_back(tempNormals[normalIndex + 1]);
        normals.push_back(tempNormals[normalIndex + 2]);
    }
}

- (void)CreateArrays {
    _numIndices = (int)vertices.size() / 3;
    _verticesPointer = (float *)malloc(_numIndices * 3 * sizeof(float));
    _texCoordsPointer = (float *)malloc(_numIndices * 2 * sizeof(float));
    _normalsPointer = (float *)malloc(_numIndices * 3 * sizeof(float));
    _indicesPointer = (int *)malloc(_numIndices * sizeof(GLuint));
    
    std::copy(vertices.begin(), vertices.end(), _verticesPointer);
    std::copy(texCoords.begin(), texCoords.end(), _texCoordsPointer);
    std::copy(normals.begin(), normals.end(), _normalsPointer);
    
    for (int i = 0; i < _numIndices; i++) {
        _indicesPointer[i] = (GLuint)i;
    }
}

@end
