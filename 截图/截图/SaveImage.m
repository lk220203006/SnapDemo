//
//  SaveImage.m
//  截图
//
//  Created by digitalforest on 2018/8/21.
//  Copyright © 2018年 digitalforest. All rights reserved.
//

#import "SaveImage.h"

@implementation SaveImage


- (void)saveImage:(UIImage*)image{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void * _Nullable)(self));
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

@end
