//
//  ViewController.h
//  FashionPhoto
//
//  Created by Nikola Grcevski on 12/24/2013.
//  Copyright (c) 2013 Exquisitus Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioToolbox.h>

@interface UIProgressIndicator : UIActivityIndicatorView {
}

+ (struct CGSize)size;
- (int)progressIndicatorStyle;
- (void)setProgressIndicatorStyle:(int)fp8;
- (void)setStyle:(int)fp8;
- (void)setAnimating:(BOOL)fp8;
- (void)startAnimation;
- (void)stopAnimation;
@end

@interface UIProgressHUD : UIView {
    UIProgressIndicator *_progressIndicator;
    UILabel *_progressMessage;
    UIImageView *_doneView;
    UIWindow *_parentWindow;
    struct {
        unsigned int isShowing:1;
        unsigned int isShowingText:1;
        unsigned int fixedFrame:1;
        unsigned int reserved:30;
    } _progressHUDFlags;
}

- (id)_progressIndicator;
- (id)initWithFrame:(struct CGRect)fp8;
- (void)setText:(id)fp8;
- (void)setShowsText:(BOOL)fp8;
- (void)setFontSize:(int)fp8;
- (void)drawRect:(struct CGRect)fp8;
- (void)layoutSubviews;
- (void)showInView:(id)fp8;
- (void)hide;
- (void)done;
- (void)dealloc;
@end


@interface ViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    IBOutlet UIImageView *imageView;
    UIProgressHUD *progressHUD;
    SystemSoundID alertSoundID;
    BOOL notFirstTime;
    UIImage *savedImage;
    
    CGFloat colorRemovalThreshold;
}

- (IBAction)loadImage:(id)sender;
- (IBAction)saveImage:(id)sender;
- (IBAction)downThreshold:(id)sender;
- (IBAction)upThreshold:(id)sender;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *downThresholdButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *upThresholdButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *fixedSpace;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *flexibleSpace;

@end
