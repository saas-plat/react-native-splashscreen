//
//  URLImageView.m
//  Copyright (c) 2013 David Hrachovy
//

#import "URLImageView.h"

@implementation URLImageView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        diskCachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"];

        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error];
            }

    return self;
}

- (UIImage *)getImageFromDiskByKey:(NSString *)key{
    NSString *localPath = [diskCachePath stringByAppendingPathComponent:key];
    if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return nil;
    }

    UIImage *image = [[UIImage alloc] initWithContentsOfFile:localPath];
    //return (nil == image) ? nil : image;

    if (nil != image) {
#ifdef DEBUG
        NSLog(@"%@ was hit in disk cache.\n", key);
#endif
        return image;
    }

    return nil;
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    return self;
}

-(void)isImageModified{
    // create a HTTP request to get the file information from the web server
    loadModifiedTime = true;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:imageUrl
      cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
   [request setHTTPMethod:@"HEAD"];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)loadURL:(NSURL*)url placeholderImage:(UIImage *)image{
    UIImage *cachefile = [self getImageFromDiskByKey:@"splash"];
    // 先从cache中加载
    if (nil != cachefile){
       self.image = cachefile;
    }else if (nil != image){
       self.image = image;
    }else {
      UIActivityIndicatorView *activity = (UIActivityIndicatorView*)[self viewWithTag:11];
      if (!activity) {
          activity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
          activity.tag = 11;
          activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
          [self addSubview:activity];
      }
      [activity startAnimating];
    }

    if (url != nil){
      imageUrl = url;
       // IOS9还没有实现NSURLRequestReloadRevalidatingCacheData自己检查
      imageFilePath = [diskCachePath stringByAppendingPathComponent:@"splash"];
      [self isImageModified];
    }
}

- (void)cacheImageToDisk:(NSString *)key image:(UIImage *)image{
    NSString *localPath = [diskCachePath stringByAppendingPathComponent:key];
    NSData *localData = UIImageJPEGRepresentation(image, 1.0f);

    if ([localData length] <= 1) {
        return ;
    }

    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
      [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
    }
    if (!error){
      [[NSFileManager defaultManager] createFileAtPath:localPath contents:localData attributes:nil];
      #ifdef DEBUG
          NSLog(@"%@ was saved to disk %@.\n", key, localPath);
      #endif
    }else{
      #ifdef DEBUG
          NSLog(@"%@ was failed save to disk %@.\n", key, localPath);
      #endif
    }
}

// -(void)padding:(unsigned int)padding
// {
//     self.frame = CGRectMake(self.frame.origin.x + padding, self.frame.origin.y + padding, self.frame.size.width - 2*padding, self.frame.size.height - 2*padding);
// }

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if (loadImageData){
	   [responseData setLength:0];
  }
  if (loadModifiedTime){
     // get the last modified info from the HTTP header
     NSString* httpLastModified = nil;
     NSHTTPURLResponse* httpReponse = (NSHTTPURLResponse *)response;
     if ([httpReponse respondsToSelector:@selector(allHeaderFields)])
     {
         httpLastModified = [[httpReponse allHeaderFields]
                             objectForKey:@"Last-Modified"];
     }

     // setup a date formatter to query the server file's modified date
     // don't ask me about this part of the code ... it works, that's all I know :)
     NSDateFormatter* df = [[NSDateFormatter alloc] init];
     df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
     df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
     df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

     // get the file attributes to retrieve the local file's modified date
     NSFileManager *fileManager = [NSFileManager defaultManager];
     NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:imageFilePath error:nil];

     // test if the server file's date is later than the local file's date
     NSDate* serverFileDate = [df dateFromString:httpLastModified];
     NSDate* localFileDate = [fileAttributes fileModificationDate];

     NSLog(@"Local File Date: %@ Server File Date: %@",localFileDate,serverFileDate);
     //If file doesn't exist, download it
     if(localFileDate==nil){
         isImageModified = YES;
     }else{
       isImageModified = ([localFileDate laterDate:serverFileDate] == serverFileDate);
     }
   }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  if (loadImageData){
  	[responseData appendData:data];
  }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  if (loadImageData){
    UIActivityIndicatorView *activity = (UIActivityIndicatorView*)[self viewWithTag:11];
    if (activity) {
      [activity stopAnimating];
      activity.hidden = YES;
    }
  }
  NSLog(@"conneciton failed");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (loadImageData){
    loadImageData = NO;
    UIImage *img = [[UIImage alloc] initWithData:responseData];
    [self cacheImageToDisk:@"splash" image:img];

    //
    UIActivityIndicatorView *activity = (UIActivityIndicatorView*)[self viewWithTag:11];
    if (activity) {
      [activity stopAnimating];
      activity.hidden = YES;
    }

    // show
    //self.alpha = 0.0;
    self.image = img;
    // [ UIView animateWithDuration:0.5 animations:^{
    //     self.alpha = 1.0;
    // }];
  }
  if(loadModifiedTime){
    loadModifiedTime = NO;
    if (isImageModified){
      loadImageData = YES;
      // 如果图片修改过开始加载数据
      responseData = [[NSMutableData alloc] init];
      NSURLRequest *request = [NSURLRequest requestWithURL:imageUrl
        cachePolicy:NSURLRequestReloadIgnoringCacheData
          timeoutInterval:60.0];
      [NSURLConnection connectionWithRequest:request delegate:self];
    }
  }
}

@end
