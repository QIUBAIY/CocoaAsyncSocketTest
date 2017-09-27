//
//  ClientA.h
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^clientAMSG)(NSString *msg) ;

@interface ClientA : NSObject
@property(nonatomic,copy)clientAMSG clientAmsg;
+(id)sharClineA;
/*连接服务器**/
-(BOOL)connect;
/*给B发消息**/
-(void)sendMSGToB;
-(void)ClientAGetMSG:(clientAMSG)clientAmsg;
@end
