//
//  MazeGenerator.h
//  Comp 8051 A3 - Maze
//
//  Created by Markus  on 2018-04-01.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#ifndef MazeGenerator_h
#define MazeGenerator_h

@interface MazeGenerator : NSObject

- (void)GenerateMaze:(bool ***)maze mazeSize:(int)size;

@end

#endif /* MazeGenerator_h */
