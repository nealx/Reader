//
//  ReaderMultiCell.m
//  Reader
//
//  Created by nealx on 16/3/7.
//
//

#import "ReaderMultiCell.h"

#import <AFNetworking/AFNetworking.h>
#import "AFReaderAPIClient.h"

@interface ReaderMultiCell ()
@property (nonatomic, copy) NSString *pathBook;
@property (nonatomic, copy) NSString *pathLocalPdf;
@property (nonatomic, copy) NSString *pathOnlinePdf;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@end

@implementation ReaderMultiCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.indicatorView];
    }
    return self;
}

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicatorView.frame = CGRectMake(0, 0, 50, 50);
        _indicatorView.center = CGPointMake(self.bounds.size.width / 2,
                                            self.bounds.size.height / 2);
        _indicatorView.backgroundColor = [UIColor colorWithWhite:0
                                                           alpha:0.3];
        _indicatorView.clipsToBounds = YES;
        _indicatorView.layer.cornerRadius = 10;
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

- (void)refresh
{
    NSString *folderName = [self.stringUrl lastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                   NSUserDomainMask,
                                                                   YES);
    NSString *filePath = [cachesDirectory objectAtIndex:0];
    self.pathBook = [filePath stringByAppendingPathComponent:folderName];
    BOOL directory;
    BOOL isExist = [fm fileExistsAtPath:self.pathBook
                            isDirectory:&directory];
    if (!isExist
        || !directory) {
        NSError *error;
        BOOL succeed = [fm createDirectoryAtPath:self.pathBook
      withIntermediateDirectories:NO
                       attributes:nil
                            error:&error];
    }
    NSString *fileName = [NSString stringWithFormat:@"%d.pdf",
                          self.index];
    self.pathLocalPdf = [self.pathBook stringByAppendingPathComponent:fileName];
    self.pathOnlinePdf = [NSString stringWithFormat:@"%@/%d.pdf",
                          self.stringUrl,
                          self.index];

    isExist = [fm fileExistsAtPath:self.pathLocalPdf
                       isDirectory:&directory];
    if (isExist
        && !directory) {
        [self loadPdf];
    } else {
        if (self.viewContent) {
            [self.viewContent removeFromSuperview];
            self.viewContent = nil;
        }
        [self.indicatorView startAnimating];
        [self loadData];
    }
}

- (void)loadPdf
{
    if (self.viewContent) {
        [self.viewContent removeFromSuperview];
        self.viewContent = nil;
    }
    [self.indicatorView stopAnimating];
    NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:self.pathLocalPdf
                                            isDirectory:NO];
    ReaderContentView *view =
    [[ReaderContentView alloc] initWithFrame:self.bounds
                                     fileURL:fileUrl
                                        page:1
                                    password:nil];
    [self addSubview:view];
    self.viewContent = view;
    //guid
    [view showPageThumb:fileUrl
                   page:1
               password:nil
                   guid:[NSString stringWithFormat:@"%d",
                         self.index]];
}

- (void)loadData
{
    NSURL *url = [NSURL URLWithString:self.pathOnlinePdf];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURL *destinationUrl = [NSURL fileURLWithPath:self.pathLocalPdf];
    AFHTTPSessionManager *session = [AFReaderAPIClient sharedClient];
    
    __weak ReaderMultiCell *weakSelf = self;
    NSURLSessionDownloadTask *downloadTask =
    [session downloadTaskWithRequest:request
                            progress:nil
                         destination: ^NSURL *(NSURL *targetPath, NSURLResponse *response)
     {
         return destinationUrl;
     }                  completionHandler: ^(NSURLResponse *response, NSURL *filePath, NSError *error)
     {
         if (!error
             && [[filePath.absoluteString lastPathComponent] isEqualToString:[weakSelf.pathOnlinePdf lastPathComponent]]) {
             [weakSelf loadPdf];
         }
     }];
    [downloadTask resume];
}

@end
