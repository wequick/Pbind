//
//  PBLLResource.m
//  Pbind
//
//  Created by galen on 17/7/30.
//

#import "PBLLResource.h"

#if (PBLIVE_ENABLED)

#import <Pbind/Pbind.h>

@implementation PBLLResource

+ (UIImage *)imageWithWidth:(CGFloat)width height:(CGFloat)height draw:(dispatch_block_t)drawBlock {
    CGRect imageRect = CGRectMake(0.0, 0.0, width, height);
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, [UIScreen mainScreen].scale);
    
    drawBlock();
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)logoImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [self imageWithWidth:32.f height:32.f draw:^{
            //// Color Declarations
//            UIColor* fillColor3 = PBColorMake(@"5D74E9");//[UIColor whiteColor];
            //// General Declarations
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            //// Color Declarations
            UIColor* fillColor4 = [UIColor whiteColor];;
            
            //// Group
            {
                CGContextSaveGState(context);
                CGContextBeginTransparencyLayer(context, NULL);
                
                //// Clip Clip 2
                UIBezierPath* clip2Path = [UIBezierPath bezierPath];
                [clip2Path moveToPoint: CGPointMake(16, 32)];
                [clip2Path addCurveToPoint: CGPointMake(32, 16) controlPoint1: CGPointMake(24.84, 32) controlPoint2: CGPointMake(32, 24.84)];
                [clip2Path addCurveToPoint: CGPointMake(16, 0) controlPoint1: CGPointMake(32, 7.16) controlPoint2: CGPointMake(24.84, 0)];
                [clip2Path addCurveToPoint: CGPointMake(0, 16) controlPoint1: CGPointMake(7.16, 0) controlPoint2: CGPointMake(0, 7.16)];
                [clip2Path addCurveToPoint: CGPointMake(16, 32) controlPoint1: CGPointMake(0, 24.84) controlPoint2: CGPointMake(7.16, 32)];
                [clip2Path closePath];
                clip2Path.usesEvenOddFillRule = YES;
                
                [clip2Path addClip];
                
                
                //// Group 2
                {
                    CGContextSaveGState(context);
                    CGContextBeginTransparencyLayer(context, NULL);
                    
                    //// Clip Clip
                    UIBezierPath* clipPath = [UIBezierPath bezierPath];
                    [clipPath moveToPoint: CGPointMake(12.13, 20.25)];
                    [clipPath addCurveToPoint: CGPointMake(-19.8, 48) controlPoint1: CGPointMake(10.03, 35.91) controlPoint2: CGPointMake(-3.46, 48)];
                    [clipPath addCurveToPoint: CGPointMake(-52, 16) controlPoint1: CGPointMake(-37.58, 48) controlPoint2: CGPointMake(-52, 33.67)];
                    [clipPath addCurveToPoint: CGPointMake(-19.8, -16) controlPoint1: CGPointMake(-52, -1.67) controlPoint2: CGPointMake(-37.58, -16)];
                    [clipPath addCurveToPoint: CGPointMake(12.13, 11.75) controlPoint1: CGPointMake(-3.46, -16) controlPoint2: CGPointMake(10.03, -3.91)];
                    [clipPath addCurveToPoint: CGPointMake(18.95, 8) controlPoint1: CGPointMake(13.55, 9.5) controlPoint2: CGPointMake(16.07, 8)];
                    [clipPath addCurveToPoint: CGPointMake(27, 16) controlPoint1: CGPointMake(23.4, 8) controlPoint2: CGPointMake(27, 11.58)];
                    [clipPath addCurveToPoint: CGPointMake(18.95, 24) controlPoint1: CGPointMake(27, 20.42) controlPoint2: CGPointMake(23.4, 24)];
                    [clipPath addCurveToPoint: CGPointMake(12.13, 20.25) controlPoint1: CGPointMake(16.07, 24) controlPoint2: CGPointMake(13.55, 22.5)];
                    [clipPath closePath];
                    [clipPath moveToPoint: CGPointMake(18.95, 22.5)];
                    [clipPath addCurveToPoint: CGPointMake(25.49, 16) controlPoint1: CGPointMake(22.56, 22.5) controlPoint2: CGPointMake(25.49, 19.59)];
                    [clipPath addCurveToPoint: CGPointMake(18.95, 9.5) controlPoint1: CGPointMake(25.49, 12.41) controlPoint2: CGPointMake(22.56, 9.5)];
                    [clipPath addCurveToPoint: CGPointMake(12.41, 16) controlPoint1: CGPointMake(15.34, 9.5) controlPoint2: CGPointMake(12.41, 12.41)];
                    [clipPath addCurveToPoint: CGPointMake(18.95, 22.5) controlPoint1: CGPointMake(12.41, 19.59) controlPoint2: CGPointMake(15.34, 22.5)];
                    [clipPath closePath];
                    [clipPath moveToPoint: CGPointMake(-19.8, 46.5)];
                    [clipPath addCurveToPoint: CGPointMake(10.9, 16) controlPoint1: CGPointMake(-2.84, 46.5) controlPoint2: CGPointMake(10.9, 32.84)];
                    [clipPath addCurveToPoint: CGPointMake(-19.8, -14.5) controlPoint1: CGPointMake(10.9, -0.84) controlPoint2: CGPointMake(-2.84, -14.5)];
                    [clipPath addCurveToPoint: CGPointMake(-50.49, 16) controlPoint1: CGPointMake(-36.75, -14.5) controlPoint2: CGPointMake(-50.49, -0.84)];
                    [clipPath addCurveToPoint: CGPointMake(-19.8, 46.5) controlPoint1: CGPointMake(-50.49, 32.84) controlPoint2: CGPointMake(-36.75, 46.5)];
                    [clipPath closePath];
                    clipPath.usesEvenOddFillRule = YES;
                    
                    [clipPath addClip];
                    
                    
                    //// Rectangle Drawing
                    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(1, 0, 31, 32)];
                    [fillColor4 setFill];
                    [rectanglePath fill];
                    
                    
                    CGContextEndTransparencyLayer(context);
                    CGContextRestoreGState(context);
                }
                
                
                CGContextEndTransparencyLayer(context);
                CGContextRestoreGState(context);
            }

        }];
    });
    return image;
}

+ (UIImage *)copyImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [self imageWithWidth:24.f height:24.f draw:^{
            //// Color Declarations
            UIColor* fillColor2 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
            
            //// Text-files
            {
                //// Bezier Drawing
                UIBezierPath* bezierPath = [UIBezierPath bezierPath];
                [bezierPath moveToPoint: CGPointMake(22.1, 3.43)];
                [bezierPath addLineToPoint: CGPointMake(20.64, 3.43)];
                [bezierPath addCurveToPoint: CGPointMake(20.55, 3.45) controlPoint1: CGPointMake(20.61, 3.43) controlPoint2: CGPointMake(20.58, 3.44)];
                [bezierPath addLineToPoint: CGPointMake(20.55, 1.88)];
                [bezierPath addCurveToPoint: CGPointMake(18.66, 0) controlPoint1: CGPointMake(20.55, 0.84) controlPoint2: CGPointMake(19.7, 0)];
                [bezierPath addLineToPoint: CGPointMake(5.97, 0)];
                [bezierPath addCurveToPoint: CGPointMake(4.08, 1.88) controlPoint1: CGPointMake(4.93, 0) controlPoint2: CGPointMake(4.08, 0.84)];
                [bezierPath addLineToPoint: CGPointMake(4.08, 19.45)];
                [bezierPath addCurveToPoint: CGPointMake(5.97, 21.33) controlPoint1: CGPointMake(4.08, 20.49) controlPoint2: CGPointMake(4.93, 21.33)];
                [bezierPath addLineToPoint: CGPointMake(8.2, 21.33)];
                [bezierPath addLineToPoint: CGPointMake(8.2, 22.18)];
                [bezierPath addCurveToPoint: CGPointMake(10.02, 24) controlPoint1: CGPointMake(8.2, 23.19) controlPoint2: CGPointMake(9.01, 24)];
                [bezierPath addLineToPoint: CGPointMake(22.1, 24)];
                [bezierPath addCurveToPoint: CGPointMake(23.92, 22.18) controlPoint1: CGPointMake(23.1, 24) controlPoint2: CGPointMake(23.92, 23.19)];
                [bezierPath addLineToPoint: CGPointMake(23.92, 5.24)];
                [bezierPath addCurveToPoint: CGPointMake(22.1, 3.43) controlPoint1: CGPointMake(23.92, 4.24) controlPoint2: CGPointMake(23.1, 3.43)];
                [bezierPath closePath];
                [bezierPath moveToPoint: CGPointMake(4.83, 19.45)];
                [bezierPath addLineToPoint: CGPointMake(4.83, 1.88)];
                [bezierPath addCurveToPoint: CGPointMake(5.97, 0.76) controlPoint1: CGPointMake(4.83, 1.27) controlPoint2: CGPointMake(5.34, 0.76)];
                [bezierPath addLineToPoint: CGPointMake(18.66, 0.76)];
                [bezierPath addCurveToPoint: CGPointMake(19.8, 1.88) controlPoint1: CGPointMake(19.29, 0.76) controlPoint2: CGPointMake(19.8, 1.27)];
                [bezierPath addLineToPoint: CGPointMake(19.8, 19.45)];
                [bezierPath addCurveToPoint: CGPointMake(18.66, 20.57) controlPoint1: CGPointMake(19.8, 20.07) controlPoint2: CGPointMake(19.29, 20.57)];
                [bezierPath addLineToPoint: CGPointMake(5.97, 20.57)];
                [bezierPath addCurveToPoint: CGPointMake(4.83, 19.45) controlPoint1: CGPointMake(5.34, 20.57) controlPoint2: CGPointMake(4.83, 20.07)];
                [bezierPath closePath];
                [bezierPath moveToPoint: CGPointMake(23.17, 22.18)];
                [bezierPath addCurveToPoint: CGPointMake(22.1, 23.24) controlPoint1: CGPointMake(23.17, 22.77) controlPoint2: CGPointMake(22.69, 23.24)];
                [bezierPath addLineToPoint: CGPointMake(10.02, 23.24)];
                [bezierPath addCurveToPoint: CGPointMake(8.95, 22.18) controlPoint1: CGPointMake(9.43, 23.24) controlPoint2: CGPointMake(8.95, 22.77)];
                [bezierPath addLineToPoint: CGPointMake(8.95, 21.33)];
                [bezierPath addLineToPoint: CGPointMake(18.66, 21.33)];
                [bezierPath addCurveToPoint: CGPointMake(20.55, 19.45) controlPoint1: CGPointMake(19.7, 21.33) controlPoint2: CGPointMake(20.55, 20.49)];
                [bezierPath addLineToPoint: CGPointMake(20.55, 4.17)];
                [bezierPath addCurveToPoint: CGPointMake(20.64, 4.19) controlPoint1: CGPointMake(20.58, 4.18) controlPoint2: CGPointMake(20.61, 4.19)];
                [bezierPath addLineToPoint: CGPointMake(22.1, 4.19)];
                [bezierPath addCurveToPoint: CGPointMake(23.17, 5.24) controlPoint1: CGPointMake(22.69, 4.19) controlPoint2: CGPointMake(23.17, 4.66)];
                [bezierPath addLineToPoint: CGPointMake(23.17, 22.18)];
                [bezierPath closePath];
                bezierPath.miterLimit = 4;
                
                [fillColor2 setFill];
                [bezierPath fill];
                
                
                //// Rectangle Drawing
                UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(8.25, 4.17, 8.4, 1.05) cornerRadius: 0.53];
                [fillColor2 setFill];
                [rectanglePath fill];
                
                
                //// Rectangle 2 Drawing
                UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(8.25, 7.33, 8.4, 1.05) cornerRadius: 0.52];
                [fillColor2 setFill];
                [rectangle2Path fill];
                
                
                //// Rectangle 3 Drawing
                UIBezierPath* rectangle3Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(8.25, 10.48, 8.4, 1.05) cornerRadius: 0.52];
                [fillColor2 setFill];
                [rectangle3Path fill];
                
                
                //// Rectangle 4 Drawing
                UIBezierPath* rectangle4Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(8.25, 13.58, 5.2, 1.05) cornerRadius: 0.52];
                [fillColor2 setFill];
                [rectangle4Path fill];
            }
        }];
    });
    
    return image;
}

@end

#endif
