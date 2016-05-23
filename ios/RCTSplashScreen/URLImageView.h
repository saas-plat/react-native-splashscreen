//
//  URLImageView.h
//  Copyright (c) 2013 David Hrachovy
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// for asynchronous URL image loading
@interface URLImageView : UIImageView {
    NSMutableData* responseData;
    NSString *diskCachePath;
}

- (void) loadURL:(NSURL*)url placeholderImage:(UIImage *)image;

@end
