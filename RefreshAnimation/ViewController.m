//
//  ViewController.m
//  RefreshAnimation
//
//  Created by 刘春桂 on 16/8/13.
//  Copyright © 2016年 liuchungui. All rights reserved.
//

#import "ViewController.h"
#import "BGBouncePath.h"
#import "UIView+Additional.h"

#define kMainScrrenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScrrenHeight [UIScreen mainScreen].bounds.size.height

static const CGFloat kBottomLayerTop = 164;

@interface ViewController ()
@property (nonatomic, strong) BGBouncePath *path;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAShapeLayer *topLayer;
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, assign) CGPoint position;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BGBouncePath * path = [[BGBouncePath alloc] init];
    self.path = path;
    
    //添加定时器
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayEvent:)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.view addGestureRecognizer:pan];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)displayEvent:(CADisplayLink *)displayLink {
    //这里只能使用layer的presentationLayer的position，使用view不行
    CALayer *layer = self.circleView.layer.presentationLayer;
    CGFloat top = layer.position.y-10;
    self.shapeLayer.path = [self.path bottomPathWithTop:top].CGPath;
    
    //顶部
    if(top > kBottomLayerTop) {
        self.topLayer.path = nil;
    }
    else {
        self.topLayer.path = [self.path topPathWithTop:top].CGPath;
    }
}


- (CAShapeLayer *)shapeLayer {
    if(_shapeLayer == nil) {
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.fillColor = [UIColor blueColor].CGColor;
        shapeLayer.strokeColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 1.0;
        shapeLayer.frame = [UIScreen mainScreen].bounds;
        [self.view.layer addSublayer:shapeLayer];
        _shapeLayer = shapeLayer;
    }
    return _shapeLayer;
}

- (CAShapeLayer *)topLayer {
    if(_topLayer == nil) {
        CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.fillColor = [UIColor blueColor].CGColor;
        shapeLayer.strokeColor = [UIColor clearColor].CGColor;
        shapeLayer.lineWidth = 1.0;
        shapeLayer.frame = [UIScreen mainScreen].bounds;
        [self.view.layer addSublayer:shapeLayer];
        _topLayer = shapeLayer;
    }
    return _topLayer;
}


- (UIView *)circleView {
    if(_circleView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake((kMainScrrenWidth-20)/2.0, 164, 20, 20)];
        view.backgroundColor = [UIColor orangeColor];
        view.layer.cornerRadius = 10;
        [self.view addSubview:view];
        _circleView = view;
    }
    return _circleView;
}

#pragma mark -
- (CGPoint)originPoint {
    return CGPointMake(kMainScrrenWidth/2.0, 164);
}

- (void)panAction:(UIPanGestureRecognizer *)pan {
    static CGPoint startPoint;
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            startPoint = [pan locationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint movePoint = [pan locationInView:self.view];
            self.position = CGPointMake(self.position.x + (movePoint.x - startPoint.x), self.position.y + (movePoint.y - startPoint.y));
            self.circleView.top = self.position.y;
            startPoint = movePoint;
        }
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.position = [self originPoint];
            [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:0.25 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.circleView.top = self.position.y;
            } completion:^(BOOL finished) {
            }];
        }
            break;
            
        default:
            break;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
