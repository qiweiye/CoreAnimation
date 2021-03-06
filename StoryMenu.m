//
//  StoryMenu.m
//  JXCoreAnimation
//
//  Created by chenyang on 1/11/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "StoryMenu.h"
#import <QuartzCore/QuartzCore.h>

#define ANIMATIONTIME 1.7f
#define BEN_Y  40.0f
#define END_X  52.0f
#define END_Y  150.0f
#define STORY_MENU_CENTER_POINT CGPointMake(280, 420)

@interface StoryMenu ()

@property (nonatomic, retain) StoryMenuItem *storyMenu;

- (void)addStoryMenuItem;
- (void)startMenuAnimation;
- (void)expandMenuStep1;
- (void)expandMenuStep2;
- (void)closeStoryMenu;
- (CAAnimationGroup *)blowupAnimationAtPoint:(CGPoint)point;
- (CAAnimationGroup *)shrinkAnimationAtPoint:(CGPoint)point;
- (void)appearStoryMenu;

@end

///////////////////////////////////////////////////////////////////

@implementation StoryMenu

@synthesize delegate;
@synthesize expanding = _expanding;
@synthesize storyMenu = _storyMenu;
@synthesize storyMenus = _storyMenus;

- (void)stoptime {
	[_time invalidate];
	_time = nil;
}

- (id)initWithStoryMenus:(NSArray *)aStoryMenus {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 320, 480)])) {
        self.backgroundColor = [UIColor clearColor];
        
		step = 1;
		
        _storyMenus = [aStoryMenus copy];
        
        // add the menu item
        [self addStoryMenuItem];
        
        // add the main item.
        self.storyMenu = [StoryMenuItem initWithImage:[UIImage imageNamed:@"myItem.png"]
									 highlightedImage:nil
									  backgroundImage:[UIImage imageNamed:@"myItem.png"]
						   highlightedBackgroundImage:nil];
        self.storyMenu.delegate = self;
        self.storyMenu.center = STORY_MENU_CENTER_POINT;
        [self addSubview:_storyMenu];
		
    }
    return self;
}

// 添加所有按钮
- (void)addStoryMenuItem {
    int count = [_storyMenus count];
    for (int i = 0; i < count; i ++) {
        StoryMenuItem *item = [_storyMenus objectAtIndex:i];
        item.tag = 1000 + i;
        item.startPoint = CGPointMake(END_X*(i*2+1), BEN_Y);//STORY_MENU_CENTER_POINT;
        item.endPoint = CGPointMake(END_X*(i*2+1), END_Y);
        item.center = item.startPoint;
        item.delegate = self;
        [self addSubview:item];
    }
}

- (void)setStoryMenus:(NSArray *)aStoryMenus {
    if (aStoryMenus != _storyMenus) {
       
        _storyMenus = [aStoryMenus copy];
        

        for (UIView *menu in self.subviews) {
            if (menu.tag >= 1000) {
                [menu removeFromSuperview];
            }
        }
        
        // add the menu buttons
        [self addStoryMenuItem];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // if the menu state is expanding, everywhere can be touch
    // otherwise, only the add button are can be touch
    return _expanding ? YES : CGRectContainsPoint(_storyMenu.frame, point);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.expanding = !self.isExpanding;
}

- (void)storyMenuItemTouchesBegan:(StoryMenuItem *)item {
    if (item == _storyMenu) {
        self.expanding = !self.isExpanding;
    }
}

- (void)storyMenuItemTouchesEnd:(StoryMenuItem *)item {
    // exclude the "add" button
    if (item == _storyMenu) {
        return;
    }
    // blowup the selected menu button
    CAAnimationGroup *blowup = [self blowupAnimationAtPoint:item.center];
    [item.layer addAnimation:blowup forKey:@"blowup"];
    item.center = item.startPoint;
    
    // shrink other menu buttons
    for (int i = 0; i < [_storyMenus count]; i ++) {
        StoryMenuItem *otherItem = [_storyMenus objectAtIndex:i];
		if (otherItem.tag == item.tag) {
            continue;
        }
        CAAnimationGroup *shrink = [self shrinkAnimationAtPoint:otherItem.center];
        [otherItem.layer addAnimation:shrink forKey:@"shrink"];
//		otherItem.center = CGPointMake(END_X*(i*2+1), BEN_Y);
    }
	
	// apear menu buttons
	[self performSelector:@selector(appearStoryMenu) withObject:nil afterDelay:ANIMATIONTIME];
	
    _expanding = NO;
    
	
    [UIView animateWithDuration:0.5f animations:^{
        _storyMenu.transform = CGAffineTransformMakeRotation(0.0f);
    }];
	
    if ([delegate respondsToSelector:@selector(tappedInStoryMenu:didSelectAtIndex:)]) {
        [delegate tappedInStoryMenu:self didSelectAtIndex:item.tag - 1000];
    }
}

- (BOOL)isExpanding {
    return _expanding;
}

- (void)setExpanding:(BOOL)expanding {
    _expanding = expanding;    
    NSLog(@"self.isExpanding %d",self.isExpanding);
	NSLog(@"_expanding %d",_expanding);
	if (!_time) {
		NSLog(@"time nil");
		_flag = self.isExpanding ? 0 : 2;
		step = 1;
		SEL selector = self.isExpanding ? @selector(startMenuAnimation) : @selector(closeStoryMenu);
		[self performSelector:selector];
	}	
}

- (void)startMenuAnimation {
	switch (step) {
		case 1:
			_time = [NSTimer scheduledTimerWithTimeInterval:ANIMATIONTIME 
													 target:self selector:@selector(startMenuAnimation) userInfo:nil repeats:NO];
			[self expandMenuStep1];
			_flag = 0;
			step++;
			break;
		case 2:
			_time = [NSTimer scheduledTimerWithTimeInterval:ANIMATIONTIME 
													 target:self selector:@selector(stoptime) userInfo:nil repeats:NO];
			[self expandMenuStep2];
			_flag = 0;
			step++;
			break;
		default:
			break;
	}
	
	[UIView animateWithDuration:0.2f animations:^{
		_storyMenu.transform = CGAffineTransformMakeRotation(-M_PI_2*(step-1));
	}];
}

- (void)expandMenuStep1 {
	for (; _flag < 3; _flag++) {
		StoryMenuItem *item = (StoryMenuItem *)[self viewWithTag:(1000+_flag)];	
		CAKeyframeAnimation *rotateAnimation;
		switch (_flag) {
			case 0:
				rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.x"];
				rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
										  [NSNumber numberWithFloat:M_PI*2],
										  [NSNumber numberWithFloat:-M_PI*2],
										  [NSNumber numberWithFloat:M_PI*7/4],
										  [NSNumber numberWithFloat:-M_PI*7/4],
										  [NSNumber numberWithFloat:0.0f],nil];
				rotateAnimation.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.2f],
											[NSNumber numberWithFloat:0.5f],
											[NSNumber numberWithFloat:0.7f],
											[NSNumber numberWithFloat:0.8f],
											[NSNumber numberWithFloat:0.9f],
											[NSNumber numberWithFloat:1.0f],nil];
				break;
			case 1:
				rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.y"];
				rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
										  [NSNumber numberWithFloat:M_PI*2],
										  [NSNumber numberWithFloat:-M_PI*2],
										  [NSNumber numberWithFloat:M_PI*7/4],
										  [NSNumber numberWithFloat:-M_PI*7/4],
										  [NSNumber numberWithFloat:0.0f],nil];
				break;
			case 2:
				rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
				rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
										  [NSNumber numberWithFloat:M_PI*2],
										  [NSNumber numberWithFloat:-M_PI*2],
										  [NSNumber numberWithFloat:M_PI*7/4],
										  [NSNumber numberWithFloat:-M_PI*7/4],
										  [NSNumber numberWithFloat:0.0f],nil];
				break;
			default:
				break;
		}
		rotateAnimation.duration = ANIMATIONTIME;
		
		float offsetY = 100.0f;
		CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		positionAnimation.duration = ANIMATIONTIME;
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, item.startPoint.x, item.startPoint.y);
		CGPathAddLineToPoint(path, NULL, item.startPoint.x, END_Y+offsetY);
		CGPathAddLineToPoint(path, NULL, item.endPoint.x, item.endPoint.y);
		positionAnimation.path = path;
		CGPathRelease(path);
		
		CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
		animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, rotateAnimation, nil];
		animationgroup.duration = ANIMATIONTIME;
		animationgroup.fillMode = kCAFillModeForwards;
		animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		[item.layer addAnimation:animationgroup forKey:@"Expand"];
		item.center = item.endPoint;
	}
}

- (void)expandMenuStep2 {	
	for (; _flag < 3; _flag++) {
		StoryMenuItem *item = (StoryMenuItem *)[self viewWithTag:(1000+_flag)];
		float radius = 90.0f;
		float len = 70.0f;
		CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		positionAnimation.duration = ANIMATIONTIME;
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, item.center.x, item.center.y);
		switch (_flag) {
			case 0:
				CGPathAddCurveToPoint(path, nil,
									  item.center.x-len, item.center.y-len,
									  item.center.x+len*3, item.center.y+len*4, 
									  item.center.x+len*4, item.center.y+len*3);
				CGPathAddCurveToPoint(path, nil,
									  item.center.x+len*5, item.center.y+len*2,
									  item.center.x+len, item.center.y-len, 
									  item.center.x, item.center.y);
				break;
			case 1:
				//1
				CGPathAddCurveToPoint(path, nil,
									  item.center.x-radius, item.center.y,
									  item.center.x-radius, item.center.y+radius, 
									  item.center.x, item.center.y+radius);
				//2
				CGPathAddCurveToPoint(path, nil,
									  item.center.x+radius, item.center.y+radius,
									  item.center.x+radius, item.center.y+radius*2, 
									  item.center.x, item.center.y+radius*2);
				//3
				CGPathAddCurveToPoint(path, nil,
									  item.center.x-radius*2, item.center.y+radius*2,
									  item.center.x-radius*2, item.center.y+radius*3, 
									  item.center.x-radius, item.center.y+radius*3);
				//4
				CGPathAddCurveToPoint(path, nil,
									  item.center.x+radius, item.center.y+radius*3,
									  item.center.x+radius, item.center.y+radius*2, 
									  item.center.x, item.center.y+radius*2);
				//5
				CGPathAddCurveToPoint(path, nil,
									  item.center.x-radius, item.center.y+radius*2,
									  item.center.x-radius, item.center.y+radius, 
									  item.center.x, item.center.y+radius);
				//6
				CGPathAddCurveToPoint(path, nil,
									  item.center.x+radius, item.center.y+radius,
									  item.center.x+radius, item.center.y, 
									  item.center.x, item.center.y);
				break;
			case 2:
				CGPathAddCurveToPoint(path, nil,
									  item.center.x+len, item.center.y-len,
									  item.center.x-len*3, item.center.y+len*4, 
									  item.center.x-len*4, item.center.y+len*3);
				CGPathAddCurveToPoint(path, nil,
									  item.center.x-len*5, item.center.y+len*2,
									  item.center.x-len, item.center.y-len, 
									  item.center.x, item.center.y);
				break;
			default:
				break;
		}
		positionAnimation.path = path;
		CGPathRelease(path);
		
		CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
		animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, nil];
		animationgroup.duration = ANIMATIONTIME;
		animationgroup.fillMode = kCAFillModeForwards;
		animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		[item.layer addAnimation:animationgroup forKey:@"Expand"];
    }
}

- (void)closeStoryMenu {
	[UIView animateWithDuration:0.2f animations:^{
		_storyMenu.transform = CGAffineTransformMakeRotation(0.0f);
	}];
	for (; _flag > -1; _flag--) {
		StoryMenuItem *item = (StoryMenuItem *)[self viewWithTag:(1000+_flag)];
		CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
		rotateAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0f],
								  [NSNumber numberWithFloat:M_PI * 4],
								  [NSNumber numberWithFloat:0.0f], nil];
		rotateAnimation.duration = 0.5f;
		rotateAnimation.keyTimes = [NSArray arrayWithObjects:
									[NSNumber numberWithFloat:.0],
									[NSNumber numberWithFloat:.4],
									[NSNumber numberWithFloat:.1], nil];
		
		CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		positionAnimation.duration = 0.5f;
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, item.endPoint.x, item.endPoint.y);
		CGPathAddLineToPoint(path, NULL, item.startPoint.x, item.startPoint.y);
		positionAnimation.path = path;
		CGPathRelease(path);
		
		CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
		animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, rotateAnimation, nil];
		animationgroup.duration = ANIMATIONTIME/2;
		animationgroup.fillMode = kCAFillModeForwards;
		animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		[item.layer addAnimation:animationgroup forKey:@"Close"];
		item.center = item.startPoint;
	}
}

- (CAAnimationGroup *)blowupAnimationAtPoint:(CGPoint)point {
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:point], nil];
    positionAnimation.keyTimes = [NSArray arrayWithObjects: [NSNumber numberWithFloat:.3], nil]; 
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(5, 5, 1)];
	scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.toValue  = [NSNumber numberWithFloat:0.0f];
    
    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = [NSArray arrayWithObjects:positionAnimation, scaleAnimation, opacityAnimation, nil];
    animationgroup.duration = ANIMATIONTIME;
    animationgroup.fillMode = kCAFillModeForwards;
    
    return animationgroup;
}

- (CAAnimationGroup *)shrinkAnimationAtPoint:(CGPoint)point {
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:point], nil];
    positionAnimation.keyTimes = [NSArray arrayWithObjects: [NSNumber numberWithFloat:.3], nil]; 
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.01, .01, 1)];
	scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.toValue  = [NSNumber numberWithFloat:0.0f];
    
    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = [NSArray arrayWithObjects: positionAnimation, scaleAnimation, opacityAnimation, nil];
    animationgroup.duration = ANIMATIONTIME;
    animationgroup.fillMode = kCAFillModeForwards;
    
    return animationgroup;
}

- (void)appearStoryMenu{
//- (CAAnimationGroup *)appearAnimationAtPoint:(CGPoint)point {
	for (int i = 0; i < [_storyMenus count]; i++) {
		StoryMenuItem *item = [_storyMenus objectAtIndex:i];
		item.center = CGPointMake(END_X*(i*2+1), BEN_Y);
		CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
		positionAnimation.values = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:item.startPoint], nil];
		positionAnimation.keyTimes = [NSArray arrayWithObjects: [NSNumber numberWithFloat:.01], nil]; 
		
		CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
		scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.01, .01, 1)];
		scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)];
		scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		
		CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		opacityAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
		opacityAnimation.toValue  = [NSNumber numberWithFloat:1.0f];
		
		CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
		animationgroup.animations = [NSArray arrayWithObjects: positionAnimation, scaleAnimation, opacityAnimation, nil];
		animationgroup.duration = ANIMATIONTIME;
		animationgroup.fillMode = kCAFillModeForwards;
		[item.layer addAnimation:animationgroup forKey:@"appear"];
	}
}

@end
