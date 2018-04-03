//
//  ViewController.m
//  Modified by Daniel Tian (February 13, 2018)

#import "ViewController.h"

@interface ViewController() {
    Renderer *glesRenderer; // ###
}
@property (strong, nonatomic) IBOutlet UIView *ModelPanel;
@end

@implementation ViewController

- (IBAction)resetButton:(id)sender {
    glesRenderer.isDay = !glesRenderer.isDay;
}

- (IBAction)spotlightBtn:(id)sender {
    glesRenderer.spotlightToggle = !glesRenderer.spotlightToggle;
}

- (IBAction)fogBtn:(id)sender {
    glesRenderer.fogToggle = !glesRenderer.fogToggle;
}

- (IBAction)fogLinBtn:(id)sender {
    glesRenderer.fogUseExp = false;
}
    
- (IBAction)fogExpBtn:(id)sender {
    glesRenderer.fogUseExp = true;
}
    
- (IBAction)plusScale:(id)sender {
    glesRenderer.scaleNME *= 1.25;
}

- (IBAction)minusScale:(id)sender {
    glesRenderer.scaleNME *= 0.8;
}

- (IBAction)swapControl:(id)sender {
    glesRenderer.controllingNME = !glesRenderer.controllingNME;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // ### <<<
    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view];
    [glesRenderer loadResources];
    // ### >>>
    
    // single finger double tap
    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:doubleTap];
    
    // double finger double tap
    UITapGestureRecognizer *doubleDoubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleDoubleTap:)];
    doubleDoubleTap.numberOfTapsRequired = 2;
    [doubleDoubleTap setNumberOfTouchesRequired:2];
    [self.view addGestureRecognizer:doubleDoubleTap];
    
    // panning
    UIPanGestureRecognizer *panning =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panning];
    
    _minimapLabel.hidden = true;
    _ModelPanel.hidden=true;
}

// resets position
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    [glesRenderer reset];
}

// toggles minimap
- (void)handleDoubleDoubleTap:(UITapGestureRecognizer *)recognizer {
    _minimapLabel.hidden = !_minimapLabel.isHidden;
}

// vertical panning moves camera forwards and backwards
// horizontal panning turns the camera left and right
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translatedPoint = [recognizer translationInView:recognizer.view.superview];
    [recognizer setTranslation:CGPointZero inView:recognizer.view.superview];
    float scale = 1.0f / recognizer.view.superview.bounds.size.width; // scales panning to be independant of screen resolution
    translatedPoint.x *= 2 * scale;
    translatedPoint.y *= 5 * scale;
    if (!glesRenderer.controllingNME) {
        [glesRenderer translateRect:translatedPoint.x secondDelta:translatedPoint.y];
    } else {
        [glesRenderer moveNME:translatedPoint.x secondDelta:translatedPoint.y];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)update {
    [glesRenderer update];
    _ModelPanel.hidden = !glesRenderer.sameCell && !glesRenderer.controllingNME;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [glesRenderer draw:rect];
    _positionLabel.text = [glesRenderer getPosition];
    _rotationLabel.text = [glesRenderer getRotation];
    _minimapLabel.text = [glesRenderer getMinimap];
}

@end
