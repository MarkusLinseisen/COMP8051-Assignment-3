//
//  ViewController.m
//  Modified by Daniel Tian (February 13, 2018)

#import "ViewController.h"

@interface ViewController() {
    Renderer *glesRenderer; // ###
}
@end


@implementation ViewController

- (IBAction)resetButton:(id)sender {
    [glesRenderer reset];
}

- (IBAction)theButton:(id)sender {
    NSLog(@"You pressed the Button!");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // ### <<<
    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view];
    [glesRenderer loadModels];
    // ### >>>
    
    //Handling single tap - not needed, utilized for testing
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    
    //Handles double tapping
    UITapGestureRecognizer *doubleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleFingerTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleFingerTap];
    
    //handles panning
    UIPanGestureRecognizer *panning =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panning];
    
    //handles two finger panning
    UIPanGestureRecognizer *twoFingerPan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerPan:)];

    twoFingerPan.minimumNumberOfTouches = 2;
    twoFingerPan.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer:twoFingerPan];
    
    //handles pinch gesture
    UIPinchGestureRecognizer *pinchHandler =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
     
    [self.view addGestureRecognizer:pinchHandler];
    
    [glesRenderer generateMaze]; //test generate maze
}

//If the cube is not rotating, the user can scale the cube
- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    if (glesRenderer._isRotating == 0) {//not rotating
        [glesRenderer scaleRect:(recognizer.scale)];
    }
}

//If the cube is not rotating, user can rotate cube by single finger dragging horizontally or vertically
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (glesRenderer._isRotating == 1) { //if rotating, return
        return;
    }
    
    float rotAngle = 0.15f;
    CGPoint vel = [recognizer velocityInView:self.view];
    
    if( fabs( vel.x) > fabs( vel.y) ) {
        if (vel.x > 0) {
            // user dragged towards the right
            [glesRenderer rotateRectHorizontal:(rotAngle)];
        } else {
            // user dragged towards the left
            [glesRenderer rotateRectHorizontal:(-rotAngle)];
        }
    } else {
        if (vel.y < 0) {
            //up
            [glesRenderer rotateRectVertical:(-rotAngle)];
        } else {
            //down
            [glesRenderer rotateRectVertical:(rotAngle)];
        }
    }
}

//Two finger dragging will translate the cube
- (void)handleTwoFingerPan:(UIPanGestureRecognizer *)recognizer {
    //if rotating, return
    //if(glesRenderer._isRotating == 1) return;
    
    float translationDelta = 0.1f;
   //CGPoint currentlocation = [recognizer locationInView:self.view];
    
    CGPoint vel = [recognizer velocityInView:self.view];
    
    if( fabs( vel.x) > fabs( vel.y) ){
        if (vel.x > 0) {
            // user dragged towards the right
            [glesRenderer translateRect:(translationDelta) secondDelta:(0.0f)];
        } else {
            // user dragged towards the left
            [glesRenderer translateRect:(-translationDelta) secondDelta:(0.0f)];
        }
    } else {
        if (vel.y < 0) {
            //up
            [glesRenderer translateRect:(0.0f) secondDelta:(translationDelta)];
        } else {
            //down
            [glesRenderer translateRect:(0.0f) secondDelta:(-translationDelta)];
        }
    }
    
}

//Double tap will toggle whether the cube will automatically rotate
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    if (glesRenderer._isRotating == 1) {
        glesRenderer._isRotating = 0;
    } else {
        glesRenderer._isRotating = 1;
    }
}

//single tap testing method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    //printf("testing");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)update {
    [glesRenderer update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [glesRenderer draw:rect];
    _positionLabel.text = [glesRenderer getPosition];   //updates position, and displays it on label
    _rotationLabel.text = [glesRenderer getRotation];   //displays rotation every frame (to a label)
}

@end