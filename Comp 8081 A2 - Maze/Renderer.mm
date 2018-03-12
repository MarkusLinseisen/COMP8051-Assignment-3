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
    std::chrono::time_point<std::chrono::steady_clock> lastTime;
    
    GLKMatrix4 m, v, p;

    float cameraX, cameraZ; // camera location
    float cameraRot; // camera rotation about y

    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
}

@end

@implementation Renderer

@synthesize _isRotating;
@synthesize isDay;

- (void)dealloc {
    glDeleteProgram(programObject);
}

- (void)loadModels {
    numIndices = glesRenderer.GenQuad(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void)setup:(GLKView *)view {
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders]) {
        return;
    }
    
    //setup initial camera coordinates
    [self reset];
    
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}

- (void)update {
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;

    v = GLKMatrix4MakeYRotation(cameraRot);
    v = GLKMatrix4Translate(v, -cameraX, 0, -cameraZ);
    
    float hFOV = 90.0f;
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    p = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(hFOV) / (aspect * aspect), aspect, 1.0f, 20.0f);
}

//translates the cube on the x and y axis
- (void)translateRect:(float)xDelta secondDelta:(float)yDelta {
    cameraRot += xDelta;
    cameraZ += cos(cameraRot) * yDelta;
    cameraX -= sin(cameraRot) * yDelta;
}

//resets the cube to default position (0, 0, -5), default scale of 1, and default rotation
- (void)reset {
    cameraX = 0.0f;
    cameraZ = 5.0f;
    cameraRot = 0.0f;
}

- (void)draw:(CGRect)drawRect; {
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, FALSE, (const float *)p.m);
    if(isDay){
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.784, 0.706, 0.627, 1.00);
        glClearColor(0.784, 0.706, 0.627, 1.00);
    }else{
        glUniform4f(uniforms[UNIFORM_SKYCOLOR], 0.125, 0.125, 0.251, 1.00);
        glClearColor(0.125, 0.125, 0.251, 1.00);
    }
    
    glUniform1i(uniforms[UNIFORM_SPOTLIGHT], true);
    glUniform1f(uniforms[UNIFORM_SPOTLIGHTCUTOFF], 0.9961);
    glUniform4f(uniforms[UNIFORM_SPOTLIGHTCOLOR], 1.0, 1.0, 1.0, 1.0);
    glUniform1i(uniforms[UNIFORM_FOG], true);
    glUniform1f(uniforms[UNIFORM_FOGEND], 10.0);
    
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    glVertexAttribPointer ( 0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    
    glVertexAttrib4f( 1, 1.0f, 1.0f, 1.0f, 1.0f ); // color
    
    glVertexAttribPointer ( 2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof ( GLfloat ), normals );
    glEnableVertexAttribArray ( 2 );
    
    glVertexAttribPointer ( 3, 2, GL_FLOAT, GL_FALSE, 2 * sizeof ( GLfloat ), texCoords );
    glEnableVertexAttribArray ( 3 );
    
    m = GLKMatrix4MakeTranslation(0, 0, 0);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
    
    m = GLKMatrix4MakeTranslation(1.0, 0.0, 0.0);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
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
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

//returns camera position
- (NSString*)getPosition {
    return [NSString stringWithFormat:@"Position: %.01f,0.00,%.01f", cameraX,cameraZ];
}

//returns camera rotation
- (NSString*)getRotation {
    return [NSString stringWithFormat:@"Rotation: %.01f", cameraRot * 180 / M_PI];
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

