//
//  ReaderMultiBoard.h
//  Reader
//
//  Created by nealx on 16/3/7.
//
//

#import <UIKit/UIKit.h>

#import "ReaderDocument.h"

@interface ReaderMultiBoard : UIView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *stringUrl;
@property (nonatomic, assign) int pageCount;

- (void)loadResource;
@end
