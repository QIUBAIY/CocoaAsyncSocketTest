//
//  ViewController.m
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import "ViewController.h"
#import "ClientA.h"
#import "Sever.h"
#import "ClientB.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *ClinetATextView;
@property (weak, nonatomic) IBOutlet UITextView *SeverTextView;
@property (weak, nonatomic) IBOutlet UITextView *ClinetBTextView;
//@property(nonatomic,strong)Sever * sever;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.sever=[[Sever alloc]init];
//    [self.sever openSerVice];
       __weak ViewController*weakSelf=self;
    [[Sever sharSever]openSerVice];
    [[Sever sharSever]SeverGetMSG:^(NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.SeverTextView.text=[self.SeverTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",msg]];
        });
    }];
    
    
    
    [[ClientA sharClineA] connect];
    [[ClientA sharClineA] ClientAGetMSG:^(NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
              weakSelf.ClinetATextView.text=[self.ClinetATextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",msg]];
        });
      
    }];
  [[ClientA sharClineA] sendMSGToB];
    
    
    
    [[ClientB sharClineB] connect];
    [[ClientB sharClineB] ClientBGetMSG:^(NSString *msg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.ClinetBTextView.text=[self.ClinetBTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",msg]];
        });
        
    }];
    [[ClientB sharClineB] sendMSGToA];
   
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
