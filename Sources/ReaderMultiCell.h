//
//  ReaderMultiCell.h
//  Reader
//
//  Created by nealx on 16/3/7.
//
//

#import <UIKit/UIKit.h>

#import "ReaderContentView.h"

@interface ReaderMultiCell : UICollectionViewCell

@property (nonatomic, strong) ReaderContentView *viewContent;
@property (nonatomic, strong) NSString *stringUrl;
@property (nonatomic, assign) int index;

- (void)refresh;

@end
