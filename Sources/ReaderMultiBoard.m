//
//  ReaderMultiBoard.m
//  Reader
//
//  Created by nealx on 16/3/7.
//
//

#import "ReaderMultiBoard.h"

#import "ReaderMultiCell.h"
#import "ReaderMainToolbar.h"
#import "ReaderDocument.h"
#import "ThumbsViewController.h"
#import "ReaderMainPagebar.h"

@interface ReaderMultiBoard () <UICollectionViewDelegate,
UICollectionViewDataSource,
ReaderMainToolbarDelegate,
ThumbsViewControllerDelegate,
ReaderMainPagebarDelegate>
{
    float marginBetweenPage;
    BOOL isBarShow;
    UIPrintInteractionController *printInteraction;
    NSInteger currentPage;
}
@property (nonatomic, strong) UICollectionView *ccContent;
@property (nonatomic, strong) ReaderMainToolbar *toolBar;
@property (nonatomic, strong) ReaderMainPagebar *thumbBar;
@property (nonatomic, strong) ReaderDocument *document;
@end

@implementation ReaderMultiBoard

- (void)dealloc
{
    [self.document archiveDocumentProperties];
}

- (void)loadResource
{
    @autoreleasepool {
        marginBetweenPage = 20;
        currentPage = 1;
        
        ReaderDocument *document = [ReaderDocument withDocumentFilePath:self.stringUrl
                                                                         password:nil];
        document.pageCount = @(self.pageCount);
        self.document = document;
        
        [self addSubview:self.ccContent];
        [self addSubview:self.toolBar];
        [self addSubview:self.thumbBar];
        
        if ([self.document.bookmarks containsIndex:currentPage])
        {
            [self.toolBar setBookmarkState:YES];
        }
        else     {
            [self.toolBar setBookmarkState:NO];
        }

        UITapGestureRecognizer *gesTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(gesTap:)];
        [self addGestureRecognizer:gesTap];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(ApplicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
    }
}

- (UICollectionView *)ccContent
{
    if (!_ccContent) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        flowLayout.minimumLineSpacing = marginBetweenPage;
        flowLayout.minimumInteritemSpacing = marginBetweenPage;
        
        CGRect rect = self.bounds;
        rect.size.width *=2;
        _ccContent =
        [[UICollectionView alloc] initWithFrame:rect
		                                collectionViewLayout:flowLayout];
        _ccContent.contentInset = UIEdgeInsetsMake(0,
                                                   0,
                                                   0,
                                                   self.bounds.size.width);
        _ccContent.backgroundColor = [UIColor grayColor];
        _ccContent.showsVerticalScrollIndicator = NO;
        _ccContent.showsHorizontalScrollIndicator = NO;
        _ccContent.dataSource = self;
        _ccContent.delegate = self;
        [_ccContent registerClass:[ReaderMultiCell class] forCellWithReuseIdentifier:@"ReaderMultiCell"];
    }
    return _ccContent;
}

- (ReaderMainToolbar *)toolBar
{
    if (!_toolBar) {
        CGRect toolbarRect = self.bounds;
        toolbarRect.size.height = 44;
        _toolBar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect
                                                   document:self.document];
        [_toolBar setBookmarkState:YES];
        _toolBar.delegate = self;
    }
    return _toolBar;
}

- (ReaderMainPagebar *)thumbBar
{
    if (!_thumbBar) {
        CGRect pagebarRect = self.bounds;
        pagebarRect.size.height = 48;
        pagebarRect.origin.y = (self.bounds.size.height - pagebarRect.size.height);
        _thumbBar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect
                                                    document:self.document];
        _thumbBar.delegate = self;
    }
    return _thumbBar;
}

#pragma mark - delegate dataresource
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //移动 pagingenable效果
    float pageWidth = self.bounds.size.width + marginBetweenPage; // width space
    
    float currentOffset = scrollView.contentOffset.x;
    float targetOffset = targetContentOffset->x;
    float newTargetOffset = 0;
    
    int indexPage = 0;
    if (targetOffset > currentOffset)
    {
        indexPage = ceilf(currentOffset / pageWidth);
    }
    else
    {
        indexPage = floorf(currentOffset / pageWidth);
    }
    newTargetOffset = indexPage * pageWidth;
    
    currentPage = indexPage;
    if ([self.document.bookmarks containsIndex:currentPage])
    {
        [self.toolBar setBookmarkState:YES];
    }
    else     {
        [self.toolBar setBookmarkState:NO];
    }

    if (newTargetOffset < 0)
        newTargetOffset = 0;
    else if (newTargetOffset > scrollView.contentSize.width)
        newTargetOffset = scrollView.contentSize.width;
    
    targetContentOffset->x = currentOffset;
    [scrollView setContentOffset:CGPointMake(newTargetOffset, 0) animated:YES];
    
}

//定义展示的UICollectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.pageCount;
}

//每个UICollectionView展示的内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ReaderMultiCell";
    ReaderMultiCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier
                                              forIndexPath:indexPath];
    cell.stringUrl = self.stringUrl;
    cell.index = (int)indexPath.row+1;
    [cell refresh];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
//定义每个Item 的大小
- (CGSize)  collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.bounds.size;
}

//UICollectionView被选中时调用的方法
- (void)      collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - delegate ReaderMainToolbar
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
             doneButton:(UIButton *)button
{
    [self removeFromSuperview];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
           thumbsButton:(UIButton *)button
{
    if (printInteraction)
    {
        [printInteraction dismissAnimated:NO];
    }
    
    ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:self.document];
    
    thumbsViewController.title = self.title;
    thumbsViewController.delegate = self;
    
    thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    thumbsViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self addSubview:thumbsViewController.view];
//    [self presentViewController:thumbsViewController animated:NO completion:NULL];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
           exportButton:(UIButton *)button
{
    //无作用
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
            printButton:(UIButton *)button
{
    //无作用
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
            emailButton:(UIButton *)button
{
    //无作用
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar
             markButton:(UIButton *)button
{
    if ([self.document.bookmarks containsIndex:currentPage]) // Remove bookmark
    {
        [self.document.bookmarks removeIndex:currentPage];
        [self.toolBar setBookmarkState:NO];
    }
    else // Add the bookmarked page number to the bookmark index set
    {
        [self.document.bookmarks addIndex:currentPage];
        [self.toolBar setBookmarkState:YES];
    }
}

- (void)gotoPgae:(NSInteger )page
{
    float pageWidth = self.bounds.size.width + marginBetweenPage; // width space
    CGPoint offset = CGPointMake(pageWidth*(page-1),
                                 0);
    [self.ccContent setContentOffset:offset
                            animated:YES];
    
    if ([self.document.bookmarks containsIndex:page])
    {
        [self.toolBar setBookmarkState:YES];
    }
    else
    {
        [self.toolBar setBookmarkState:NO];
    }
}

#pragma mark  - delegate ThumbsViewController
- (void)thumbsViewController:(ThumbsViewController *)viewController
                    gotoPage:(NSInteger)page
{
    [self gotoPgae:page];
}

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
    [viewController.view removeFromSuperview];
}

#pragma mark - delegate ReaderMainPagebar
- (void)pagebar:(ReaderMainPagebar *)pagebar
       gotoPage:(NSInteger)page
{
    [self gotoPgae:page];
}

#pragma mark - notification
- (void)ApplicationDidEnterBackground:(NSNotification *)notification
{
    [self.document archiveDocumentProperties];
}

#pragma mark - action
- (void)gesTap:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        float tapMargin = 80;
        CGRect viewRect = recognizer.view.bounds;
        
        CGPoint point = [recognizer locationInView:recognizer.view];
        
        CGRect areaRect = CGRectInset(viewRect,
                                      tapMargin,
                                      0);
        
        if (CGRectContainsPoint(areaRect, point) == true)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentPage
                                                        inSection:0];
            ReaderMultiCell *cell =
            (ReaderMultiCell *)[self.ccContent cellForItemAtIndexPath:indexPath];
            ReaderContentView *targetView = cell.viewContent;
            id target = [targetView processSingleTap:(UITapGestureRecognizer *)recognizer];
            if (target)
            {
                if ([target isKindOfClass:[NSURL class]]) // Open a URL
                {
                    NSURL *url = (NSURL *)target; // Cast to a NSURL object
                    
                    if (url.scheme == nil) // Handle a missing URL scheme
                    {
                        NSString *www = url.absoluteString; // Get URL string
                        
                        if ([www hasPrefix:@"www"] == YES) // Check for 'www' prefix
                        {
                            NSString *http = [[NSString alloc] initWithFormat:@"http://%@", www];
                            
                            url = [NSURL URLWithString:http]; // Proper http-based URL
                        }
                    }
                    
                    if ([[UIApplication sharedApplication] openURL:url] == NO)
                    {
#ifdef DEBUG
                        NSLog(@"%s '%@'", __FUNCTION__, url); // Bad or unknown URL
#endif
                    }
                }
                else // Not a URL, so check for another possible object type
                {
                    if ([target isKindOfClass:[NSNumber class]]) // Goto page
                    {
                        NSInteger number = [target integerValue]; // Number
                        
                        float pageWidth = self.bounds.size.width + marginBetweenPage; // width space
                        CGPoint offset = CGPointMake(pageWidth*(number-1),
                                                     0);
                        [self.ccContent setContentOffset:offset
                                                animated:YES];
                    }
                }
            }
            else
            {
                isBarShow = !isBarShow;
                if (isBarShow) {
                    self.toolBar.hidden = NO;
                } else {
                    self.toolBar.hidden = YES;
                }
            }
            return;
        }
        
        CGRect nextPageRect = viewRect;
        nextPageRect.size.width = tapMargin;
        nextPageRect.origin.x = (viewRect.size.width - tapMargin);
        
        if (CGRectContainsPoint(nextPageRect, point)) // page++
        {
            [self incrementPageNumber];
            return;
        }
        
        CGRect prevPageRect = viewRect;
        prevPageRect.size.width = tapMargin;
        
        if (CGRectContainsPoint(prevPageRect, point)) // page--
        {
            [self decrementPageNumber];
            return;
        }
    }

}

- (void)decrementPageNumber
{
    NSInteger pageAim = currentPage-1;
    if (pageAim>=1) {
        currentPage = pageAim;
        CGPoint contentOffset = CGPointMake((pageAim-1)*(self.bounds.size.width + marginBetweenPage),
                                            0);
        [self.ccContent setContentOffset:contentOffset
                                animated:YES];
    }
}

- (void)incrementPageNumber
{
    NSInteger pageAim = currentPage+1;
    if (pageAim<=self.pageCount) {
        currentPage = pageAim;
        CGPoint contentOffset = CGPointMake((pageAim-1)*(self.bounds.size.width + marginBetweenPage),
                                            0);
        [self.ccContent setContentOffset:contentOffset
                                animated:YES];
    }
}


@end
