//
//  MazeGenerator.m
//  Comp 8051 A3 - Maze
//
//  Created by Markus  on 2018-04-01.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MazeGenerator.h"

@implementation MazeGenerator {
    bool **mazeArray;
    int mazeLength;
}

- (void)GenerateMaze:(bool ***)maze mazeSize:(int)size {
    mazeLength = 2 * size + 1;
    // allocate memory for mazeArray
    mazeArray = malloc(mazeLength * sizeof(bool *));
    for (int i = 0; i < mazeLength; i++) {
        mazeArray[i] = malloc(mazeLength * sizeof(bool));
    }
    // create entrance and exit
    int mazeEntrance = (size % 2)? size : size - 1;
    mazeArray[0][mazeEntrance] = true;
    mazeArray[mazeLength - 1][mazeEntrance] = true;
    // generate maze
    [self DepthFirstSearch:1 :1];
    // set maze to point to the mazeArray
    *maze = mazeArray;
}

- (void)DepthFirstSearch:(int)x :(int)y {
    // Sets current cell as visited.
    mazeArray[x][y] = true;
    // Sets orderOfSearch to a random permutation of {0,1,2,3}.
    int orderOfSearch[] = { 0, 1, 2, 3 };
    for (int i = 0; i < 4; i++) {
        int r = arc4random() % (4 - i) + i;
        int temp = orderOfSearch[r];
        orderOfSearch[r] = orderOfSearch[i];
        orderOfSearch[i] = temp;
    }
    // Tries to visit cells to the North, East, South, and West in order of orderOfSearch.
    for (int i = 0; i < 4; i++) {
        if ((orderOfSearch[0] == i) && (y + 2 < mazeLength) && (!mazeArray[x][y + 2])) {
            mazeArray[x][y + 1] = true;
            [self DepthFirstSearch:x :y + 2];
        } else if ((orderOfSearch[1] == i) && (x + 2 < mazeLength) && (!mazeArray[x + 2][y])) {
            mazeArray[x + 1][y] = true;
            [self DepthFirstSearch:x + 2 :y];
        } else if ((orderOfSearch[2] == i) && (y - 2 >= 0) && (!mazeArray[x][y - 2])) {
            mazeArray[x][y - 1] = true;
            [self DepthFirstSearch:x :y - 2];
        } else if ((orderOfSearch[3] == i) && (x - 2 >= 0) && (!mazeArray[x - 2][y])) {
            mazeArray[x - 1][y] = true;
            [self DepthFirstSearch:x - 2 :y];
        }
    }
}

@end
