//
//  Sever.m
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import "Sever.h"
#import "GCDAsyncSocket.h"

static dispatch_queue_t CGD_manager_SEVER_queue() {
    static dispatch_queue_t _CGD_manager_SEVER_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _CGD_manager_SEVER_queue = dispatch_queue_create("gcd.mine.queue.SeverAkey", DISPATCH_QUEUE_CONCURRENT);
    });
    return _CGD_manager_SEVER_queue;
}
//储存在本地的客户端类型
@interface Client : NSObject
@property(nonatomic, strong)GCDAsyncSocket *scocket;//客户端scocket
@property(nonatomic, strong)NSDate *timeOfSocket;  //更新通讯时间
@property(nonatomic,strong) NSDictionary *currentPacketHead;//客户端报文字典
@property(nonatomic,copy)NSString * clientID;//客户端ID
@end
@implementation Client
@end



@interface Sever () <GCDAsyncSocketDelegate>
@property(nonatomic, strong)GCDAsyncSocket *serve;
@property(nonatomic, strong)NSMutableArray *clientsArray;// 储存客户端
@property(nonatomic, strong)NSThread *checkThread;// 检测心跳
@end

@implementation Sever
+(instancetype)sharSever{
    static Sever * sever;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sever=[[Sever alloc]init];
    });
    return sever;
}
-(instancetype)init{
    if (self = [super init]) {
        self.serve = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:CGD_manager_SEVER_queue()];
        self.checkThread = [[NSThread alloc]initWithTarget:self selector:@selector(checkClient) object:nil];
        [self.checkThread start];
    }
    
    return self;
}
-(NSMutableArray *)clientsArray{
    if (!_clientsArray) {
        _clientsArray = [NSMutableArray array];
    }
    
    return _clientsArray;
}
-(void)SeverGetMSG:(SeverMSG)severAmsg{
    self.severAmsg =severAmsg;
}
//监控端口
-(void)openSerVice{
    
    NSError *error;
    BOOL sucess = [self.serve acceptOnPort:8088 error:&error];
    if (sucess) {
        NSLog(@"%@",[NSString stringWithFormat:@"%@---监听端口成功,等待客户端请求连接...",self.class]);
        if (self.severAmsg) {
            self.severAmsg([NSString stringWithFormat:@"%@---监听端口成功,等待客户端请求连接...",self.class]);
        }
        
    }else {
        NSLog(@"%@",[NSString stringWithFormat:@"%@---端口开启失败...",self.class]);
        if (self.severAmsg) {
            self.severAmsg([NSString stringWithFormat:@"%@---端口开启失败...",self.class]);
        }
    }
}

#pragma mark  GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)serveSock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    if (self.severAmsg) {
        self.severAmsg([NSString stringWithFormat:@"%@---%@ IP: %@: %zd 客户端请求连接...",self.class,newSocket,newSocket.connectedHost,newSocket.connectedPort]);
    }
    NSLog(@"%@---%@ IP: %@: %zd 客户端请求连接...",self.class,newSocket,newSocket.connectedHost,newSocket.connectedPort);
    // 1.将客户端socket保存起来
    Client *client = [[Client alloc]init];
    client.scocket = newSocket;
    client.timeOfSocket = [NSDate date];
    [self.clientsArray addObject:client];
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag  {
    Client * client=[self getClientBysocket:sock];
    if (!client) {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
        return;
    }
    //先读取到当前数据包头部信息
    if (!client.currentPacketHead) {
        client.currentPacketHead = [NSJSONSerialization
                                    JSONObjectWithData:data
                                    options:NSJSONReadingMutableContainers
                                    error:nil];
        if (!client.currentPacketHead) {
            NSLog(@"error：当前数据包的头为空");
            if (self.severAmsg) {
                self.severAmsg(@"error：当前数据包的头为空");
            }
            //断开这个socket连接或者丢弃这个包的数据进行下一个包的读取
            //....
            return;
        }
        NSUInteger packetLength = [client.currentPacketHead[@"size"] integerValue];
        //读到数据包的大小
        [sock readDataToLength:packetLength withTimeout:-1 tag:0];
        return;
    }
    //正式的包处理
    NSUInteger packetLength = [client.currentPacketHead[@"size"] integerValue];
    //说明数据有问题
    if (packetLength <= 0 || data.length != packetLength) {
        NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"error：当前数据包数据大小不正确(%@)",msg);
        if (self.severAmsg) {
            self.severAmsg([NSString stringWithFormat:@"error：当前数据包数据大小不正确(%@)",msg]);
        }
        return;
    }
    //分配ID
    NSString *clientID=client.currentPacketHead[@"CinentID"];
    client.clientID=clientID;
    NSString *targetID=client.currentPacketHead[@"targetID"];
    NSString *type = client.currentPacketHead[@"type"];
    
    
    
    
    /*
     *服务端可以不解析内容，直接转发出去，这里只是想看看打印消息
     **/
    if ([type isEqualToString:@"img"]) {
        NSLog(@"收到图片");
        if (self.severAmsg) {
            self.severAmsg(@"收到图片");
        }
    }else{
        NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        if (self.severAmsg) {
            self.severAmsg([NSString stringWithFormat:@"收到消息:%@",msg]);
        }
        NSLog(@"收到消息:%@",msg);
    }
    
    
    
    
    for (Client *socket in self.clientsArray) {
        //这里找不到目标客户端，可以把数据保存起来，等待目标客户端上线，再转发出去，这里就不做了，感兴趣的同学自己可以试一试
        if ([socket.clientID isEqualToString:targetID]) {
            [self writeDataWithSocket:socket.scocket data:data type:type sourceClient:clientID];
        }
    }
    client.currentPacketHead = nil;
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}
-(Client *)getClientBysocket:(GCDAsyncSocket *)sock{
    for (Client *socket in self.clientsArray) {
        if ([sock isEqual:socket.scocket]) {
            ///更新最新时间
            socket.timeOfSocket = [NSDate date];
            return socket;
        }
    }
    return nil;
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (self.severAmsg) {
        self.severAmsg([NSString stringWithFormat:@"%@---有用户下线...",self.class]);
    }
    NSLog(@"%@",[NSString stringWithFormat:@"%@---有用户下线...",self.class]);
    NSMutableArray *arrayNew = [NSMutableArray array];
    for (Client *socket in self.clientsArray ) {
        if ([socket.scocket isEqual:sock]) {
            continue;
        }
        [arrayNew addObject:socket   ];
    }
    self.clientsArray = arrayNew;
}

-(void)exitWithSocket:(GCDAsyncSocket *)clientSocket{
    //    [self writeDataWithSocket:clientSocket str:@"成功退出\n"];
    //    [self.arrayClient removeObject:clientSocket];
    //
    //    NSLog(@"当前在线用户个数:%ld",self.arrayClient.count);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    if (self.severAmsg) {
        self.severAmsg([NSString stringWithFormat:@"%@---数据发送成功.....",self.class]);
    }
    NSLog(@"%@",[NSString stringWithFormat:@"%@---数据发送成功.....",self.class]);
}

- (void)writeDataWithSocket:(GCDAsyncSocket*)clientSocket data:(NSData *)data type:(NSString *)type sourceClient:(NSString *)sourceClient {
    NSUInteger size = data.length;
    NSMutableDictionary *headDic = [NSMutableDictionary dictionary];
    [headDic setObject:type forKey:@"type"];
    [headDic setObject:sourceClient forKey:@"sourceClient"];
    [headDic setObject:[NSString stringWithFormat:@"%ld",size] forKey:@"size"];
    NSString *jsonStr = [self dictionaryToJson:headDic];
    NSData *lengthData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *mData = [NSMutableData dataWithData:lengthData];
    //分界
    [mData appendData:[GCDAsyncSocket CRLFData]];
    [mData appendData:data];
    //第二个参数，请求超时时间
    [clientSocket writeData:mData withTimeout:-1 tag:0];
    
}
//字典转为Json字符串
- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma checkTimeThread

//开启线程 启动runloop 循环检测客户端socket最新time
- (void)checkClient{
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(repeatCheckClinet) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]run];
    }
}

//移除 超过心跳的 client
- (void)repeatCheckClinet{
    if (self.clientsArray.count == 0) {
        return;
    }
    NSDate *date = [NSDate date];
    NSMutableArray *arrayNew = [NSMutableArray array];
    for (Client *socket in self.clientsArray ) {
        if ([date timeIntervalSinceDate:socket.timeOfSocket]>20||!socket) {
            if (socket) {
                [socket.scocket disconnect];
            }
            
            continue;
        }
        [arrayNew addObject:socket];
    }
    self.clientsArray = arrayNew;
}
@end

