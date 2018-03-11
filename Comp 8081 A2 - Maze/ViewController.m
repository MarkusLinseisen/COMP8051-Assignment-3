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

//single tap testing method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
}

//Double tap will toggle whether the cube will automatically rotate
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
}

// vertical panning moves camera forwards and backwards
// horizontal panning turns the camera left and right
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:recognizer.view.superview];
    [recognizer setTranslation:CGPointZero inView:recognizer.view.superview];
    float scale = 1.0f / recognizer.view.superview.bounds.size.width; // scales panning to be independant of screen resolution
    [glesRenderer translateRect:(translatedPoint.x * scale) secondDelta:(translatedPoint.y * scale)];
}

- (void)handleTwoFingerPan:(UIPanGestureRecognizer *)recognizer {
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)update {
    [glesRenderer update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [glesRenderer draw:rect];
    _positionLabel.text = [glesRenderer getPosition];
    _rotationLabel.text = [glesRenderer getRotation];
}

@end
