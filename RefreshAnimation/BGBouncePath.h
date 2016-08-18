//
//  BGBouncePath.h
//  RefreshAnimation
//
//  Created by 刘春桂 on 16/8/13.
//  Copyright © 2016年 liuchungui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern CGFloat bezier3(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat t);
extern CGFloat bezier2(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat t);
extern CGFloat searchBezier(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat p);

@interface BGBouncePath : NSObject
- (instancetype)init;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

//底部path
- (UIBezierPath *)bottomPathWithTop:(CGFloat)top;

//顶部path
- (UIBezierPath *)topPathWithTop:(CGFloat)top;

- (UIBezierPath *)sinPathWithTop:(CGFloat)top;

- (UIBezierPath *)connetedPathWithTop:(CGFloat)top;

- (UIBezierPath *)dividedPathWithTop:(CGFloat)top;


@end
