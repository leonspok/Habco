//
//  HBEditUserViewController.m
//  Habco
//
//  Created by Игорь Савельев on 08/04/16.
//  Copyright © 2016 Leonspok. All rights reserved.
//

#import "HBEditUserViewController.h"
#import "HBPrototypesManager.h"
#import "HBCPrototype.h"
#import "HBCPrototypeUser.h"

@interface HBEditUserViewController ()<UITextViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) HBCPrototype *prototype;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTextViewPlaceholderLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionHeightConstraint;

@property (nonatomic, strong) UIBarButtonItem *saveItem;

@property (nonatomic, strong) UIView *activeResponder;
@property (nonatomic) CGRect keyboardFrame;
@property (atomic) BOOL observing;

@end

@implementation HBEditUserViewController

- (id)initWithPrototype:(HBCPrototype *)prototype title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.prototype = prototype;
        self.title = title;
        self.saveItem = [[UIBarButtonItem alloc] initWithTitle:saveButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    }
    return self;
}

- (id)initWithUser:(HBCPrototypeUser *)user title:(NSString *)title saveButtonTitle:(NSString *)saveButtonTitle {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        self.user = user;
        self.title = title;
        self.saveItem = [[UIBarButtonItem alloc] initWithTitle:saveButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.saveItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    
    if (self.user) {
        [self.nameTextField setText:self.user.name];
        [self.descriptionTextView setText:self.user.bio];
        [self textFieldEditingChanged:self.descriptionTextView];
    }
    [self.saveItem setEnabled:NO];
    
    [self.scrollView setAlwaysBounceVertical:YES];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    [self.nameTextField setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:self.nameTextField.placeholder attributes:@{NSFontAttributeName: self.nameTextField.font, NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.3f], NSParagraphStyleAttributeName: paragraphStyle}]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self textFieldEditingChanged:nil];
    
    if (!self.observing) {
        self.observing = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.observing) {
        self.observing = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setActiveResponder:(UIView *)activeResponder {
    _activeResponder = activeResponder;
    [self scrollToActiveResponderWithDuration:0.2f];
}

#pragma mark UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.activeResponder) {
        NSDictionary *info = [notification userInfo];
        self.keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        self.keyboardFrame = [self.view convertRect:self.keyboardFrame fromView:[[UIApplication sharedApplication].delegate window]];
        NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self scrollToActiveResponderWithDuration:duration];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardFrame = CGRectZero;
}

#pragma mark UIActions

- (IBAction)cancel:(id)sender {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (IBAction)save:(id)sender {
    if (!self.user) {
        if (!self.prototype) {
            return;
        }
        
        self.user = [[HBPrototypesManager sharedManager] createUserForPrototype:self.prototype];
    }
    self.user.name = self.nameTextField.text;
    self.prototype.prototypeDescription = self.descriptionTextView.text;
    [[HBPrototypesManager sharedManager] saveChangesInUser:self.user];
    
    if (self.saveBlock) {
        self.saveBlock();
    }
}

- (IBAction)backgroundTap:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)textFieldBeginEditing:(id)sender {
    self.activeResponder = sender;
}

- (IBAction)textFieldEditingChanged:(id)sender {
    if (self.nameTextField.text.length > 0) {
        [self.saveItem setEnabled:YES];
    } else {
        [self.saveItem setEnabled:NO];
    }
}

- (void)scrollToActiveResponderWithDuration:(NSTimeInterval)duration {
    if ([self.activeResponder isKindOfClass:UITextField.class]) {
        CGFloat activeFieldYPosition = [self.view convertRect:self.activeResponder.frame fromView:self.activeResponder.superview].origin.y+self.activeResponder.frame.size.height/2.0f;
        if ((activeFieldYPosition < self.keyboardFrame.origin.y-self.activeResponder.frame.size.height/2.0f && activeFieldYPosition > self.activeResponder.frame.size.height/2.0f) || CGRectIsEmpty(self.keyboardFrame)) {
            return;
        }
        CGFloat preferredActiveFieldYPosition = self.keyboardFrame.origin.y/2.0f;
        CGFloat offset = preferredActiveFieldYPosition-activeFieldYPosition;
        CGPoint newOffset = self.scrollView.contentOffset;
        newOffset.y -= offset;
        [UIView animateWithDuration:duration animations:^{
            [self.scrollView setContentOffset:newOffset];
        }];
    } else if ([self.activeResponder isKindOfClass:UITextView.class]) {
        UITextView *textView = (UITextView *)self.activeResponder;
        CGRect caretRect = [self.view convertRect:[textView caretRectForPosition:textView.selectedTextRange.start] fromView:textView];
        CGFloat caretYPosition = caretRect.origin.y+caretRect.size.height;
        if ((caretYPosition < self.keyboardFrame.origin.y-10.0f && caretYPosition > 10.0f) || CGRectIsEmpty(self.keyboardFrame)) {
            return;
        }
        CGFloat preferredCaretYPosition = self.keyboardFrame.origin.y-caretRect.size.height-20.0f;
        CGFloat offset = preferredCaretYPosition-caretYPosition;
        CGPoint newOffset = self.scrollView.contentOffset;
        newOffset.y -= offset;
        [UIView animateWithDuration:duration animations:^{
            [self.scrollView setContentOffset:newOffset];
        }];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.activeResponder == self.nameTextField) {
        [self.descriptionTextView becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self textFieldEditingChanged:textField];
    return YES;
}

#pragma mark UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.activeResponder = textView;
    [self.descriptionTextViewPlaceholderLabel setHidden:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.descriptionTextView.text.length == 0) {
        [self.descriptionTextViewPlaceholderLabel setHidden:NO];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.descriptionHeightConstraint.constant = [self.descriptionTextView sizeThatFits:CGSizeMake(textView.frame.size.width, HUGE_VALF)].height;
    [self.descriptionTextView setNeedsLayout];
    [self.descriptionTextView layoutIfNeeded];
    [self scrollToActiveResponderWithDuration:0.2f];
}

@end
