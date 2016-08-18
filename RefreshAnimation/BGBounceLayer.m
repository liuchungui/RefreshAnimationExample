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
@end

@implementation BGBounceLayer

- (instancetype)init {
    if(self = [super init]) {
        [self addSublayer:self.bottomLayer];
        [self addSublayer:self.topLayer];
        
        BGBouncePath * path = [[BGBouncePath alloc] init];
        self.bouncePath = path;
    }
    return self;
}

- (void)setContentTop:(CGFloat)contentTop {
    _contentTop = contentTop;
    self.bottomLayer.path = [self.bouncePath bottomPathWithTop:contentTop].CGPath;
    //顶部
    if(contentTop > kBottomLayerTop) {
        self.topLayer.path = nil;
    }
    else {
        self.topLayer.path = [self.bouncePath topPathWithTop:contentTop].CGPath;
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
@end
