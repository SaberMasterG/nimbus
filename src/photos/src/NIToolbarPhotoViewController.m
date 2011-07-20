//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NIToolbarPhotoViewController.h"

#import "NIPhotoAlbumScrollView.h"


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NIToolbarPhotoViewController

@synthesize showPhotoAlbumBeneathToolbar = _showPhotoAlbumBeneathToolbar;
@synthesize hidesChromeWhenScrolling = _hidesChromeWhenScrolling;
@synthesize chromeCanBeHidden = _chromeCanBeHidden;
@synthesize animateMovingToNextAndPreviousPhotos = _animateMovingToNextAndPreviousPhotos;
@synthesize toolbar = _toolbar;
@synthesize photoAlbumView = _photoAlbumView;
@synthesize nextButton = _nextButton;
@synthesize previousButton = _previousButton;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    // Default Configuration Settings
    self.showPhotoAlbumBeneathToolbar = YES;
    self.hidesChromeWhenScrolling = YES;
    self.chromeCanBeHidden = YES;
    self.animateMovingToNextAndPreviousPhotos = NO;

    // Allow the photos to display beneath the status bar.
    self.wantsFullScreenLayout = YES;
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addTapGestureToView {
  if ([self isViewLoaded]
      && nil != NIUITapGestureRecognizerClass()
      && [self.photoAlbumView respondsToSelector:@selector(addGestureRecognizer:)]) {
    if (nil == _tapGesture) {
      _tapGesture =
      [[NIUITapGestureRecognizerClass() alloc] initWithTarget: self
                                                       action: @selector(didTap)];

      [self.photoAlbumView addGestureRecognizer:_tapGesture];
    }
  }

  [_tapGesture setEnabled:YES];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView {
  [super loadView];

  CGRect bounds = self.view.bounds;

  // Toolbar Setup

  CGFloat toolbarHeight = NIToolbarHeightForOrientation(NIInterfaceOrientation());
  CGRect toolbarFrame = CGRectMake(0, bounds.size.height - toolbarHeight,
                                   bounds.size.width, toolbarHeight);

  _toolbar = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
  _toolbar.barStyle = UIBarStyleBlack;
  _toolbar.translucent = self.showPhotoAlbumBeneathToolbar;
  _toolbar.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                               | UIViewAutoresizingFlexibleTopMargin);

  UIImage* nextIcon = [UIImage imageWithContentsOfFile:
                       NIPathForBundleResource(nil, @"NimbusPhotos.bundle/gfx/next.png")];
  UIImage* previousIcon = [UIImage imageWithContentsOfFile:
                           NIPathForBundleResource(nil, @"NimbusPhotos.bundle/gfx/previous.png")];

  // We weren't able to find the next or previous icons in your application's resources.
  // Ensure that you've dragged the NimbusPhotos.bundle from src/photos/resources into your
  // application with the "Create Folder References" option selected. You can verify that
  // you've done this correctly by expanding the NimbusPhotos.bundle file in your project
  // and verifying that the 'gfx' directory is blue. Also verify that the bundle is being
  // copied in the Copy Bundle Resources phase.
  NIDASSERT(nil != nextIcon);
  NIDASSERT(nil != previousIcon);

  _nextButton = [[UIBarButtonItem alloc] initWithImage: nextIcon
                                                 style: UIBarButtonItemStylePlain
                                                target: self
                                                action: @selector(didTapNextButton)];

  _previousButton = [[UIBarButtonItem alloc] initWithImage: previousIcon
                                                     style: UIBarButtonItemStylePlain
                                                    target: self
                                                    action: @selector(didTapPreviousButton)];

  UIBarItem* flexibleSpace =
  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                 target: nil
                                                 action: nil] autorelease];

  _toolbar.items = [NSArray arrayWithObjects:
                    flexibleSpace, _previousButton,
                    flexibleSpace, _nextButton,
                    flexibleSpace,
                    nil];


  // Photo Album View Setup

  CGRect photoAlbumFrame = bounds;
  if (!self.showPhotoAlbumBeneathToolbar) {
    photoAlbumFrame = NIRectContract(bounds, 0, toolbarHeight);
  }
  _photoAlbumView = [[[NIPhotoAlbumScrollView alloc] initWithFrame:photoAlbumFrame] autorelease];
  _photoAlbumView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                      | UIViewAutoresizingFlexibleHeight);
  _photoAlbumView.delegate = self;

  [self.view addSubview:_photoAlbumView];
  [self.view addSubview:_toolbar];


  if (self.hidesChromeWhenScrolling) {
    [self addTapGestureToView];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload {
  // We don't have to release the views here because self.view is the only thing retaining them.
  _photoAlbumView = nil;
  _toolbar = nil;

  NI_RELEASE_SAFELY(_nextButton);
  NI_RELEASE_SAFELY(_previousButton);

  NI_RELEASE_SAFELY(_tapGesture);

  [super viewDidUnload];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackTranslucent
                                              animated: animated];

  UINavigationBar* navBar = self.navigationController.navigationBar;
  navBar.barStyle = UIBarStyleBlack;
  navBar.translucent = YES;

  _previousButton.enabled = [self.photoAlbumView hasPrevious];
  _nextButton.enabled = [self.photoAlbumView hasNext];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return NIIsSupportedOrientation(toInterfaceOrientation);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                duration: (NSTimeInterval)duration {
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

  [self.photoAlbumView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                         duration: (NSTimeInterval)duration {
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                          duration:duration];

  CGRect toolbarFrame = self.toolbar.frame;
  toolbarFrame.size.height = NIToolbarHeightForOrientation(toInterfaceOrientation);
  toolbarFrame.origin.y = self.view.bounds.size.height - toolbarFrame.size.height;
  self.toolbar.frame = toolbarFrame;

  if (!self.showPhotoAlbumBeneathToolbar) {
    CGRect photoAlbumFrame = self.photoAlbumView.frame;
    photoAlbumFrame.size.height = self.view.bounds.size.height - toolbarFrame.size.height;
    self.photoAlbumView.frame = photoAlbumFrame;
  }

  [self.photoAlbumView willAnimateRotationToInterfaceOrientation: toInterfaceOrientation
                                                        duration: duration];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didHideChrome {
  _isAnimatingChrome = NO;
  self.toolbar.hidden = YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didShowChrome {
  _isAnimatingChrome = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setChromeVisibility:(BOOL)isVisible animated:(BOOL)animated {
  if (_isAnimatingChrome
      || (!isVisible && self.toolbar.hidden)
      || (isVisible && !self.toolbar.hidden)
      || !self.chromeCanBeHidden) {
    // Nothing to do here.
    return;
  }

  CGRect toolbarFrame = self.toolbar.frame;
  CGRect bounds = self.view.bounds;

  // Reset the toolbar's initial position.
  if (!isVisible) {
    toolbarFrame.origin.y = bounds.size.height - toolbarFrame.size.height;

  } else {
    // Ensure that the toolbar is visible through the animation.
    self.toolbar.hidden = NO;

    toolbarFrame.origin.y = bounds.size.height;
  }
  self.toolbar.frame = toolbarFrame;

  // Show/hide the system chrome.
  if ([[UIApplication sharedApplication] respondsToSelector:
       @selector(setStatusBarHidden:withAnimation:)]) {
    // On 3.2 and higher we can slide the status bar out.
    [[UIApplication sharedApplication] setStatusBarHidden: !isVisible
                                            withAnimation: (animated
                                                            ? UIStatusBarAnimationSlide
                                                            : UIStatusBarAnimationNone)];

  } else {
    // On 3.0 devices we use the boring fade animation.
    [[UIApplication sharedApplication] setStatusBarHidden: !isVisible
                                                 animated: animated];
  }

  // Place the toolbar at its final location.
  if (isVisible) {
    // Slide up.
    toolbarFrame.origin.y = bounds.size.height - toolbarFrame.size.height;

  } else {
    // Slide down.
    toolbarFrame.origin.y = bounds.size.height;
  }

  // If there is a navigation bar, place it at its final location.
  CGRect navigationBarFrame = CGRectZero;
  if (nil != self.navigationController.navigationBar) {
    navigationBarFrame = self.navigationController.navigationBar.frame;
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat statusBarHeight = MIN(statusBarFrame.size.width, statusBarFrame.size.height);

    if (isVisible) {
      navigationBarFrame.origin.y = statusBarHeight;

    } else {
      navigationBarFrame.origin.y = 0;
    }
  }

  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:(isVisible
                                         ? @selector(didShowChrome)
                                         : @selector(didHideChrome))];

    // Ensure that the animation matches the status bar's.
    [UIView setAnimationDuration:NIStatusBarAnimationDuration()];
    [UIView setAnimationCurve:NIStatusBarAnimationCurve()];
  }

  self.toolbar.frame = toolbarFrame;
  if (nil != self.navigationController.navigationBar) {
    self.navigationController.navigationBar.frame = navigationBarFrame;
    self.navigationController.navigationBar.alpha = (isVisible ? 1 : 0);
  }

  if (animated) {
    _isAnimatingChrome = YES;
    [UIView commitAnimations];

  } else if (!isVisible) {
    [self didHideChrome];

  } else if (isVisible) {
    [self didShowChrome];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)toggleChromeVisibility {
  [self setChromeVisibility:(self.toolbar.hidden || _isAnimatingChrome) animated:YES];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIGestureRecognizer


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didTap {
  SEL selector = @selector(toggleChromeVisibility);
  if (self.photoAlbumView.zoomingIsEnabled) {
    // Cancel any previous delayed performs so that we don't stack them.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];

    // We need to delay taking action on the first tap in case a second tap comes in, causing
    // a double-tap gesture to be recognized and the photo to be zoomed.
    [self performSelector: selector
               withObject: nil
               afterDelay: 0.3];

  } else {
    // When zooming is disabled, double-tap-to-zoom is also disabled so we don't have to
    // be as careful; just toggle the chrome immediately.
    [self toggleChromeVisibility];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NIPhotoAlbumScrollViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)photoAlbumScrollViewDidScroll:(NIPhotoAlbumScrollView *)photoAlbumScrollView {
  if (self.hidesChromeWhenScrolling) {
    [self setChromeVisibility:NO animated:YES];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)photoAlbumScrollView: (NIPhotoAlbumScrollView *)photoAlbumScrollView
                   didZoomIn: (BOOL)didZoomIn {
  // This delegate method is called after a double-tap gesture, so cancel any pending
  // single-tap gestures.
  [NSObject cancelPreviousPerformRequestsWithTarget: self
                                           selector: @selector(toggleChromeVisibility)
                                             object: nil];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)photoAlbumScrollViewDidChangePages:(NIPhotoAlbumScrollView *)photoAlbumScrollView {
  _previousButton.enabled = [photoAlbumScrollView hasPrevious];
  _nextButton.enabled = [photoAlbumScrollView hasNext];

  self.title = [NSString stringWithFormat:@"%d of %d",
                (photoAlbumScrollView.currentCenterPhotoIndex + 1),
                photoAlbumScrollView.numberOfPhotos];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didTapNextButton {
  [self.photoAlbumView moveToNextAnimated:self.animateMovingToNextAndPreviousPhotos];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didTapPreviousButton {
  [self.photoAlbumView moveToPreviousAnimated:self.animateMovingToNextAndPreviousPhotos];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setShowPhotoAlbumBeneathToolbar:(BOOL)enabled {
  _showPhotoAlbumBeneathToolbar = enabled;

  self.toolbar.translucent = enabled;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setHidesChromeWhenScrolling:(BOOL)hidesToolbar {
  _hidesChromeWhenScrolling = hidesToolbar;

  if (hidesToolbar) {
    [self addTapGestureToView];

  } else {
    [_tapGesture setEnabled:NO];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setChromeCanBeHidden:(BOOL)canBeHidden {
  if (nil == NIUITapGestureRecognizerClass()) {
    // Don't allow the chrome to be hidden if we can't tap to make it visible again.
    canBeHidden = NO;
  }

  _chromeCanBeHidden = canBeHidden;

  if (!canBeHidden) {
    self.hidesChromeWhenScrolling = NO;

    // Ensure that the toolbar is visible.
    self.toolbar.hidden = NO;

    CGRect toolbarFrame = self.toolbar.frame;
    CGRect bounds = self.view.bounds;
    toolbarFrame.origin.y = bounds.size.height - toolbarFrame.size.height;
    self.toolbar.frame = toolbarFrame;
  }
}


@end