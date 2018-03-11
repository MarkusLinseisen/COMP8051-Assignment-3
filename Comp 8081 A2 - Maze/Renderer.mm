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
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASSTHROUGH,
    UNIFORM_SHADEINFRAG,
    UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
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
    
    GLKMatrix4 mvp;
    GLKMatrix3 normalMatrix;

    float xRot, yRot, zRot; //rotation angles for all 3 axis
    float x, y, z;          //coordinate of cube
    
    float cameraX, cameraY, cameraZ; //location of the camera (eyes)
    float targetX, targetY, targetZ; //coordinates of the point being looked at
    
    
    float _scale;           //scale of cube

    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
}

@end



@implementation Renderer

@synthesize _isRotating;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    numIndices = glesRenderer.GenQuad(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders])
        return;
    
    _isRotating = 1;
    _scale = 1.0f;
    
    x = y = z = 0.0f;
    xRot = zRot = 0.0f; //sets rotation angles to 0
    
    //setup initial camera coordinates
    cameraX = 0.0f;
    cameraY = 0.0f;
    cameraZ = 5.0f;
    
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();

}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    
    if (_isRotating)
    {
        xRot += 0.001f * elapsedTime;
        if(xRot >= 360.0f)
            xRot = 0.0f;
        
        zRot += 0.001f * elapsedTime;
        if(zRot >= 360.0f)
            zRot = 0.0f;
    }

    // it looks like this code translates, then scales, then rotates the model,
    // but because matrix multiplication it rotates, then scales, then translates
    GLKMatrix4 m = GLKMatrix4Identity;
    m = GLKMatrix4Translate(m, x, y, z);
    m = GLKMatrix4Scale(m, _scale, _scale, _scale);
    m = GLKMatrix4RotateX(m, xRot);
    m = GLKMatrix4RotateZ(m, zRot);

    GLKMatrix4 v = GLKMatrix4MakeLookAt(cameraX, cameraY, cameraZ,
                                       targetX, targetY, targetZ,
                                       0, 1, 0);

    GLKMatrix4 mv = GLKMatrix4Multiply(v, m);
    
    // don't need a normal matrix if we scale x y and z uniformly
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mv), NULL);
    
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    
    GLKMatrix4 p = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);
    
    mvp = GLKMatrix4Multiply(p, mv);
}

//rotates the cube on the z axis
- (void)rotateRectHorizontal:(float)angle
{

    zRot += angle;
    if (zRot >= 360.0f)
    {
        zRot = 0.0f;
    }else if(zRot < 0){
        zRot = 360.0f;
    }
}

//rotates the cube on the x axis
- (void)rotateRectVertical:(float)angle
{

    xRot += angle;
    if (xRot >= 360.0f)
    {
        xRot = 0.0f;
    }else if(xRot < 0){
        xRot = 360.0f;
    }
    
}

//scales the cube, setting _scale to the new scale
- (void)scaleRect:(float)scale
{
    _scale = scale;
    
}

//translates the cube on the x and y axis
- (void)translateRect:(float)xDelta secondDelta:(float)zDelta
{
    x += xDelta;
    y += zDelta;
}

//resets the cube to default position (0, 0, -5), default scale of 1, and default rotation
- (void)reset
{
    x = y = z = 0.0f;
    xRot = yRot = zRot = 0.0f;
    _scale = 1.0f;
}

//returns the x y z coordinates of the cube's transformation
- (NSString*)getPosition
{
    return [NSString stringWithFormat:@"Position: %.01f,%.01f,%.01f", x,y,z];
}

//returns the rotation of the cube
- (NSString*)getRotation
{
    return [NSString stringWithFormat:@"Rotation: %.01f,%.01f,%.01f", xRot, yRot, zRot];
}

- (void)draw:(CGRect)drawRect;
{

    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    
    
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
    glUniform1i(uniforms[UNIFORM_PASSTHROUGH], false);
    glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);
    
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );
    
    glVertexAttribPointer ( 0, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    
    glVertexAttrib4f ( 1, 1.0f, 0.0f, 0.0f, 1.0f );
    
    glVertexAttribPointer ( 2, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), normals );
    glEnableVertexAttribArray ( 2 );
    
    glVertexAttribPointer ( 3, 2, GL_FLOAT,
                           GL_FALSE, 2 * sizeof ( GLfloat ), texCoords );
    glEnableVertexAttribArray ( 3 );
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
}

- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_PASSTHROUGH] = glGetUniformLocation(programObject, "passThrough");
    uniforms[UNIFORM_SHADEINFRAG] = glGetUniformLocation(programObject, "shadeInFrag");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(programObject, "texSampler");
    
    return true;
}

// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName
{
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


//generate maze
-(void) generateMaze{
    
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

