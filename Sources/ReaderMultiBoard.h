//
//  ReaderMultiBoard.h
//  Reader
//
//  Created by nealx on 16/3/7.
//
//

#import <UIKit/UIKit.h>

#import "ReaderDocument.h"

@protocol ReaderMultiBoardDelegate <NSObject>
- (void)ReaderMultiBoardWillRemove:(id)sender;
@end

@interface ReaderMultiBoard : UIView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *stringUrl;
@property (nonatomic, assign) int pageCount;
@property (nonatomic, assign) id <ReaderMultiBoardDelegate> delegate;
- (void)loadResource;
@end
