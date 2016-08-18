//
//  BGBounceLayer.m
//  RefreshAnimation
//
//  Created by 刘春桂 on 16/8/18.
//  Copyright © 2016年 liuchungui. All rights reserved.
//

#import "BGBounceLayer.h"
#import <UIKit/UIKit.h>
#import "BGBouncePath.h"

static const CGFloat kBottomLayerTop = 164;

@interface BGBounceLayer ()
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
@property (nonatomic, strong) CAShapeLayer *topLayer;
@property (nonatomic, strong) BGBouncePath *bouncePath;
//转圈的layer
@property (nonatomic, strong) CAShapeLayer *ringLayer;
@end

@implementation BGBounceLayer

- (instancetype)init {
    if(self = [super init]) {
        [self addSublayer:self.bottomLayer];
        [self addSublayer:self.topLayer];
        [self addSublayer:self.ringLayer];
        
        BGBouncePath * path = [[BGBouncePath alloc] init];
        self.bouncePath = path;
    }
    return self;
}

- (void)setContentTop:(CGFloat)contentTop {
    _contentTop = contentTop;
    self.bottomLayer.path = [self.bouncePath bottomPathWithTop:contentTop].CGPath;
    
    //上面内容的路径
    if(contentTop > kBottomLayerTop) {
        self.topLayer.path = nil;
    }
    else {
        self.topLayer.path = [self.bouncePath topPathWithTop:contentTop].CGPath;
    }
    
    //形成球时，外面圆环路径
    if(contentTop + self.bouncePath.radius > self.bouncePath.contentRect.height/2.0) {
        self.ringLayer.path = nil;
    }
    else {
        //外部圈path
        self.ringLayer.path = [self.bouncePath outerRingPathWithTop:contentTop].CGPath;
    }
}

- (CAShapeLayer *)bottomLayer {
    if(_bottomLayer == nil) {
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.fillColor = [UIColor blueColor].CGColor;
        shapeLayer.strokeColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 1.0;
        shapeLayer.frame = [UIScreen mainScreen].bounds;
        _bottomLayer = shapeLayer;
    }
    return _bottomLayer;
}

- (CAShapeLayer *)topLayer {
    if(_topLayer == nil) {
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.fillColor = [UIColor blueColor].CGColor;
        shapeLayer.strokeColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 1.0;
        _topLayer = shapeLayer;
    }
    return _topLayer;
}

- (CAShapeLayer *)ringLayer {
    if(_ringLayer == nil) {
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.strokeColor = [UIColor blueColor].CGColor;
        shapeLayer.lineWidth = 2.0;
        _ringLayer = shapeLayer;
    }
    return _ringLayer;
}
@end
