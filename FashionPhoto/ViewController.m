//
//  ViewController.m
//  FashionPhoto
//
//  Created by Nikola Grcevski on 12/24/2013.
//  Copyright (c) 2013 Exquisitus Inc. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>
#import "UIImage+ImageEffects.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;

#pragma mark -
#pragma mark OpenCV Support Methods

- (void)dealloc {
	AudioServicesDisposeSystemSoundID(alertSoundID);
}

#define RED 0
#define GREEN 1
#define BLUE 2

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
    
	return ret;
}

- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}

#pragma mark -
#pragma mark Utilities for internal use

- (void)showProgressIndicator:(NSString *)text {
	self.view.userInteractionEnabled = FALSE;
	if(!progressHUD) {
		CGFloat w = 160.0f, h = 120.0f;
		progressHUD = [[UIProgressHUD alloc] initWithFrame:CGRectMake((self.view.frame.size.width-w)/2, (self.view.frame.size.height-h)/2, w, h)];
		[progressHUD setText:text];
		[progressHUD showInView:self.view];
	}
}

- (void)hideProgressIndicator {
	self.view.userInteractionEnabled = TRUE;
	if(progressHUD) {
		[progressHUD hide];
		progressHUD = nil;
        
		AudioServicesPlaySystemSound(alertSoundID);
	}
}

- (CGRect)transformContextToFlipRect:(CGContextRef)c box:(CGRect) destBox
{
	CGContextTranslateCTM(c, 0, CGRectGetMaxY(destBox));
	CGContextScaleCTM(c, 1.0, -1.0);
	destBox = CGRectOffset(destBox, 0, -destBox.origin.y);
	
	return destBox;
}

- (void)medianColor:(UIImage *)image mask:(IplImage *)img2 boundingBox:(CGRect)box result:(CGFloat *) components {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* origData = CFDataGetBytePtr(pixelData);
    
    NSMutableArray *redArr = [[NSMutableArray alloc] init];
    NSMutableArray *greenArr = [[NSMutableArray alloc] init];
    NSMutableArray *blueArr = [[NSMutableArray alloc] init];
    
    for(int y=box.origin.y; y<box.size.height; y+=10) {
        int foundX = 0;
        for(int x=box.origin.x; x<(box.origin.x+box.size.width); x++) {
            char color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                foundX = x;
                break;
            }
        }
        
        for(int x=box.origin.x; x<foundX; x++) {
            int pixelPos = ((img2->widthStep  * y) + x ) * 4;
            UInt8 red = origData[pixelPos];
            UInt8 green = origData[pixelPos + 1];
            UInt8 blue = origData[pixelPos + 2];
            
            if (red == 0 && green == 0 && blue == 0)
                continue;
            
            [redArr addObject:[NSNumber numberWithInt:red]];
            [greenArr addObject:[NSNumber numberWithInt:green]];
            [blueArr addObject:[NSNumber numberWithInt:blue]];
        }
        
        for(int x=(box.origin.x + box.size.width); x>foundX; x--) {
            char color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                foundX = x;
                break;
            }
        }
        
        for(int x=(box.origin.x + box.size.width); x>foundX; x--) {
            int pixelPos = ((img2->widthStep  * y) + x ) * 4;
            UInt8 red = origData[pixelPos];
            UInt8 green = origData[pixelPos + 1];
            UInt8 blue = origData[pixelPos + 2];
            
            if (red == 0 && green == 0 && blue == 0)
                continue;
            
            [redArr addObject:[NSNumber numberWithInt:red]];
            [greenArr addObject:[NSNumber numberWithInt:green]];
            [blueArr addObject:[NSNumber numberWithInt:blue]];
        }
    }
    
    NSArray *sortedRedArr = [redArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    NSArray *sortedGreenArr = [greenArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    NSArray *sortedBlueArr = [blueArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    if (sortedRedArr.count>0) {
        components[RED] = [[sortedRedArr objectAtIndex:(sortedRedArr.count+1)/2] floatValue];
    }
    if (sortedGreenArr.count>0) {
        components[GREEN] = [[sortedGreenArr objectAtIndex:(sortedGreenArr.count+1)/2] floatValue];
    }
    
    if (sortedBlueArr.count>0) {
        components[BLUE] = [[sortedBlueArr objectAtIndex:(sortedBlueArr.count+1)/2] floatValue];
    }
    
    CFRelease(pixelData);
}

- (void)medianColorReversed:(UIImage *)image mask:(IplImage *)img2 boundingBox:(CGRect)box result:(CGFloat *) components {
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* origData = CFDataGetBytePtr(pixelData);
    
    NSMutableArray *redArr = [[NSMutableArray alloc] init];
    NSMutableArray *greenArr = [[NSMutableArray alloc] init];
    NSMutableArray *blueArr = [[NSMutableArray alloc] init];
    
    for(int x=box.origin.x; x<box.size.width; x+=10) {
        int foundY = 0;
        for(int y=box.origin.y; y<(box.origin.y+box.size.height)-1; y++) {
            char color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                foundY = y;
                break;
            }
        }
        
        for(int y=box.origin.y; y<foundY; y++) {
            int pixelPos = ((img2->widthStep  * y) + x ) * 4;
            UInt8 red = origData[pixelPos];
            UInt8 green = origData[pixelPos + 1];
            UInt8 blue = origData[pixelPos + 2];
            
            if (red == 0 && green == 0 && blue == 0)
                continue;
            
            if (origData[pixelPos+3] == 0)
                continue;
            
            [redArr addObject:[NSNumber numberWithInt:red]];
            [greenArr addObject:[NSNumber numberWithInt:green]];
            [blueArr addObject:[NSNumber numberWithInt:blue]];
        }
        
        for(int y=(box.origin.y + box.size.height)-1; y>foundY; y--) {
            char color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                foundY = y;
                break;
            }
        }
        
        for(int y=(box.origin.y + box.size.height)-1; y>foundY; y--) {
            int pixelPos = ((img2->widthStep  * y) + x ) * 4;
            UInt8 red = origData[pixelPos];
            UInt8 green = origData[pixelPos + 1];
            UInt8 blue = origData[pixelPos + 2];
            
            if (red == 0 && green == 0 && blue == 0)
                continue;
            
            if (origData[pixelPos+3] == 0)
                continue;
            
            [redArr addObject:[NSNumber numberWithInt:red]];
            [greenArr addObject:[NSNumber numberWithInt:green]];
            [blueArr addObject:[NSNumber numberWithInt:blue]];
        }
    }
    
    NSArray *sortedRedArr = [redArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    NSArray *sortedGreenArr = [greenArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    NSArray *sortedBlueArr = [blueArr sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a compare:b];
    }];
    
    
    if (sortedRedArr.count>0) {
        components[RED] = [[sortedRedArr objectAtIndex:(sortedRedArr.count+1)/2] floatValue];
    }
    if (sortedGreenArr.count>0) {
        components[GREEN] = [[sortedGreenArr objectAtIndex:(sortedGreenArr.count+1)/2] floatValue];
    }
    
    if (sortedBlueArr.count>0) {
        components[BLUE] = [[sortedBlueArr objectAtIndex:(sortedBlueArr.count+1)/2] floatValue];
    }
    
    CFRelease(pixelData);
}

- (BOOL)fitsThreshold:(UInt8 *)pixel color:(float *)color threshold:(float)threshold {
    int red = color[RED];
    int green = color[GREEN];
    int blue = color[BLUE];
    
    int pixelRed = pixel[RED+1];
    int pixelGreen = pixel[GREEN+1];
    int pixelBlue = pixel[BLUE+1];
    
    int diff = (int)threshold;
    
    if ((pixelRed < (red-diff)) ||
        (pixelRed > (red+diff)))
        return NO;
    
    if ((pixelGreen < (green-diff)) ||
        (pixelGreen > (green+diff)))
        return NO;
    
    if ((pixelBlue < (blue-diff)) ||
        (pixelBlue > (blue+diff)))
        return NO;
    
    return YES;
}

- (double)distance:(UInt8 *)pixel color:(float *)color {
    int red = color[RED];
    int green = color[GREEN];
    int blue = color[BLUE];
    
    int pixelRed = pixel[RED+1];
    int pixelGreen = pixel[GREEN+1];
    int pixelBlue = pixel[BLUE+1];
    
    return sqrt((red-pixelRed)*(red-pixelRed) +
                (green-pixelGreen)*(green-pixelGreen) +
                (blue-pixelBlue)*(blue-pixelBlue));
}

CGContextRef CreateARGBBitmapContext (CGImageRef inImage)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

- (UIImage *)makeBackgroundTransparent:(UIImage *)image mask:(IplImage *)img2 medianColour:(CGFloat *)median threshold:(float)threshold {
    CGImageRef imageRef = image.CGImage;
    
    size_t width                    = CGImageGetWidth(imageRef);
    size_t height                   = CGImageGetHeight(imageRef);
    size_t bitsPerComponent         = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel             = CGImageGetBitsPerPixel(imageRef);
    size_t bytesPerRow              = CGImageGetBytesPerRow(imageRef);
    
    // Create the bitmap context
    CGContextRef cgctx = CreateARGBBitmapContext(imageRef);
    if (cgctx == NULL)
    {
        // error creating context
        return nil;
    }
    
    // Get image width, height. We'll use the entire image.
    CGRect rect = {{0,0},{width,height}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(cgctx, rect, imageRef);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    UInt8 *pixels = CGBitmapContextGetData (cgctx);
    NSInteger count = 0;
    for(int y=0; y<height; y++) {
        int leftX = 0;
        int rightX = 0;
        
        for(int x=0; x<width-1; x++) {
            UInt8 color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                leftX = x;
                break;
            }
        }
        
        for(int x=width-1; x>leftX; x--) {
            UInt8 color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                rightX = x;
                break;
            }
        }
        
        for(int x=0; x<leftX; x++) {
            int pixelPos = ((width  * y) + x ) * 4;
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold]) {
                pixels[pixelPos] =
                pixels[pixelPos+1] =
                pixels[pixelPos+2] =
                pixels[pixelPos+3] = 0;
                count++;
            }
        }
        
        for(int x=width-1; x>rightX; x--) {
            int pixelPos = ((width  * y) + x ) * 4;
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold]) {
                pixels[pixelPos] =
                pixels[pixelPos+1] =
                pixels[pixelPos+2] =
                pixels[pixelPos+3] = 0;
                count++;
            }
        }
        
        for(int x=leftX; x<rightX; x++) {
            int pixelPos = ((width  * y) + x ) * 4;
            
            if (pixels[pixelPos+3] == 0)
                continue;
            
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold/3.0]) {
                float distance = [self distance:(pixels+pixelPos) color:median];
                pixels[pixelPos+3] = (int)(distance/threshold * 255.0);
                
                float multiplier = (float)pixels[pixelPos+3]/255.0f;
                pixels[pixelPos] = MAX(0,MIN(255,(int)(pixels[pixelPos]*multiplier)));
                pixels[pixelPos+1] = MAX(0,MIN(255,(int)(pixels[pixelPos+1]*multiplier)));
                pixels[pixelPos+2] = MAX(0,MIN(255,(int)(pixels[pixelPos+2]*multiplier)));
            }
        }
    }
    
    NSLog(@"Count: %d", count);
    
    for(int x=0; x<width; x++) {
        int topY = 0;
        int bottomY = 0;
        
        for(int y=0; y<height-1; y++) {
            UInt8 color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                topY = y;
                break;
            }
        }
        
        for(int y=height-1; y>topY; y--) {
            UInt8 color = img2->imageData[y * img2->widthStep + x];
            if (color != 0) {
                bottomY = y;
                break;
            }
        }
        
        for(int y=0; y<topY; y++) {
            int pixelPos = ((width  * y) + x ) * 4;
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold]) {
                pixels[pixelPos] =
                pixels[pixelPos+1] =
                pixels[pixelPos+2] =
                pixels[pixelPos+3] = 0;
            }
        }
        
        for(int y=height-1; y>bottomY; y--) {
            int pixelPos = ((width  * y) + x ) * 4;
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold]) {
                pixels[pixelPos] =
                pixels[pixelPos+1] =
                pixels[pixelPos+2] =
                pixels[pixelPos+3] = 0;
            }
        }
        
        for(int y=topY; y<bottomY; y++) {
            int pixelPos = ((width  * y) + x ) * 4;
            
            if (pixels[pixelPos+3] == 0)
                continue;
            
            if ([self fitsThreshold:(pixels+pixelPos) color:median threshold:threshold/3.0]) {
                float distance = [self distance:(pixels+pixelPos) color:median];
                pixels[pixelPos+3] = (int)(distance/threshold * 255.0);
                
                float multiplier = (float)pixels[pixelPos+3]/255.0f;
                pixels[pixelPos] = MAX(0,MIN(255,(int)(pixels[pixelPos]*multiplier)));
                pixels[pixelPos+1] = MAX(0,MIN(255,(int)(pixels[pixelPos+1]*multiplier)));
                pixels[pixelPos+2] = MAX(0,MIN(255,(int)(pixels[pixelPos+2]*multiplier)));
                pixels[pixelPos+3] = (int)(distance/threshold * 255.0);
            }
        }
    }
    
    // create a new image from the modified pixel data
    CGColorSpaceRef colorspace      = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo         = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst;
    CGDataProviderRef provider      = CGDataProviderCreateWithData(NULL, pixels, width*height*4, NULL);
    
    CGImageRef newImageRef = CGImageCreate (
                                            width,
                                            height,
                                            bitsPerComponent,
                                            bitsPerPixel,
                                            bytesPerRow,
                                            colorspace,
                                            bitmapInfo,
                                            provider,
                                            NULL,
                                            false,
                                            kCGRenderingIntentDefault
                                            );
    // the modified image
    UIImage *newImage   = [UIImage imageWithCGImage:newImageRef];
    
    // cleanup
    CGContextRelease(cgctx);
    /*if (pixels) {
        free(pixels);
    }*/
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    CGImageRelease(newImageRef);
    
    return newImage;
}

- (void)removeBackgroundColor:(NSNumber *)threshold {
    imageView.backgroundColor = [UIColor clearColor];
    
    if(imageView.image) {
        cvSetErrMode(CV_ErrModeParent);
        
        // Create grayscale IplImage from UIImage
        UIImage *originalImage = imageView.image;//[self imageWithAlpha:imageView.image];
        IplImage *img_color = [self CreateIplImageFromUIImage:imageView.image];
        
        IplImage *img = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
        cvCvtColor(img_color, img, CV_BGR2GRAY);
        cvReleaseImage(&img_color);
        
        // Detect edge
        IplImage *img2 = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
        cvCanny(img, img2, 64, 128, 3);
        cvReleaseImage(&img);
        
        float colors[3] = {0.0f, 0.0f, 0.0f};
        
        CGRect box = CGRectMake(0, 0, img2->width, img2->height);
        [self medianColor:originalImage mask:img2 boundingBox:box result:colors];
        NSLog(@"%f %f %f", colors[0], colors[1], colors[2]);

        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self hideProgressIndicator];
        }];
        
        float thresholds[3];
        
        thresholds[RED] = thresholds[GREEN] = thresholds[BLUE] = [threshold floatValue];
        
        UIImage *modImage = [self makeBackgroundTransparent:originalImage mask:img2 medianColour:colors threshold:[threshold floatValue]];
        
        cvReleaseImage(&img2);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            imageView.image = modImage;
        }];
    }
}

#pragma mark -
#pragma mark IBAction

- (IBAction)loadImage:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Use Photo from Library", @"Take Photo with Camera", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
}

- (IBAction)saveImage:(id)sender {
	if(imageView.image) {
		[self showProgressIndicator:@"Saving"];
		UIImageWriteToSavedPhotosAlbum(imageView.image, self, @selector(finishUIImageWriteToSavedPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
	}
}

- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	[self hideProgressIndicator];
}

- (void)enableDisableButtons {
    [self.downThresholdButton setEnabled:(colorRemovalThreshold>0.0)];
    [self.upThresholdButton setEnabled:(colorRemovalThreshold<255.0)];
}

- (IBAction)downThreshold:(id)sender {
    imageView.image = savedImage;
    colorRemovalThreshold -= 10.0;
    if (colorRemovalThreshold<0.0)
        colorRemovalThreshold = 0.0;
    else
        [self.downThresholdButton setEnabled:YES];
    
    [self enableDisableButtons];
	[self showProgressIndicator:@"Processing"];
	[self performSelectorInBackground:@selector(removeBackgroundColor:) withObject:[NSNumber numberWithFloat:colorRemovalThreshold]];
}

- (IBAction)upThreshold:(id)sender {
    imageView.image = savedImage;
    colorRemovalThreshold += 10.0;
    if (colorRemovalThreshold>255.0)
        colorRemovalThreshold = 255.0;
    else
        [self.upThresholdButton setEnabled:YES];
    
    [self enableDisableButtons];
	[self showProgressIndicator:@"Processing"];
	[self performSelectorInBackground:@selector(removeBackgroundColor:) withObject:[NSNumber numberWithFloat:colorRemovalThreshold]];
}

#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &alertSoundID);
}

- (void)viewDidAppear:(BOOL)animated {
    if (!notFirstTime) {
        [self loadImage:nil];
        notFirstTime = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerControllerSourceType sourceType = -1;
    
    if (buttonIndex == 0) {
        sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    } else if(buttonIndex == 1) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        // Cancel
        return;
    }
    
    if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = sourceType;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:^(void) {}];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (CGSize)sizeForWidth:(int)maxWidth image:(UIImage *)anImage {
	float height = (float)(anImage.size.height/anImage.size.width)*(float)maxWidth;
	float width = maxWidth;
    
	return CGSizeMake(width, height);
}

- (UIImage *)resizedImage:(UIImage *)image newSize:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    BOOL drawTransposed;
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
            
        default:
            drawTransposed = NO;
    }
    
    return [self resizedImage:image newSize:newSize
                    transform:[self transformForOrientation:image newSize:newSize]
               drawTransposed:drawTransposed
         interpolationQuality:quality];
}


#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(UIImage *)image newSize:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = image.CGImage;
    
    CGImageAlphaInfo    alphaInfo = CGImageGetAlphaInfo(imageRef);
	
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                8,//CGImageGetBitsPerComponent(imageRef),
                                                0,
												CGColorSpaceCreateDeviceRGB(),
												(CGBitmapInfo)alphaInfo);
    //*CGImageGetBitmapInfo(imageRef)*);*/
    
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(UIImage *)image newSize:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
    }
    
    return transform;
}

- (void)imagePickerController:(UIImagePickerController *)picker
		didFinishPickingImage:(UIImage *)image
				  editingInfo:(NSDictionary *)editingInfo
{
	UIImage *scaledImage = [self resizedImage:image newSize:[self sizeForWidth:MIN(420,image.size.width) image:image] interpolationQuality:kCGInterpolationHigh];
    
    [self.upThresholdButton setEnabled:YES];
    [self.downThresholdButton setEnabled:YES];
    
    scaledImage = [UIImage imageWithData:UIImagePNGRepresentation(scaledImage)];
    colorRemovalThreshold = 100.0;
    
    savedImage = scaledImage;
	imageView.image = scaledImage;
	[picker dismissModalViewControllerAnimated:YES];
    picker = nil;
    [self showProgressIndicator:@"Processing"];
	[self performSelectorInBackground:@selector(removeBackgroundColor:) withObject:[NSNumber numberWithFloat:colorRemovalThreshold]];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:^(void){}];
    picker = nil;
}

@end
