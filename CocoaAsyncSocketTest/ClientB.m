//
//  ClientB.m
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import "ClientB.h"
#import "GCDAsyncSocket.h"
#define HOST @"127.0.0.1"
#define PORT 8088
static dispatch_queue_t CGD_manager_creation_queue() {
    static dispatch_queue_t _CGD_manager_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _CGD_manager_creation_queue = dispatch_queue_create("gcd.mine.queue.ClinetBkey", DISPATCH_QUEUE_CONCURRENT);
    });
    return _CGD_manager_creation_queue;
}
@interface ClientB () <GCDAsyncSocketDelegate>
{
    NSDictionary *currentPacketHead;
}
@property (nonatomic, strong)NSThread *connectThread;
@property (nonatomic,strong)NSTimer * connectTimer;
@property (nonatomic,strong)GCDAsyncSocket * clinetSocket;
@property (nonatomic,assign)BOOL  isAgain;
@end


@implementation ClientB
+(id)sharClineB{
    static ClientB * clinet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        clinet=[[ClientB alloc]init];
    });
    return clinet;
}
-(void)ClientBGetMSG:(clientBMSG)clientBmsg{
    self.clientBmsg=clientBmsg;
}
-(BOOL)connect{
    self.clinetSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:CGD_manager_creation_queue()];
    NSError * error;
    [self.clinetSocket  connectToHost:HOST onPort:PORT error:&error];
    if (!error) {
        return YES;
    }else{
        return NO;
    }
    
}
-(void)sendMSGToA{
    NSData *data  =  [@"Hello" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data1  = [@"I" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2  = [@"am" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data3  = [@"B," dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data4  = [@"nice to meet you too!" dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:data :@"txt" toClinet:@"CinentA"];
    [self sendData:data1 :@"txt" toClinet:@"CinentA"];
    [self sendData:data2 :@"txt" toClinet:@"CinentA"];
    [self sendData:data3 :@"txt" toClinet:@"CinentA"];
    [self sendData:data4 :@"txt" toClinet:@"CinentA"];
    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"7" ofType:@"jpeg"];
    
    NSData *data5 = [NSData dataWithContentsOfFile:filePath];
    
    [self sendData:data5 :@"img" toClinet:@"CinentA"];
    
}

- (void)sendData:(NSData *)data :(NSString *)type toClinet:(NSString *)target;
{
    NSUInteger size = data.length;
    
    NSMutableDictionary *headDic = [NSMutableDictionary dictionary];
    [headDic setObject:type forKey:@"type"];
    [headDic setObject:@"CinentB" forKey:@"CinentID"];
    [headDic setObject:target forKey:@"targetID"];
    [headDic setObject:[NSString stringWithFormat:@"%ld",size] forKey:@"size"];
    NSString *jsonStr = [self dictionaryToJson:headDic];
    NSData *lengthData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *mData = [NSMutableData dataWithData:lengthData];
    //分界
    [mData appendData:[GCDAsyncSocket CRLFData]];
    
    [mData appendData:data];
    
    
    //第二个参数，请求超时时间
    [self.clinetSocket writeData:mData withTimeout:-1 tag:0];
    
}
//字典转为Json字符串
- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}



- (void)threadStart{
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]run];
    }
}

- (void)heartBeat{
    
    NSData *data  = [@"B心跳" dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data :@"heartB" toClinet:@""];
    //    [self.clinetSocket writeData:[@"A心跳" dataUsingEncoding:NSUTF8StringEncoding ] withTimeout:-1 tag:0];
    
}

- (NSThread*)connectThread{
    if (!_connectThread) {
        _connectThread = [[NSThread alloc]initWithTarget:self selector:@selector(threadStart) object:nil];
    }
    return _connectThread;
}

#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //先读取到当前数据包头部信息
    if (!currentPacketHead) {
        currentPacketHead = [NSJSONSerialization
                             JSONObjectWithData:data
                             options:NSJSONReadingMutableContainers
                             error:nil];
        
        
        if (!currentPacketHead) {
            NSLog(@"error：当前数据包的头为空");
            
            //断开这个socket连接或者丢弃这个包的数据进行下一个包的读取
            
            //....
            
            return;
        }
        
        NSUInteger packetLength = [currentPacketHead[@"size"] integerValue];
        
        //读到数据包的大小
        [sock readDataToLength:packetLength withTimeout:-1 tag:0];
        
        return;
    }
    
    
    //正式的包处理
    NSUInteger packetLength = [currentPacketHead[@"size"] integerValue];
    //说明数据有问题
    if (packetLength <= 0 || data.length != packetLength) {
        NSLog(@"error：当前数据包数据大小不正确");
        return;
    }
    
    NSString *type = currentPacketHead[@"type"];
    NSString * sourceClient=currentPacketHead[@"sourceClient"];
    if ([type isEqualToString:@"img"]) {
        NSLog(@"客户端B成功收到图片--来自于%@",sourceClient);
        if (self.clientBmsg) {
            self.clientBmsg([NSString stringWithFormat:@"客户端B成功收到图片--来自于%@",sourceClient]);
        }

    }else{
        
        NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"客户端B收到消息:%@--来自于%@",msg,sourceClient);
        if (self.clientBmsg) {
            self.clientBmsg([NSString stringWithFormat:@"客户端B收到消息:%@--来自于%@",msg,sourceClient]);
        }
    }
    
    currentPacketHead = nil;
    
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];

  
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self heartBeat];
    NSLog(@"%@",[NSString stringWithFormat:@"%@：连接成功",self.class]);
    if (self.clientBmsg) {
        self.clientBmsg([NSString stringWithFormat:@"%@：连接成功",self.class]);
    }
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    //开启线程发送心跳
    if (!self.isAgain) {
        [self.connectThread start];
    }
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{

    NSLog(@"%@",[NSString stringWithFormat:@"%@：断开连接(Error:%@)",self.class,err]);
    if (self.clientBmsg) {
        self.clientBmsg([NSString stringWithFormat:@"%@：断开连接(Error:%@)",self.class,err]);
    }
    
    if (err) {
        //重连
        self.isAgain=YES;
             [self.clinetSocket connectToHost:HOST onPort:PORT error:nil];
    }else{
        //断开
    }
    
}

@end
