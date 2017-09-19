//
//  AppDelegate.h
//  CocoaAsyncSocketTest
//
//  Created by apple on 2017/9/19.
//  Copyright © 2017年 YY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

