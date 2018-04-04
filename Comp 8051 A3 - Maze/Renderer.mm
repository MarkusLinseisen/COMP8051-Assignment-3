//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#import "Renderer.h"
#import "MazeGenerator.h"
#import <Foundation/Foundation.h>
#import <chrono>
#import "GLESRenderer.hpp"
#import "ObjLoader.h"

// Uniform index.
enum {
    UNIFORM_MODELVIEW_MATRIX,
    UNIFORM_PROJECTION_MATRIX,
    UNIFORM_AMBIENTCOLOR,
    UNIFORM_SPOTLIGHT,
    UNIFORM_SPOTLIGHTCUTOFF,
    UNIFORM_SPOTLIGHTCOLOR,
    UNIFORM_FOG,
    UNIFORM_FOGCOLOR,
    UNIFORM_FOGEND,
    UNIFORM_FOGDENSITY,
    UNIFORM_FOGUSEEXP,
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

const int mazeSize = 5;
const int mazeLength = mazeSize * 2 + 1;
const int mazeEntrance = (mazeSize % 2)?mazeSize: mazeSize - 1;
bool **mazeArray;

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

    float nmeX, nmeZ, nmeRot;
    
    float *quadVertices, *quadTexCoords, *quadNormals;
    int *quadIndices, quadNumIndices;
    
    GLKVector3 *modelVertices, *modelNormals;
    GLKVector2 *modelTexCoords;
    int *modelIndices, modelNumIndices;
    
    int tester; //testing var for enemy rotation
}

@end

@implementation Renderer

@synthesize isDay;
@synthesize spotlightToggle;
@synthesize fogToggle;
@synthesize fogUseExp;

- (void)dealloc {
    glDeleteProgram(programObject);
}

- (void)loadResources {
    // model for walls and floors
    quadNumIndices = glesRenderer.GenQuad(1.0f, &quadVertices, &quadNormals, &quadTexCoords, &quadIndices);
    
    // model for enemy
    ObjLoader *objLoader = [[ObjLoader alloc] init];
    [objLoader ReadFile:@"suzanne.obj"];
    modelVertices = [objLoader verticesPointer];
    modelTexCoords = [objLoader texCoordsPointer];
    modelNormals = [objLoader normalsPointer];
    modelIndices = [objLoader indicesPointer];
    modelNumIndices = [objLoader numIndices];
    
    // maze data representation
    MazeGenerator *mazeGenerator = [[MazeGenerator alloc] init];
    [mazeGenerator GenerateMaze:&mazeArray mazeSize:mazeSize];
    
    // textures
    crateTexture = [self setupTexture:@"crate.jpg"];
    floorTexture = [self setupTexture:@"floor.png"];
    wallLeftTexture = [self setupTexture:@"wall_left.png"];
    wallRightTexture = [self setupTexture:@"wall_right.png"];
    wallBothTexture = [self setupTexture:@"wall_both.png"];
    wallNeitherTexture = [self setupTexture:@"wall_neither.png"];
}

- (void)setup:(GLKView *)view {
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    spotlightToggle = true;
    isDay = true;
    fogToggle = true;
    fogUseExp = true;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders]) {
        return;
    }
    
    glUseProgram (programObject);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    glUniform1f(uniforms[UNIFORM_FOGEND], 8.0);
    glUniform1f(uniforms[UNIFORM_FOGDENSITY], 0.25);
    glUniform1f(uniforms[UNIFORM_SPOTLIGHTCUTOFF], cosf(M_PI / 8.0)); // cos(45deg / 2)
    glUniform4f(uniforms[UNIFORM_SPOTLIGHTCOLOR], 0.5, 0.5, 0.5, 1.0);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    /*
    lastTime = std::chrono::steady_clock::now();
    */
    
    //set camera and nme to initial values
    [self reset];
}

- (void)reset {
    cameraX = mazeEntrance + 0.5;
    cameraZ = 0.5f;
    cameraRot = 0.0f;
    
    _controllingNME = false;
    _scaleNME = 0.3;
    nmeX = mazeEntrance + 0.5;
    nmeZ = 1.5f;
    nmeRot = 0.0f;
    tester = 120;
}

- (void)update {
    /*
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    */
    
    v = GLKMatrix4MakeYRotation(cameraRot);
    v = GLKMatrix4Translate(v, -cameraX, 0, cameraZ);
    
    float hFOV = 90.0f;
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    p = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(hFOV), aspect, 0.1f, mazeLength);
    
    _sameCell = floor(nmeZ) == floor(cameraZ) && floor(nmeX) == floor(cameraX);
    if (!_sameCell && !_controllingNME) {
        if(tester == 0) {
            [self moveNME:0.25 * M_PI * (rand() % 8) secondDelta:0.0];
            tester = rand() % 120; // number of ticks until enemy rotates again
        } else {
            tester--;
        }
        [self moveNME:0.00 secondDelta:0.05];
    }
}

double wrapMax(double x, double max) {
    return fmod(max + fmod(x, max), max);
}

- (void)translateRect:(float)xDelta secondDelta:(float)yDelta {
    cameraRot -= xDelta;
    cameraRot = wrapMax(cameraRot, 2 * M_PI);
    
    float radius = 0.25;
    
    float cameraZ_delta = cos(cameraRot) * yDelta;
    cameraZ = MAX(MIN(cameraZ + cameraZ_delta, mazeLength - radius), radius);
    float cameraZ_test_offset = signbit(cameraZ_delta)?-radius:radius;
    if (!mazeArray[(int)(cameraZ + cameraZ_test_offset)][(int)cameraX]) {
        cameraZ = roundf(cameraZ) - cameraZ_test_offset;
    }
    
    float cameraX_delta = sin(cameraRot) * yDelta;
    cameraX = MAX(MIN(cameraX + cameraX_delta, mazeLength - radius), radius);
    float cameraX_test_offset = signbit(cameraX_delta)?-radius:radius;
    if (!mazeArray[(int)cameraZ][(int)(cameraX + cameraX_test_offset)]) {
        cameraX = roundf(cameraX) - cameraX_test_offset;
    }
}

- (void)moveNME:(float)xDelta secondDelta:(float)yDelta {
    nmeRot += xDelta;
    nmeRot = wrapMax(nmeRot, 2 * M_PI);
    
    float radius = fmin(0.5, _scaleNME / 2);
    float offset = 1.0;
    
    float nmeZ_delta = cos(nmeRot) * yDelta;
    nmeZ = MAX(MIN(nmeZ + nmeZ_delta, mazeLength - radius - offset), radius + offset);
    float nmeZ_test_offset = signbit(nmeZ_delta)?-radius:radius;
    if (!mazeArray[(int)(nmeZ + nmeZ_test_offset)][(int)nmeX]) {
        nmeZ = roundf(nmeZ) - nmeZ_test_offset;
    }
    
    float nmeX_delta = -sin(nmeRot) * yDelta;
    nmeX = MAX(MIN(nmeX + nmeX_delta, mazeLength - radius - offset), radius + offset);
    float nmeX_test_offset = signbit(nmeX_delta)?-radius:radius;
    if (!mazeArray[(int)nmeZ][(int)(nmeX + nmeX_test_offset)]) {
        nmeX = roundf(nmeX) - nmeX_test_offset;
    }
}

- (void)draw:(CGRect)drawRect; {
    glUniformMatrix4fv(uniforms[UNIFORM_PROJECTION_MATRIX], 1, FALSE, (const float *)p.m);
    glUniform1i(uniforms[UNIFORM_SPOTLIGHT], spotlightToggle);
    glUniform1i(uniforms[UNIFORM_FOG], fogToggle);
    glUniform1i(uniforms[UNIFORM_FOGUSEEXP], fogUseExp);
    if (isDay) {
        glUniform4f(uniforms[UNIFORM_AMBIENTCOLOR], 0.784, 0.706, 0.627, 1.000);
        glUniform4f(uniforms[UNIFORM_FOGCOLOR], 0.784, 0.706, 0.627, 1.000);
        glClearColor(1.000, 0.671, 0.921, 1.00);
    } else {
        glUniform4f(uniforms[UNIFORM_AMBIENTCOLOR], 0.250, 0.250, 0.500, 1.000);
        glUniform4f(uniforms[UNIFORM_FOGCOLOR], 0.125, 0.125, 0.250, 1.000);
        glClearColor(0.125, 0.125, 0.251, 1.000);
    }
    
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    
    // draw cube
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(GLKVector3), modelVertices);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLKVector2), modelTexCoords);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, sizeof(GLKVector3), modelNormals);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    m = GLKMatrix4MakeTranslation(nmeX, 0, -nmeZ);
    m = GLKMatrix4Rotate(m, nmeRot + M_PI, 0.0, 1.0, 0.0);
    m = GLKMatrix4Scale(m, _scaleNME, _scaleNME, _scaleNME);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
    glDrawElements(GL_TRIANGLES, modelNumIndices, GL_UNSIGNED_INT, modelIndices);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), quadVertices);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), quadTexCoords);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), quadNormals);
    for (int x = 0; x < mazeLength; x++) {
        for (int z = 0; z < mazeLength; z++) {
            if (mazeArray[z][x]) {
                
                // draw floor
                m = GLKMatrix4MakeTranslation(x + 0.5, 0, -z - 0.5);
                m = GLKMatrix4RotateX(m, M_PI / -2.0);
                glBindTexture(GL_TEXTURE_2D, floorTexture);
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, FALSE, (const float *)GLKMatrix4Multiply(v, m).m);
                glDrawElements (GL_TRIANGLES, quadNumIndices, GL_UNSIGNED_INT, quadIndices);
                
                // draw walls
                m = GLKMatrix4MakeTranslation(x + 0.5, 0, -z - 0.5);
                int k[] = {0, 1};
                for (int i = 0; i < 4; i++) {
                    if (x + k[0] < mazeLength && x + k[0] >= 0 && z + k[1] < mazeLength && z + k[1] >= 0 && !mazeArray[z + k[1]][x + k[0]]) {
                        bool wall_left  = (x + k[0] + k[1] < mazeLength && x + k[0] + k[1] >= 0 && z + k[1] - k[0] < mazeLength && z + k[1] - k[0] >= 0 && !mazeArray[z + k[1] - k[0]][x + k[0] + k[1]]);
                        bool wall_right = (x + k[0] - k[1] < mazeLength && x + k[0] - k[1] >= 0 && z + k[1] + k[0] < mazeLength && z + k[1] + k[0] >= 0 && !mazeArray[z + k[1] + k[0]][x + k[0] - k[1]]);
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
                    // rotate kernel 90 degrees
                    int temp = k[1];
                    k[1] = -k[0];
                    k[0] = temp;
                    // rotate m 90 degrees
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
    uniforms[UNIFORM_AMBIENTCOLOR] = glGetUniformLocation(programObject, "ambientColor");
    uniforms[UNIFORM_SPOTLIGHT] = glGetUniformLocation(programObject, "spotlight");
    uniforms[UNIFORM_SPOTLIGHTCUTOFF] = glGetUniformLocation(programObject, "spotlightCutoff");
    uniforms[UNIFORM_SPOTLIGHTCOLOR] = glGetUniformLocation(programObject, "spotlightColor");
    uniforms[UNIFORM_FOG] = glGetUniformLocation(programObject, "fog");
    uniforms[UNIFORM_FOGCOLOR] = glGetUniformLocation(programObject, "fogColor");
    uniforms[UNIFORM_FOGEND] = glGetUniformLocation(programObject, "fogEnd");
    uniforms[UNIFORM_FOGDENSITY] = glGetUniformLocation(programObject, "fogDensity");
    uniforms[UNIFORM_FOGUSEEXP] = glGetUniformLocation(programObject, "fogUseExp");
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
    for(int z = 0; z < mazeLength; z++){
        for(int x = 0; x < mazeLength; x++){
            if (z == floor(cameraZ) && x == floor(cameraX)) {
                float rotDegrees = GLKMathRadiansToDegrees(cameraRot);
                if (rotDegrees > 337.5 || rotDegrees <= 22.5) {
                    [string appendString:@"@↓"];
                } else if (rotDegrees > 22.5 && rotDegrees <= 67.5) {
                    [string appendString:@"@↘"];
                } else if (rotDegrees > 67.5 && rotDegrees <= 112.5) {
                    [string appendString:@"@→"];
                } else if (rotDegrees > 112.5 && rotDegrees <= 157.5) {
                    [string appendString:@"@↗"];
                } else if (rotDegrees > 157.5 && rotDegrees <= 202.5) {
                    [string appendString:@"@↑"];
                } else if (rotDegrees > 202.5 && rotDegrees <= 247.5) {
                    [string appendString:@"@↖"];
                } else if (rotDegrees > 247.5 && rotDegrees <= 292.5) {
                    [string appendString:@"@←"];
                } else if (rotDegrees > 292.5 && rotDegrees <= 337.5) {
                    [string appendString:@"@↙"];
                }
            } else if (z == floor(nmeZ) && x == floor(nmeX)) {
                [string appendString:@"&&"];
            } else {
                if(mazeArray[z][x]){
                    [string appendString:@"  "];
                } else {
                    [string appendString:@"██"];
                }
            }
        }
        [string appendString:@"\n"];
    }
    return string;
}

@end

