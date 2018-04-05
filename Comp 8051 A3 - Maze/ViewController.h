//
//  ViewController.h
//  c8051intro3
//
//  Created by Borna Noureddin on 2017-12-20.
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//  Modified by Daniel Tian (February 13, 2018)
//

#import <UIKit/UIKit.h>
#import "Renderer.h" // ###

//@interface ViewController : UIViewController
@interface ViewController : GLKViewController { // ###
}

@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *rotationLabel;
@property (weak, nonatomic) IBOutlet UILabel *minimapLabel;

@end
