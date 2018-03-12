//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#include <chrono>
#include "GLESRenderer.hpp"

//Camera - modify the view matrix. not the projection matrix


// Uniform index.
enum {
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_PROJECTION_MATRIX,
    UNIFORM_SPOTLIGHT,
    UNIFORM_SPOTLIGHTCUTOFF,
    UNIFORM_SPOTLIGHTCOLOR,
    UNIFORM_SKYCOLOR,
    UNIFORM_FOG,
    UNIFORM_FOGEND,
    UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    
    GLuint programObject;
    
    GLuint crateTexture;
    GLuint floorTexture;
    GLuint wallLeftTexture;
    GLuint wallRightTexture;
    GLuint wallBothTexture;
    GLuint wallNeitherTexture;
    
    GLKMatrix4 m, v, p;

    float cameraX, cameraZ; // camera location
    float cameraRot; // camera rotation about y

    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
}

@end

@implementation Renderer

@synthesize isDay;
@synthesize spotlightToggle;
@synthesize fogToggle;

- (void)dealloc {
    glDeleteProgram(programObject);
}

- (void)loadModels {
    numIndices = glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void)setup:(GLKView *)view {
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    spotlightToggle = true;
    isDay = true;
    fogToggle = true;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders]) {
        return;
    }
    
    //setup initial camera coordinates
    [self reset];
    
    crateTexture = [self setupTexture:@"crate.jpg"];
    floorTexture = [self setupTexture:@"floor.png"];
    wallLeftTexture = [self setupTexture:@"wall_left.png"];
    wallRightTexture = [self setupTexture:@"wall_right.png"];
    wallBothTexture = [self setupTexture:@"wall_both.png"];
    wallNeitherTexture = [self setupTexture:@"wall_neither.png"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, floorTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
}

- (void)update {
    v = GLKMatrix4MakeYRotation(cameraRot);
    v = GLKMatrix4Translate(v, -cameraX, 0, -cameraZ);
    
    float hFOV = 90.0f;
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    p = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(hFOV), aspect, 0.1f, 10.0f);
}

- (void)translateRect:(float)xDelta secondDelta:(float)yDelta {
    cameraRot -= xDelta;
    
    if (cameraRot > 2 * M_PI) {
        cameraRot -= 2 * M_PI;
    }
    if (cameraRot < 0.0) {
        cameraRot += 2 * M_PI;
    }
    
    cameraZ -= cos(cameraRot) * yDelta * 4.0;
    cameraX += sin(cameraRot) * yDelta * 4.0;
}

- (void)reset {
    cameraX = 4.0f;
    cameraZ = 4.0f;
    cameraRot = 0.0f;
}

- (void)draw:(CGRect)drawRect; {
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, FALSE, (const float *)p.m);
    if(isDay) {
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.784, 0.706, 0.627, 1.00);
        glClearColor(0.784, 0.706, 0.627, 1.00);
    } else {
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.125, 0.125, 0.251, 1.00);
        glClearColor(0.125, 0.125, 0.251, 1.00);
    }
    
    glUniform1i(uniforms[UNIFORM_SPOTLIGHT], spotlightToggle);
    glUniform1f(uniforms[UNIFORM_SPOTLIGHTCUTOFF], 0.9659); // cos(30deg / 2)
    glUniform4f(uniforms[UNIFORM_SPOTLIGHTCOLOR], 0.5, 0.5, 0.5, 1.0);
    glUniform1i(uniforms[UNIFORM_FOG], fogToggle);
    glUniform1f(uniforms[UNIFORM_FOGEND], 10.0);
    
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    glVertexAttribPointer ( 0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    glVertexAttribPointer ( 1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof ( GLfloat ), texCoords );
    glEnableVertexAttribArray ( 1 );
    
    static bool mazeArray[10][10] = {
        {true, true, true, true, false, true, true, true, true, true},
        {true, false, false, true, false, false, false, true, false, true},
        {true, true, false, false, false, true, true, true, false, true},
        {true, true, true, true, false, false, false, false, false, true},
        {true, false, false, false, false, true, true, false, true, true},
        {true, false, true, true, true, true, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, false, false, false, false, true, false, true, true},
        {true, true, true, true, true, true, true, false, true, true},
    };
    
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 10; j++) {
            if (mazeArray[j][i]) {
                m = GLKMatrix4MakeTranslation(i, 0, -j);
                    glBindTexture(GL_TEXTURE_2D, wallBothTexture);
            } else {
                m = GLKMatrix4MakeTranslation(i, -1, -j);
                    glBindTexture(GL_TEXTURE_2D, floorTexture);
            }
            glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
            glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
        }
    }
}

- (bool)setupShaders {
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(programObject, "modelViewMatrix");
    uniforms[UNIFORM_PROJECTION_MATRIX] = glGetUniformLocation(programObject, "projectionMatrix");
    uniforms[UNIFORM_SPOTLIGHT] = glGetUniformLocation(programObject, "spotlight");
    uniforms[UNIFORM_SPOTLIGHTCUTOFF] = glGetUniformLocation(programObject, "spotlightCutoff");
    uniforms[UNIFORM_SPOTLIGHTCOLOR] = glGetUniformLocation(programObject, "spotlightColor");
    uniforms[UNIFORM_SKYCOLOR] = glGetUniformLocation(programObject, "skyColor");
    uniforms[UNIFORM_FOG] = glGetUniformLocation(programObject, "fog");
    uniforms[UNIFORM_FOGEND] = glGetUniformLocation(programObject, "fogEnd");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    
    return true;
}

// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

//returns camera position
- (NSString*)getPosition {
    return [NSString stringWithFormat:@"Position: %.01f,0.0,%.01f", cameraX,cameraZ];
}

//returns camera rotation
- (NSString*)getRotation {
    return [NSString stringWithFormat:@"Rotation: %.01f", cameraRot * 180 / M_PI];
}

- (NSString*)getMinimap {
    static bool mazeArray[10][10] = {
        {true, true, true, true, false, true, true, true, true, true},
        {true, false, false, true, false, false, false, true, false, true},
        {true, true, false, false, false, true, true, true, false, true},
        {true, true, true, true, false, false, false, false, false, true},
        {true, false, false, false, false, true, true, false, true, true},
        {true, false, true, true, true, true, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, false, false, false, false, true, false, true, true},
        {true, true, true, true, true, true, true, false, true, true},
    };
    
    NSMutableString *goat = [NSMutableString string];
    
    for(int r=0;r<10;r++){
        for(int c=0;c<10;c++){
            if (r == floorf(-cameraZ + 0.5) && c == floorf(cameraX + 0.5)) {
                float rotDegrees = GLKMathRadiansToDegrees(cameraRot);
                if (rotDegrees > 315 || rotDegrees <= 45) {
                    [goat appendFormat:@"%@", @"@↓"];
                } else if (rotDegrees > 45 && rotDegrees <= 135) {
                    [goat appendFormat:@"%@", @"@→"];
                } else if (rotDegrees > 135 && rotDegrees <= 225) {
                    [goat appendFormat:@"%@", @"@↑"];
                } else {
                    [goat appendFormat:@"%@", @"@←"];
                }
            } else {
                if(mazeArray[r][c]){
                    [goat appendFormat:@"%@", @"██"];
                }else{
                    [goat appendFormat:@"%@", @"  "];
                }
            }
        }
        [goat appendFormat:@"%@", @"\n"];
    }
    
    return goat;
}

//generate maze
-(void) generateMaze {
    static bool mazeArray[10][10] = {
        {true, true, true, true, false, true, true, true, true, true},
        {true, false, false, true, false, false, false, true, false, true},
        {true, true, false, false, false, true, true, true, false, true},
        {true, true, true, true, false, false, false, false, false, true},
        {true, false, false, false, false, true, true, false, true, true},
        {true, false, true, true, true, true, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, true, true, true, false, true, false, true, true},
        {true, false, false, false, false, false, true, false, true, true},
        {true, true, true, true, true, true, true, false, true, true},
    };
    
    for(int r=0;r<10;r++){
        for(int c=0;c<10;c++){
            if(mazeArray[r][c]){
                printf("*"); //wall
            }else{
                printf(" "); //path
            }
        }
        printf("\n");
    }
}

@end

