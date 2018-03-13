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

static bool mazeArray[11][11] = {
    {true, true, true, true, true, false, true, true, true, true, true},
    {true, false, true, false, false, false, true, false, false, false, true},
    {true, false, true, false, true, false, true, true, true, false, true},
    {true, false, false, false, true, false, false, false, false, false, true},
    {true, true, true, false, true, true, true, false, true, false, true},
    {true, false, false, false, true, false, false, false, true, false, true},
    {true, true, true, false, true, true, true, true, true, false, true},
    {true, false, false, false, false, false, true, false, false, false, true},
    {true, false, true, true, true, false, true, true, true, false, true},
    {true, false, true, false, false, false, true, false, false, false, true},
    {true, true, true, true, true, false, true, true, true, true, true}
};

static int mazeSize = 11;

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    
    GLuint programObject;
    
    std::chrono::time_point<std::chrono::steady_clock> lastTime;
    
    GLuint crateTexture;
    GLuint floorTexture;
    GLuint wallLeftTexture;
    GLuint wallRightTexture;
    GLuint wallBothTexture;
    GLuint wallNeitherTexture;
    
    GLKMatrix4 m, v, p;

    float cameraX, cameraZ; // camera location
    float cameraRot; // camera rotation about y
    float cubeRot;

    float *quadVertices, *quadTexCoords;
    int *quadIndices, quadNumIndices;
    
    float *cubeVertices, *cubeTexCoords;
    int *cubeIndices, cubeNumIndices;
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
    cubeNumIndices = glesRenderer.GenCube(0.5f, &cubeVertices, NULL, &cubeTexCoords, &cubeIndices);
    quadNumIndices = glesRenderer.GenQuad(1.0f, &quadVertices, NULL, &quadTexCoords, &quadIndices);
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
    
    glUseProgram (programObject);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    glUniform1f(uniforms[UNIFORM_FOGEND], 10.0);
    glUniform1f(uniforms[UNIFORM_SPOTLIGHTCUTOFF], cosf(M_PI/12)); // cos(30deg / 2)
    glUniform4f(uniforms[UNIFORM_SPOTLIGHTCOLOR], 0.5, 0.5, 0.5, 1.0);
    
    glEnable(GL_DEPTH_TEST);
    
    /*
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    */
    
    std::chrono::time_point<std::chrono::steady_clock> lastTime;
}

- (void)update {
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    cubeRot += 0.001f * elapsedTime;
    
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
    cameraX = 5.0f;
    cameraZ = 3.0f;
    cameraRot = 0.0f;
}

- (void)draw:(CGRect)drawRect; {
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, FALSE, (const float *)p.m);
    glUniform1i(uniforms[UNIFORM_SPOTLIGHT], spotlightToggle);
    glUniform1i(uniforms[UNIFORM_FOG], fogToggle);
    if (isDay) {
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.784, 0.706, 0.627, 1.00);
        glClearColor(1.000, 0.671, 0.921, 1.00);
    } else {
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.125, 0.125, 0.251, 1.00);
        glClearColor(0.125, 0.125, 0.251, 1.00);
    }
    
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    
    // draw cube
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), cubeVertices);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), cubeTexCoords);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    m = GLKMatrix4MakeTranslation(5, 0, 0);
    m = GLKMatrix4Rotate(m, cubeRot, 1.0, 1.0, 1.0);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
    glDrawElements(GL_TRIANGLES, cubeNumIndices, GL_UNSIGNED_INT, cubeIndices);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), quadVertices);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), quadTexCoords);
    for (int x = 0; x < mazeSize; x++) {
        for (int z = 0; z < mazeSize; z++) {
            if (!mazeArray[z][x]) {
                
                // draw floor
                m = GLKMatrix4MakeTranslation(x, 0, -z);
                m = GLKMatrix4RotateX(m, M_PI / -2.0);
                glBindTexture(GL_TEXTURE_2D, floorTexture);
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
                glDrawElements (GL_TRIANGLES, quadNumIndices, GL_UNSIGNED_INT, quadIndices);
                
                // draw walls
                m = GLKMatrix4MakeTranslation(x, 0, -z);
                int k[] = {0, 1};
                for (int i = 0; i < 4; i++) {
                    if (x + k[0] < mazeSize && x + k[0] >= 0 && z + k[1] < mazeSize && z + k[1] >= 0 && mazeArray[z + k[1]][x + k[0]]) {
                        bool wall_left  = (x + k[0] + k[1] < mazeSize && x + k[0] + k[1] >= 0 && z + k[1] - k[0] < mazeSize && z + k[1] - k[0] >= 0 && mazeArray[z + k[1] - k[0]][x + k[0] + k[1]]);
                        bool wall_right = (x + k[0] - k[1] < mazeSize && x + k[0] - k[1] >= 0 && z + k[1] + k[0] < mazeSize && z + k[1] + k[0] >= 0 && mazeArray[z + k[1] + k[0]][x + k[0] - k[1]]);
                        if (wall_left && wall_right) {
                            glBindTexture(GL_TEXTURE_2D, wallBothTexture);
                        } else if (wall_left) {
                            glBindTexture(GL_TEXTURE_2D, wallLeftTexture);
                        } else if (wall_right) {
                            glBindTexture(GL_TEXTURE_2D, wallRightTexture);
                        } else {
                            glBindTexture(GL_TEXTURE_2D, wallNeitherTexture);
                        }
                        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
                        glDrawElements ( GL_TRIANGLES, quadNumIndices, GL_UNSIGNED_INT, quadIndices );
                    }
                    // rotate kernel 45 degrees
                    int temp = k[1];
                    k[1] = -k[0];
                    k[0] = temp;
                    // rotate m 45 degrees
                    m = GLKMatrix4RotateY(m, M_PI / -2.0);
                }

            }
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
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

//returns camera position
- (NSString*)getPosition {
    return [NSString stringWithFormat:@"ポジション: %.01f,0.0,%.01f", cameraX,cameraZ];
}

//returns camera rotation
- (NSString*)getRotation {
    return [NSString stringWithFormat:@"回転: %.01f", cameraRot * 180 / M_PI];
}

- (NSString*)getMinimap {
    NSMutableString *string = [NSMutableString string];
    for(int z = 0; z < mazeSize; z++){
        for(int x = 0; x < 11; x++){
            if (z == roundf(-cameraZ) && x == roundf(cameraX)) {
                float rotDegrees = GLKMathRadiansToDegrees(cameraRot);
                if (rotDegrees > 337.5 || rotDegrees <= 22.5) {
                    [string appendFormat:@"%@", @"@↓"];
                } else if (rotDegrees > 22.5 && rotDegrees <= 67.5) {
                    [string appendFormat:@"%@", @"@↘"];
                } else if (rotDegrees > 67.5 && rotDegrees <= 112.5) {
                    [string appendFormat:@"%@", @"@→"];
                } else if (rotDegrees > 112.5 && rotDegrees <= 157.5) {
                    [string appendFormat:@"%@", @"@↗"];
                } else if (rotDegrees > 157.5 && rotDegrees <= 202.5) {
                    [string appendFormat:@"%@", @"@↑"];
                } else if (rotDegrees > 202.5 && rotDegrees <= 247.5) {
                    [string appendFormat:@"%@", @"@↖"];
                } else if (rotDegrees > 247.5 && rotDegrees <= 292.5) {
                    [string appendFormat:@"%@", @"@←"];
                } else if (rotDegrees > 292.5 && rotDegrees <= 337.5) {
                    [string appendFormat:@"%@", @"@↙"];
                }
            } else {
                if(mazeArray[z][x]){
                    [string appendFormat:@"%@", @"██"];
                }else{
                    [string appendFormat:@"%@", @"  "];
                }
            }
        }
        [string appendFormat:@"%@", @"\n"];
    }
    return string;
}

@end

