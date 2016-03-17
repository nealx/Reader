//
//	ReaderThumbFetch.m
//	Reader v2.8.6
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2015 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderThumbFetch.h"
#import "ReaderThumbRender.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbView.h"

#import <ImageIO/ImageIO.h>

#import <AFNetworking/AFHTTPSessionManager.h>
#import "CGPDFDocument.h"

@implementation ReaderThumbFetch
{
	ReaderThumbRequest *request;
}

#pragma mark - ReaderThumbFetch instance methods

- (instancetype)initWithRequest:(ReaderThumbRequest *)options
{
	if ((self = [super initWithGUID:options.guid]))
	{
		request = options;
	}

	return self;
}

- (void)cancel
{
	[super cancel]; // Cancel the operation

	request.thumbView.operation = nil; // Break retain loop

	request.thumbView = nil; // Release target thumb view on cancel

	[[ReaderThumbCache sharedInstance] removeNullForKey:request.cacheKey];
}

- (NSURL *)thumbFileURL
{
	NSString *cachePath = [ReaderThumbCache thumbCachePathForGUID:request.guid]; // Thumb cache path

	NSString *fileName = [[NSString alloc] initWithFormat:@"%@.png", request.thumbName]; // Thumb file name

	return [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:fileName]]; // File URL
}

- (NSString *)savePath:(NSString *)filename
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *filePath = [paths objectAtIndex:0];
    filePath = [filePath stringByAppendingPathComponent:@"smph2_mp3"];
    BOOL isDirectory = NO;
    BOOL fileExist = [fm fileExistsAtPath:filePath
                              isDirectory:&isDirectory];
    if (!fileExist
        || !isDirectory) {
        [fm createDirectoryAtPath:filePath
		    withIntermediateDirectories:NO
		                     attributes:nil
		                          error:nil];
    }
    filename = [filename stringByReplacingOccurrencesOfString:@"/"
                                                   withString:@"_"];
    filePath = [filePath stringByAppendingPathComponent:filename];
    return filePath;
}

//!!!!!!guid 控制

- (void)main
{
    /**
     *  1、判断本地是否有png缓存
     2、判断本地是否pdf
     3、下载pdf
     */
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.png",
                          [ReaderThumbCache thumbCachePathForGUID:request.guid],
                          request.thumbName];
    UIImage *img = [UIImage imageWithContentsOfFile:filePath];
    if (img) {
        if (self.isCancelled == NO) {
            ReaderThumbView *thumbView = request.thumbView;
            NSUInteger targetTag = request.targetTag;
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               if (thumbView.targetTag == targetTag)
                               {
                                   [thumbView showImage:img];
                               }
                           });
        }
    } else {
        NSString *fileUrl = [request.fileURL.absoluteString stringByReplacingOccurrencesOfString:@"file:///"
                                                                                      withString:@""];
        NSString *fileName = [NSString stringWithFormat:@"%ld.pdf",
                              (long)request.thumbPage];
        NSArray *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                       NSUserDomainMask,
                                                                       YES);
        NSString *cachePath = [cachesDirectory objectAtIndex:0];
        NSString *pathLocalPdf = nil;
        if ([fileUrl hasSuffix:@".pdf"]) {
            pathLocalPdf = fileUrl;
        } else {
            pathLocalPdf = [NSString stringWithFormat:@"%@/%@/%@",
                            cachePath,
                            [fileUrl lastPathComponent],
                            fileName];
        }
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isDirectory;
        BOOL fileExist = [fm fileExistsAtPath:pathLocalPdf
                                  isDirectory:&isDirectory];
        if (fileExist
            && !isDirectory) {
            }
        else {
            NSString *pathOnlinePdf = [NSString stringWithFormat:@"%@/%@",
                                       fileUrl,
                                       fileName];
            
            NSURL *url = [NSURL URLWithString:pathOnlinePdf];
            NSData *data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:pathLocalPdf
                   atomically:YES];
            NSLog(@"pathOnlinePdf %@ \n pathLocalPdf %@",
                  pathOnlinePdf,
                  pathLocalPdf);
        }
        
        if (self.isCancelled == NO) {            
            NSString *password = request.password;
            
            CGImageRef imageRef = NULL;
            CFURLRef fileURL = (__bridge CFURLRef)[NSURL fileURLWithPath:pathLocalPdf];
            CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateUsingUrl(fileURL,
                                                                        password);
            if (thePDFDocRef != NULL)
            {
                CGPDFPageRef thePDFPageRef = CGPDFDocumentGetPage(thePDFDocRef,
                                                                  1);
                if (thePDFPageRef != NULL)
                {
                    CGFloat thumb_w = request.thumbSize.width;
                    CGFloat thumb_h = request.thumbSize.height;
                    
                    CGRect cropBoxRect = CGPDFPageGetBoxRect(thePDFPageRef,
                                                             kCGPDFCropBox);
                    CGRect mediaBoxRect = CGPDFPageGetBoxRect(thePDFPageRef,
                                                              kCGPDFMediaBox);
                    CGRect effectiveRect = CGRectIntersection(cropBoxRect,
                                                              mediaBoxRect);
                    NSInteger pageRotate = CGPDFPageGetRotationAngle(thePDFPageRef);
                    CGFloat page_w = 0.0f;
                    CGFloat page_h = 0.0f;
                    
                    switch (pageRotate) // Page rotation (in degrees)
                    {
                        default: // Default case
                        case 0: case 180: // 0 and 180 degrees
                        {
                            page_w = effectiveRect.size.width;
                            page_h = effectiveRect.size.height;
                            break;
                        }
                            
                        case 90: case 270: // 90 and 270 degrees
                        {
                            page_h = effectiveRect.size.width;
                            page_w = effectiveRect.size.height;
                            break;
                        }
                    }
                    
                    CGFloat scale_w = (thumb_w / page_w); // Width scale
                    CGFloat scale_h = (thumb_h / page_h); // Height scale
                    
                    CGFloat scale = 0.0f; // Page to target thumb size scale
                    
                    if (page_h > page_w)
                        scale = ((thumb_h > thumb_w) ? scale_w : scale_h); // Portrait
                    else
                        scale = ((thumb_h < thumb_w) ? scale_h : scale_w); // Landscape
                    
                    NSInteger target_w = (page_w * scale); // Integer target thumb width
                    NSInteger target_h = (page_h * scale); // Integer target thumb height
                    
                    if (target_w % 2) target_w--; if (target_h % 2) target_h--; // Even
                    
                    target_w *= request.scale; target_h *= request.scale; // Screen scale
                    
                    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB(); // RGB color space
                    
                    CGBitmapInfo bmi = (kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
                    
                    CGContextRef context = CGBitmapContextCreate(NULL, target_w, target_h, 8, 0, rgb, bmi);
                    
                    if (context != NULL) // Must have a valid custom CGBitmap context to draw into
                    {
                        CGRect thumbRect = CGRectMake(0.0f, 0.0f, target_w, target_h); // Target thumb rect
                        
                        CGContextSetRGBFillColor(context, 1.0f, 1.0f, 1.0f, 1.0f); CGContextFillRect(context, thumbRect); // White fill
                        
                        CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(thePDFPageRef, kCGPDFCropBox, thumbRect, 0, true)); // Fit rect
                        
                        //CGContextSetRenderingIntent(context, kCGRenderingIntentDefault); CGContextSetInterpolationQuality(context, kCGInterpolationDefault);
                        
                        CGContextDrawPDFPage(context, thePDFPageRef); // Render the PDF page into the custom CGBitmap context
                        
                        imageRef = CGBitmapContextCreateImage(context); // Create CGImage from custom CGBitmap context
                        
                        CGContextRelease(context); // Release custom CGBitmap context reference
                    }
                    
                    CGColorSpaceRelease(rgb); // Release device RGB color space reference
                }
                CGPDFDocumentRelease(thePDFDocRef);
            }
            
            if (imageRef != NULL)
            {
                UIImage *image = [UIImage imageWithCGImage:imageRef scale:request.scale orientation:UIImageOrientationUp];
                
                [[ReaderThumbCache sharedInstance] setObject:image forKey:request.cacheKey]; // Update cache
                
                if (self.isCancelled == NO) // Show the image in the target thumb view on the main thread
                {
                    ReaderThumbView *thumbView = request.thumbView; // Target thumb view for image show
                    
                    NSUInteger targetTag = request.targetTag; // Target reference tag for image show
                    
                    dispatch_async(dispatch_get_main_queue(), // Queue image show on main thread
                                   ^{
                                       if (thumbView.targetTag == targetTag) [thumbView showImage:image];
                                   });
                }
                
                CFURLRef thumbURL = (__bridge CFURLRef)[self thumbFileURL]; // Thumb cache path with PNG file name URL
                
                CGImageDestinationRef thumbRef = CGImageDestinationCreateWithURL(thumbURL, (CFStringRef)@"public.png", 1, NULL);
                
                if (thumbRef != NULL) // Write the thumb image file out to the thumb cache directory
                {
                    CGImageDestinationAddImage(thumbRef, imageRef, NULL); // Add the image
                    
                    CGImageDestinationFinalize(thumbRef); // Finalize the image file
                    
                    CFRelease(thumbRef); // Release CGImageDestination reference
                }
                
                CGImageRelease(imageRef); // Release CGImage reference
            }
            else // No image - so remove the placeholder object from the cache
            {
                [[ReaderThumbCache sharedInstance] removeNullForKey:request.cacheKey];
            }
        }
        		ReaderThumbRender *thumbRender = [[ReaderThumbRender alloc] initWithRequest:request]; // Create a thumb render operation
        
        		[thumbRender setQueuePriority:self.queuePriority]; [thumbRender setThreadPriority:(self.threadPriority - 0.1)]; // Priority
        
        		if (self.isCancelled == NO) // We're not cancelled - so update things and add the render operation to the work queue
        		{
        			request.thumbView.operation = thumbRender; // Update the thumb view operation property to the new operation
        
        			[[ReaderThumbQueue sharedInstance] addWorkOperation:thumbRender]; return; // Queue the operation
        		}
        }
    request.thumbView.operation = nil;
    
//    //sb代码：
//	CGImageRef imageRef = NULL; NSURL *thumbURL = [self thumbFileURL];
//
//	CGImageSourceRef loadRef = CGImageSourceCreateWithURL((__bridge CFURLRef)thumbURL, NULL);
//
//	if (loadRef != NULL) // Load the existing thumb image
//	{
//		imageRef = CGImageSourceCreateImageAtIndex(loadRef, 0, NULL); // Load it
//
//		CFRelease(loadRef); // Release CGImageSource reference
//	}
//	else // Existing thumb image not found - so create and queue up a thumb render operation on the work queue
//	{
//		ReaderThumbRender *thumbRender = [[ReaderThumbRender alloc] initWithRequest:request]; // Create a thumb render operation
//
//		[thumbRender setQueuePriority:self.queuePriority]; [thumbRender setThreadPriority:(self.threadPriority - 0.1)]; // Priority
//
//		if (self.isCancelled == NO) // We're not cancelled - so update things and add the render operation to the work queue
//		{
//			request.thumbView.operation = thumbRender; // Update the thumb view operation property to the new operation
//
//			[[ReaderThumbQueue sharedInstance] addWorkOperation:thumbRender]; return; // Queue the operation
//		}
//	}
//
//	if (imageRef != NULL) // Create a UIImage from a CGImage and show it
//	{
//		UIImage *image = [UIImage imageWithCGImage:imageRef scale:request.scale orientation:UIImageOrientationUp];
//
//		CGImageRelease(imageRef); // Release the CGImage reference from the above thumb load code
//
//		UIGraphicsBeginImageContextWithOptions(image.size, YES, request.scale); // Graphics context
//
//		[image drawAtPoint:CGPointZero]; // Decode and draw the image on this background thread
//
//		UIImage *decoded = UIGraphicsGetImageFromCurrentImageContext(); // Newly decoded image
//
//		UIGraphicsEndImageContext(); // Cleanup after the bitmap-based graphics drawing context
//
//		[[ReaderThumbCache sharedInstance] setObject:decoded forKey:request.cacheKey]; // Cache it
//
//		if (self.isCancelled == NO) // Show the image in the target thumb view on the main thread
//		{
//			ReaderThumbView *thumbView = request.thumbView; // Target thumb view for image show
//
//			NSUInteger targetTag = request.targetTag; // Target reference tag for image show
//
//			dispatch_async(dispatch_get_main_queue(), // Queue image show on main thread
//			^{
//				if (thumbView.targetTag == targetTag) [thumbView showImage:decoded];
//			});
//		}
//	}
//
//	request.thumbView.operation = nil; // Break retain loop
}

@end
