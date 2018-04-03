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

@implementation ObjLoader {
    // in order read from file
    NSMutableArray *tempVertices;
    NSMutableArray *tempTexCoords;
    NSMutableArray *tempNormals;
    
    // in order defined by faces
    NSMutableArray *vertices;
    NSMutableArray *texCoords;
    NSMutableArray *normals;
}

- (void)ReadFile:(NSString *)fileName {
    NSError *error;
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    tempVertices = [[NSMutableArray alloc] init];
    tempTexCoords = [[NSMutableArray alloc] init];
    tempNormals = [[NSMutableArray alloc] init];

    vertices = [[NSMutableArray alloc] init];
    texCoords = [[NSMutableArray alloc] init];
    normals = [[NSMutableArray alloc] init];
    
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
    NSNumber *x = [NSNumber numberWithFloat:[strings[1] floatValue]];
    NSNumber *y = [NSNumber numberWithFloat:[strings[2] floatValue]];
    NSNumber *z = [NSNumber numberWithFloat:[strings[3] floatValue]];
    [tempVertices addObject:x];
    [tempVertices addObject:y];
    [tempVertices addObject:z];
}

- (void)ReadTexture:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    NSNumber *u = [NSNumber numberWithFloat:[strings[1] floatValue]];
    NSNumber *v = [NSNumber numberWithFloat:[strings[2] floatValue]];
    [tempTexCoords addObject:u];
    [tempTexCoords addObject:v];
}

- (void)ReadNormal:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    NSNumber *i = [NSNumber numberWithFloat:[strings[1] floatValue]];
    NSNumber *j = [NSNumber numberWithFloat:[strings[2] floatValue]];
    NSNumber *k = [NSNumber numberWithFloat:[strings[3] floatValue]];
    [tempNormals addObject:i];
    [tempNormals addObject:j];
    [tempNormals addObject:k];
}

- (void)ReadFace:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    for (int i = 0; i < 3; i++) {
        NSString *string = strings[i + 1];
        NSArray *a = [string componentsSeparatedByString:@"/"];
        int vertexIndex = 3 * ([a[0] intValue] - 1);
        [vertices addObject:tempVertices[vertexIndex]];
        [vertices addObject:tempVertices[vertexIndex + 1]];
        [vertices addObject:tempVertices[vertexIndex + 2]];
        int texCoordIndex = 2 * ([a[1] intValue] - 1);
        [texCoords addObject:tempTexCoords[texCoordIndex]];
        [texCoords addObject:tempTexCoords[texCoordIndex + 1]];
        int normalIndex = 3 * ([a[2] intValue] - 1);
        [normals addObject:tempNormals[normalIndex]];
        [normals addObject:tempNormals[normalIndex + 1]];
        [normals addObject:tempNormals[normalIndex + 2]];
    }
}

- (void)CreateArrays {
    _numIndices = (int)[vertices count] / 3;
    _verticesPointer = malloc(_numIndices * 3 * sizeof(float));
    _texCoordsPointer = malloc(_numIndices * 2 * sizeof(float));
    _normalsPointer = malloc(_numIndices * 3 * sizeof(float));
    _indicesPointer = malloc(_numIndices * sizeof(GLuint));
    
    for (int i = 0; i < _numIndices; i++) {
        _verticesPointer[3 * i] = [vertices[3 * i] floatValue];
        _verticesPointer[3 * i + 1] = [vertices[3 * i + 1] floatValue];
        _verticesPointer[3 * i + 2] = [vertices[3 * i + 2] floatValue];
        
        _texCoordsPointer[2 * i] = [texCoords[2 * i] floatValue];
        _texCoordsPointer[2 * i + 1] = [texCoords[2 * i] floatValue];
        
        _normalsPointer[3 * i] = [normals[3 * i] floatValue];
        _normalsPointer[3 * i + 1] = [normals[3 * i + 1] floatValue];
        _normalsPointer[3 * i + 2] = [normals[3 * i + 2] floatValue];
        
        _indicesPointer[i] = (GLuint)i;
    }
}

@end
