//
//  Sever.h
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SeverMSG)(NSString *msg) ;
@interface Sever : NSObject
@property(nonatomic,copy)SeverMSG severAmsg;
+(instancetype)sharSever;
/*开始监听本地端口**/
-(void)openSerVice;
-(void)SeverGetMSG:(SeverMSG)severAmsg;
@end
