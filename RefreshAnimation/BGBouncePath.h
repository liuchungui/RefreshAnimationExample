//
//  BGBouncePath.h
//  RefreshAnimation
//
//  Created by 刘春桂 on 16/8/13.
//  Copyright © 2016年 liuchungui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef struct BGRect {
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
    CGFloat height;
    CGFloat width;
    CGFloat x, y, centerX, centerY;
} BGRect;

extern BGRect BGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height);
extern CGFloat bezier3(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat t);
extern CGFloat bezier2(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat t);
extern CGFloat searchBezier(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat p);

@interface BGBouncePath : NSObject
- (instancetype)init;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) UIEdgeInsets contentInsets;
//内容区域
@property (nonatomic, assign) BGRect contentRect;

//小球在Y轴方向哪个地方停留，此处参照是小球的圆心位置
@property (nonatomic, assign) CGFloat stopPosition;

//底部path
- (UIBezierPath *)bottomPathWithTop:(CGFloat)top;

//顶部path
- (UIBezierPath *)topPathWithTop:(CGFloat)top;

- (UIBezierPath *)sinPathWithTop:(CGFloat)top;

- (UIBezierPath *)connetedPathWithTop:(CGFloat)top;

- (UIBezierPath *)dividedPathWithTop:(CGFloat)top;

//到达顶部之后，外圈的路径
- (UIBezierPath *)outerRingPathWithTop:(CGFloat)top;


@end
