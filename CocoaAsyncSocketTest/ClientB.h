//
//  ClientB.h
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClientB : NSObject
typedef void(^clientBMSG)(NSString *msg) ;
@property(nonatomic,copy)clientBMSG clientBmsg;
+(id)sharClineB;
-(BOOL)connect;
-(void)sendMSGToA;
-(void)ClientBGetMSG:(clientBMSG)clientBmsg;
@end
