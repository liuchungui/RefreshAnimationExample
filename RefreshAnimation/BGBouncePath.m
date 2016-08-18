//
//  BGBouncePath.m
//  RefreshAnimation
//
//  Created by 刘春桂 on 16/8/13.
//  Copyright © 2016年 liuchungui. All rights reserved.
//

#import "BGBouncePath.h"

//2次贝塞尔曲线公式
CGFloat bezier2(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat t) {
    return p0*(1-t)*(1-t) + 2*t*(1-t)*p1 + t*t*p2;
}

//三次贝塞尔曲线公式
CGFloat bezier3(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat t) {
    return p0*pow(1-t, 3) + 3*p1*t*pow(1-t, 2) + 3*p2*t*t*(1-t) + p3*pow(t, 3);
}

//三次贝塞尔曲线的导数
CGFloat differentialBezier3(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat t) {
    return 3*(-p0+3*p1+3*p2+p3)*t*t + 2*(3*p0-6*p1+3*p2)*t + (-3*p0+3*p1);
}

//通过x或y来求解T的值,使用牛顿法来解 参照https://www.zhihu.com/question/30570430
//需要注意的是方程并不是beizer3，而是f(t) = bezier3(t) - p; （后面还需要减去一个p，求解的是三元一次方程）
CGFloat tForBezier3(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat p3, CGFloat p) {
    //精度
    CGFloat tolerance = 0.01;
    CGFloat t0 = 0.5;
    CGFloat value = bezier3(p0, p1, p2, p3, t0);
    CGFloat t = t0;
    while (ABS(value - p) > tolerance || t < 0 || t > 1) {
        t0 = t0 - (value-p) /  differentialBezier3(p0, p1, p2, p3, t0);
        if(ABS(t - t0) <= 0.000001) {
            t0 = -1;
            break;
        }
        t = t0;
        value = bezier3(p0, p1, p2, p3, t0);
    }
    return t0;
}

typedef struct BGRect {
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
    CGFloat height;
    CGFloat width;
    CGFloat x, y, centerX, centerY;
} BGRect;

BGRect BGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    BGRect info = {};
    info.x = x;
    info.y = y;
    info.width = width;
    info.height = height;
    info.left = x;
    info.right = x + width;
    info.top = y;
    info.bottom = y + height;
    info.centerX = x + width/2.0;
    info.centerY = y + height / 2.0;
    return info;
}

@interface BGBouncePath ()
//内容区域
@property (nonatomic, assign) BGRect contentRect;

//从正弦曲线过渡到连接状态时D点的最佳偏移量
@property (nonatomic, assign) CGFloat optimumOffsetX;
//从正弦曲线过渡到连接状态时，最佳的初始角度
@property (nonatomic, assign) CGFloat optimumOffsetAngle;
//分离时的Top值
@property (nonatomic, assign) CGFloat dividedTop;
//分离时那个点的Y坐标
@property (nonatomic, assign) CGFloat dividedPointY;

@end

@implementation BGBouncePath

- (instancetype)init {
    if(self = [super init]) {
        self.radius = 18;
        self.contentRect = BGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 164);
//        [self solveOptimumOffsetForSinPathTransitToConnectedPath];
        self.optimumOffsetAngle = 112/[UIScreen mainScreen].bounds.size.width;
        [self calculateDividedTopAndPointY];
    }
    return self;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets {
    _contentInsets = contentInsets;
    self.contentRect = BGRectMake(contentInsets.left, contentInsets.top, [UIScreen mainScreen].bounds.size.width - contentInsets.right, 164 - contentInsets.bottom);
}

#pragma mark - 切线方程
//上面圆弧右边终点的切线方程, NT线
- (CGFloat)getNTLinePointXWithY:(CGFloat)y radius:(CGFloat)radius top:(CGPoint)point0 angle:(CGFloat)angle {
    return (y - point0.y - radius + (tan(angle/2.0))*point0.x + radius/cos(angle/2.0)) / tan(angle/2.0);
}

//下面圆弧左边终点的切线方程, L1线
- (CGFloat)getBottomTangentLineWithY:(CGFloat)y radius:(CGFloat)radius top:(CGPoint)point0 angle:(CGFloat)angle {
    CGFloat b = point0.y - radius + radius * cos(angle/2.0) - tan(angle/2.0)*(point0.x - radius * sin(angle/2.0));
    return (y - b) / tan(angle/2.0);
}

#pragma mark 几何方法

//计算正弦曲线所有的点
- (NSArray *)pointsForSinPathWithTop:(CGFloat)top {
    //偏移量
    CGFloat offset = self.contentRect.width * (M_PI - 2) / (2.0 * M_PI);
    
    //点
    CGPoint pointA = CGPointMake(self.contentRect.left, self.contentRect.bottom);
    CGPoint pointB = CGPointMake(self.contentRect.right, self.contentRect.bottom);
    CGPoint pointC = CGPointMake(self.contentRect.centerX, top);
    CGPoint pointD = CGPointMake(pointA.x + offset, pointA.y);
    CGPoint pointE = CGPointMake(pointB.x - offset, pointB.y);
    CGPoint pointM = CGPointMake(pointC.x - offset, pointC.y);
    CGPoint pointN = CGPointMake(pointC.x + offset, pointC.y);
    
    //计算正弦曲线上所有点， 间隔值为1像素
    NSMutableArray *pointArray = [NSMutableArray array];
    CGPoint tmpPoint = CGPointZero;
    for (CGFloat i = self.contentRect.left; i <= self.contentRect.right; i += 1.0) {
        if(i <= pointC.x) {
            CGFloat t = tForBezier3(pointA.x, pointD.x, pointM.x, pointC.x, i);
            CGFloat y = bezier3(pointA.y, pointD.y, pointM.y, pointC.y, t);
            tmpPoint = CGPointMake(i, y);
        }
        else {
            CGFloat t = tForBezier3(pointC.x, pointN.x, pointE.x, pointB.x, i);
            CGFloat y = bezier3(pointC.y, pointN.y, pointE.y, pointB.y, t);
            tmpPoint = CGPointMake(i, y);
        }
        [pointArray addObject:[NSValue valueWithCGPoint:tmpPoint]];
    }
    
    return pointArray;
}

//求解正弦曲线过渡到连接状态时的最佳偏移量
- (void)solveOptimumOffsetForSinPathTransitToConnectedPath {
    CGFloat top = self.contentRect.bottom - 2*self.radius;
    NSArray *sinPathPointArray = [self pointsForSinPathWithTop:top];
    //点
    CGPoint pointA = CGPointMake(self.contentRect.left, self.contentRect.bottom);
    CGPoint pointB = CGPointMake(self.contentRect.right, self.contentRect.bottom);
    CGPoint pointC = CGPointMake(self.contentRect.centerX, top);
    //偏移量
    CGFloat offset = self.contentRect.width * (M_PI - 2) / (2.0 * M_PI);
    
    //正弦曲线的点
    CGPoint pointD = CGPointMake(pointA.x + offset, pointA.y);
    CGPoint pointE = CGPointMake(pointB.x - offset, pointB.y);
    CGPoint pointM = CGPointMake(pointC.x - offset, pointC.y);
    CGPoint pointN = CGPointMake(pointC.x + offset, pointC.y);
    
    //连接时的点
    CGPoint pointH = CGPointMake(pointC.x, pointC.y + self.radius);
    
    //偏差最小值
    CGFloat minDistance = INT_MAX;
    
    for(CGFloat offsetX = (self.contentRect.width * (M_PI - 2) / (2.0 * M_PI)); offsetX < self.contentRect.centerX; offsetX++) {
        for(CGFloat angle = M_PI/180.0; angle < M_PI; angle += M_PI/180.0) {
            CGFloat distance = 0;
            BOOL isBreak = NO;
            for (CGFloat i = self.contentRect.left; i <= self.contentRect.right; i += 1.0) {
                CGFloat y = 0;
                //正弦曲线
                if(i <= pointC.x) {
                    CGFloat t = tForBezier3(pointA.x, pointD.x, pointM.x, pointC.x, i);
                    y = bezier3(pointA.y, pointD.y, pointM.y, pointC.y, t);
                }
                else {
                    CGFloat t = tForBezier3(pointC.x, pointN.x, pointE.x, pointB.x, i);
                    y = bezier3(pointC.y, pointN.y, pointE.y, pointB.y, t);
                }
                
                //连接时葫芦状态
                CGPoint pointD1 = CGPointMake(pointA.x + offsetX, pointA.y);
                CGPoint pointE1 = CGPointMake(pointB.x - offsetX, pointB.y);
                
                CGPoint pointM1 = CGPointMake(0, pointH.y + (self.contentRect.bottom - top - self.radius)/2.0);
                CGPoint pointN1 = CGPointMake(0, pointM1.y);
                
                //通过右边切线， 使用y求x坐标
                pointN1.x = [self getNTLinePointXWithY:pointN1.y radius:self.radius top:pointC angle:angle];
                //pointM1的x坐标与pointN1对称
                pointM1.x = self.contentRect.left + (self.contentRect.width - pointN1.x);
                if(pointN1.x >= self.contentRect.right || pointN.x <= self.contentRect.left) {
                    isBreak = YES;
                    break;
                }
                
                //圆弧的两个终点
                CGPoint pointT1 = CGPointMake(pointH.x-self.radius*sin(angle/2.0), pointH.y - self.radius*cos(angle/2.0));
                CGPoint pointT2 = CGPointMake(pointH.x+self.radius*sin(angle/2.0), pointH.y - self.radius*cos(angle/2.0));
                
                CGFloat y1 = 0;
                if(i < pointT1.x) {
                    CGFloat t = tForBezier3(pointA.x, pointD1.x, pointM1.x, pointT1.x, i);
                    y1 = bezier3(pointA.y, pointD1.y, pointM1.y, pointT1.y, t);
                }
                else if(i < pointT2.x) {
                    y1 = sqrt(self.radius*self.radius - (i-pointH.x)*(i-pointH.x)) + pointH.y;
                }
                else {
                    CGFloat t = tForBezier3(pointT2.x, pointN1.x, pointE1.x, pointB.x, i);
                    y1 = bezier3(pointT2.y, pointN1.y, pointE1.y, pointB.y, t);
                }
                
                //积累距离值
                distance += (y1 - y)*(y1 - y)*(y1 - y)*(y1 - y);
            }
            if(isBreak) {
                continue;
            }
            //记录最小的值
            if(distance < minDistance) {
                minDistance = distance;
                self.optimumOffsetX = offsetX;
                self.optimumOffsetAngle = angle;
                if(minDistance == 0) {
                    return;
                }
            }
        }
    }
}

//计算出分开时的top值和分离的那个坐标Y值
- (void)calculateDividedTopAndPointY {
    //模拟上拉过程
    for(CGFloat top = self.contentRect.bottom - 2*self.radius; top >= -100; top -= 1) {
        //偏移量
        CGFloat offset = [self pointDOffsetXWhenConnectedWithTop:top];
        
        //点
        CGPoint pointA = CGPointMake(self.contentRect.left, self.contentRect.bottom);
//        CGPoint pointB = CGPointMake(self.contentRect.right, self.contentRect.bottom);
        CGPoint pointT = CGPointMake(self.contentRect.centerX, top);
        CGPoint pointD = CGPointMake(pointA.x + offset, pointA.y);
//        CGPoint pointE = CGPointMake(pointB.x - offset, pointB.y);
        //中心点
        CGPoint pointC = CGPointMake(pointT.x, pointT.y + self.radius);
        
        //初始角度
        CGFloat angle = [self circleAngleWhenConnectedWithTop:top];
        
        //圆弧的终点
        CGPoint pointT1 = CGPointMake(pointC.x-self.radius*sin(angle/2.0), pointC.y - self.radius*cos(angle/2.0));
        
        //圆弧的切线
        CGPoint pointM = CGPointMake(0, pointC.y + (self.contentRect.bottom - top - self.radius)/2.0);
        CGPoint pointN = CGPointMake(0, pointM.y);
        
        //通过右边切线， 使用y求x坐标
        pointN.x = [self getNTLinePointXWithY:pointN.y radius:self.radius top:pointT angle:angle];
        //pointM1的x坐标与pointN1对称
        pointM.x = self.contentRect.left + (self.contentRect.width - pointN.x);
        
        //求解在X中心处，是否存在交叉点
        CGFloat t = tForBezier3(pointA.x, pointD.x, pointM.x, pointT1.x, self.contentRect.centerX);
        if(t != -1) {
            self.dividedPointY = bezier3(pointA.y, pointD.y, pointM.y, pointT1.y, t);
            self.dividedTop = top;
            return;
        }
    }
}



#pragma mark 路径方法
- (UIBezierPath *)topPathWithTop:(CGFloat)top {
//    NSLog(@"bottom = %f, top = %f", self.contentRect.bottom, top);
    CGFloat contentHeight = self.contentRect.bottom - top;
    if(contentHeight < 2*self.radius) {
        return [self sinPathWithTop:top];
    }
    else if(contentHeight < self.contentRect.bottom - self.dividedTop) {
        return [self connetedPathWithTop:top];
    }
    else {
        return [self dividedPathWithTop:top];
    }
}
//正弦曲线
- (UIBezierPath *)sinPathWithTop:(CGFloat)top {
    //偏移量
    CGFloat offset = self.contentRect.width * (M_PI - 2) / (2.0 * M_PI);
    
    //点
    CGPoint pointA = CGPointMake(self.contentRect.left, self.contentRect.bottom);
    CGPoint pointB = CGPointMake(self.contentRect.right, self.contentRect.bottom);
    CGPoint pointT = CGPointMake(self.contentRect.centerX, top);
    CGPoint pointD = CGPointMake(pointA.x + offset, pointA.y);
    CGPoint pointE = CGPointMake(pointB.x - offset, pointB.y);
    CGPoint pointM = CGPointMake(pointT.x - offset, pointT.y);
    CGPoint pointN = CGPointMake(pointT.x + offset, pointT.y);
    
    //画线
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:pointA];
    [path addCurveToPoint:pointT controlPoint1:pointD controlPoint2:pointM];
    [path addCurveToPoint:pointB controlPoint1:pointN controlPoint2:pointE];
    [path addLineToPoint:pointA];
    
    return path;
}

- (UIBezierPath *)connetedPathWithTop:(CGFloat)top {
    //偏移量
    CGFloat offset = [self pointDOffsetXWhenConnectedWithTop:top];
    
    //点
    CGPoint pointA = CGPointMake(self.contentRect.left, self.contentRect.bottom);
    CGPoint pointB = CGPointMake(self.contentRect.right, self.contentRect.bottom);
    CGPoint pointT = CGPointMake(self.contentRect.centerX, top);
    CGPoint pointD = CGPointMake(pointA.x + offset, pointA.y);
    CGPoint pointE = CGPointMake(pointB.x - offset, pointB.y);
    //中心点
    CGPoint pointC = CGPointMake(pointT.x, pointT.y + self.radius);
    
    //初始角度
    CGFloat angle = [self circleAngleWhenConnectedWithTop:top];
    
    //圆弧的两个终点
    CGPoint pointT1 = CGPointMake(pointC.x-self.radius*sin(angle/2.0), pointC.y - self.radius*cos(angle/2.0));
//    CGPoint pointT2 = CGPointMake(pointC+self.radius*sin(angle/2.0), pointC - self.radius*cos(angle/2.0));
    
    //圆弧的切线
    CGPoint pointM = CGPointMake(0, pointC.y + (self.contentRect.bottom - top - self.radius)/2.0);
    CGPoint pointN = CGPointMake(0, pointM.y);
    
    //通过右边切线， 使用y求x坐标
    pointN.x = [self getNTLinePointXWithY:pointN.y radius:self.radius top:pointT angle:angle];
    //pointM1的x坐标与pointN1对称
    pointM.x = self.contentRect.left + (self.contentRect.width - pointN.x);
    
    //画水滴效果
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:pointA];
    [path addCurveToPoint:pointT1 controlPoint1:pointD controlPoint2:pointM];
    [path addArcWithCenter:pointC radius:self.radius startAngle:M_PI + M_PI_2 - angle/2.0 endAngle:M_PI * 2 - (M_PI_2 - angle/2.0) clockwise:YES];
    [path addCurveToPoint:pointB controlPoint1:pointN controlPoint2:pointE];
    [path addLineToPoint:pointA];
    
    return path;
}

//分开时的路径
- (UIBezierPath *)dividedPathWithTop:(CGFloat)top {
    //半径
    CGFloat radius = self.radius;
    
    //中心点
    CGPoint pointC = CGPointMake(self.contentRect.centerX, top + radius);
    
    //从离开点开始y坐标的偏移量
    CGFloat offsetY = (self.dividedTop - top) * 4.0;
    
    //底部圆的半径
    CGFloat bottomCircleRadius = offsetY > radius ? radius : offsetY;
    //底部圆的角度
    CGFloat bottomCircleOffsetAngle = 1 / 4.0 * M_PI;
    CGFloat bottomCircleAngle = bottomCircleRadius / radius * (M_PI - bottomCircleOffsetAngle) + bottomCircleOffsetAngle;
    
    //圆底部的店
    CGPoint circleBottomPoint = CGPointMake(self.contentRect.centerX, self.dividedPointY - offsetY);
    //底部圆的中心点
    CGPoint bottomCircleCenter = CGPointMake(circleBottomPoint.x, circleBottomPoint.y - bottomCircleRadius);
    
    //当上面的圆心和下面的圆心重合，则两个半圆重合成一个圆
    if(bottomCircleAngle >= M_PI && pointC.y >= bottomCircleCenter.y) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:pointC radius:radius startAngle:0 endAngle:2*M_PI clockwise:YES];
        return path;
    }
    else {
        //上半圆的两个终点，topPointT1是左终点，topPointT2是右终点
        CGPoint topPointT1 = CGPointMake(pointC.x - radius, pointC.y);
        CGPoint topPointT2 = CGPointMake(pointC.x + radius, pointC.y);
        
        //上面半圆的切线，topPoint1为左切点，topPoint2为右切点
        CGPoint topPoint1 = CGPointMake(pointC.x - radius, pointC.y + radius - offsetY * 0.6);
        CGPoint topPoint2 = CGPointMake(pointC.x + radius, pointC.y + radius - offsetY * 0.6);
        
        //底部圆弧的终点
        CGPoint bottomPointT1 = CGPointMake(bottomCircleCenter.x - bottomCircleRadius * sin(bottomCircleAngle / 2.0), bottomCircleCenter.y + bottomCircleRadius * cos(bottomCircleAngle / 2.0));
        CGPoint bottomPointT2 = CGPointMake(bottomCircleCenter.x + bottomCircleRadius * sin(bottomCircleAngle / 2.0), bottomPointT1.y);
        
        //底部圆弧的切线点
        CGPoint bottomPoint1 = CGPointMake(0, bottomCircleCenter.y + offsetY / 4.0);
        CGPoint bottomPoint2 = CGPointMake(0, bottomPointT1.y);
        //切线，通过y坐标求x坐标
        bottomPoint1.x = [self getBottomTangentLineWithY:bottomPoint1.y radius:bottomCircleRadius top:circleBottomPoint angle:bottomCircleAngle];
        bottomPoint2.x = self.contentRect.right - (bottomPoint1.x - self.contentRect.left);
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:topPointT1];
        [path addArcWithCenter:pointC radius:radius startAngle:M_PI endAngle:M_PI * 2 clockwise:YES];
        [path addCurveToPoint:bottomPointT2 controlPoint1:topPoint2 controlPoint2:bottomPoint2];
        [path addArcWithCenter:bottomCircleCenter radius:bottomCircleRadius startAngle:M_PI_2 - bottomCircleAngle/2.0 endAngle:M_PI_2 + bottomCircleAngle/2.0 clockwise:YES];
        [path addCurveToPoint:topPointT1 controlPoint1:bottomPoint1 controlPoint2:topPoint1];
        return path;
        
    }
}

//到达顶部之后，外圈的路径
- (UIBezierPath *)outerRingPathWithTop:(CGFloat)top {
    CGFloat radius = self.radius + 5;
    CGPoint pointC = CGPointMake(self.contentRect.centerX, top + radius);
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:pointC radius:radius startAngle:0 endAngle:2*M_PI clockwise:YES];
    return path;
}

- (UIBezierPath *)bottomPathWithTop:(CGFloat)top {
    CGFloat scrrenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat scrrenWidth = [UIScreen mainScreen].bounds.size.width;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, self.contentRect.bottom)];
    [path addLineToPoint:CGPointMake(0, scrrenHeight)];
    [path addLineToPoint:CGPointMake(scrrenWidth, scrrenHeight)];
    [path addLineToPoint:CGPointMake(scrrenWidth, self.contentRect.bottom)];
    if(top > self.contentRect.bottom) {
        [path addQuadCurveToPoint:CGPointMake(0, self.contentRect.bottom) controlPoint:CGPointMake(self.contentRect.centerX, top)];
    }
    else {
        [path addLineToPoint:CGPointMake(0, self.contentRect.bottom)];
    }
    return path;
}

#pragma mark - 辅助方法
//连接状态时，pointD的X轴方向偏移量
- (CGFloat)pointDOffsetXWhenConnectedWithTop:(CGFloat)top {
    //    CGFloat offset = (self.contentRect.bottom - top - 2*self.radius) + self.optimumOffsetX;
    CGFloat offset = (self.contentRect.width * (M_PI - 2) / (2.0 * M_PI)) + (self.contentRect.bottom - top)*2.5 - 2.0*self.radius;
    return offset;
}

//连接状态时，上面的圆的角度
- (CGFloat)circleAngleWhenConnectedWithTop:(CGFloat)top {
    CGFloat angle = (self.contentRect.bottom - top - 2*self.radius) / self.radius * (M_PI - self.optimumOffsetAngle)+ self.optimumOffsetAngle;
    if(angle > M_PI) {
        angle = M_PI;
    }
    return angle;
}


@end
