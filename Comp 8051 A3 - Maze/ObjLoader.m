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

@interface ObjLoader () {
    
}

@end

@implementation ObjLoader

NSArray *vertices;
NSArray *textures;

GLKVector3 goat;

- (void)ReadFile:(NSString *)fileName {
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    if(content != nil) {
        NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
        for(NSString *line in lines) {
            if([line hasPrefix:@"v "]) {
                [self ReadVertex:line];
            } else if([line hasPrefix:@"vt "]) {
                [self ReadTexture:line];
            } else if([line hasPrefix:@"f "]) {
                [self ReadFace:line];
            }
        }
    } else {
        NSLog(@"Error: Objloader: file contents nil");
    }
}

- (void)ReadVertex:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    float x = [strings[1] floatValue];
    float y = [strings[2] floatValue];
    float z = [strings[3] floatValue];
}

- (void)ReadTexture:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
    float u = [strings[1] floatValue];
    float v = [strings[2] floatValue];
}

- (void)ReadFace:(NSString *)_line {
    NSArray *strings = [_line componentsSeparatedByString:@" "];
}

@end
