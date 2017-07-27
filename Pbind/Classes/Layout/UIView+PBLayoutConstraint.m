//
//  UIView+PBLayoutConstraint.h
//  Pbind <https://github.com/wequick/Pbind>
//
//  Created by galen on 17/7/25.
//  Copyright (c) 2015-present, Wequick.net. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "UIView+PBLayoutConstraint.h"

@implementation UIView (PBLayoutConstraint)

- (CGSize)pb_constraintSize {
    CGSize size = self.frame.size;
    if (size.width != 0 && size.height != 0) {
        return size;
    }
    
    if (self.translatesAutoresizingMaskIntoConstraints) {
        return size;
    }
    
    UIView *parent = self.superview;
    CGSize parentSize = parent.frame.size;
    if (parentSize.width == 0) {
        return size;
    }
    
    NSArray *constraints = [self.superview constraints];
    if (constraints.count == 0) {
        return size;
    }
    
    // Calculate width or height by the relation with parent
    for (NSLayoutConstraint *constraint in constraints) {
        if (constraint.firstItem == self && constraint.secondItem == parent) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                if (constraint.secondAttribute == NSLayoutAttributeHeight) {
                    // self.height = parent.height * k + b
                    size.height = parentSize.height * constraint.multiplier + constraint.constant;
                } else if (constraint.secondAttribute == NSLayoutAttributeWidth) {
                    // self.height = parent.width * k + b
                    size.height = parentSize.width * constraint.multiplier + constraint.constant;
                }
            } else if (constraint.firstAttribute == NSLayoutAttributeWidth) {
                if (constraint.secondAttribute == NSLayoutAttributeWidth) {
                    // self.width = parent.width * k + b
                    size.width = parentSize.width * constraint.multiplier + constraint.constant;
                } else if (constraint.secondAttribute == NSLayoutAttributeHeight) {
                    // self.width = parent.height * k + b
                    size.width = parentSize.height * constraint.multiplier + constraint.constant;
                }
            }
        } else if (constraint.firstItem == parent && constraint.secondItem == self) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                if (constraint.secondAttribute == NSLayoutAttributeHeight) {
                    // parent.height = self.height * k + b
                    size.height = (parentSize.height - constraint.constant) / constraint.multiplier;
                } else if (constraint.secondAttribute == NSLayoutAttributeWidth) {
                    // parent.height = self.width * k + b
                    size.width = (parentSize.height - constraint.constant) / constraint.multiplier;
                }
            } else if (constraint.firstAttribute == NSLayoutAttributeWidth) {
                if (constraint.secondAttribute == NSLayoutAttributeWidth) {
                    // parent.width = self.width * k + b
                    size.width = (parentSize.width - constraint.constant) / constraint.multiplier;
                } else if (constraint.secondAttribute == NSLayoutAttributeHeight) {
                    // parent.width = self.height * k + b
                    size.height = (parentSize.width - constraint.constant) / constraint.multiplier;
                }
            }
        }
    }
    
    if (size.height == 0 && size.width == 0) {
        // Calculate width or height by the margins with parent
        UIEdgeInsets insets = UIEdgeInsetsMake(-1, -1, -1, -1);
        UIEdgeInsets parentInsets = UIEdgeInsetsMake(0, 0, parentSize.height, parentSize.width);
        for (NSLayoutConstraint *constraint in constraints) {
            if (constraint.firstItem == self && constraint.secondItem == parent) {
                if (constraint.firstAttribute == NSLayoutAttributeTop) {
                    if (constraint.secondAttribute == NSLayoutAttributeTop) {
                        // self.top = parent.top * k + b
                        insets.top = parentInsets.top * constraint.multiplier + constraint.constant;
                    } else if (constraint.secondAttribute == NSLayoutAttributeBottom) {
                        // self.top = parent.bottom * k + b
                        insets.top = parentInsets.bottom * constraint.multiplier + constraint.constant;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeBottom) {
                    if (constraint.secondAttribute == NSLayoutAttributeTop) {
                        // self.bottom = parent.top * k + b
                        insets.bottom = parentInsets.top * constraint.multiplier + constraint.constant;
                    } else if (constraint.secondAttribute == NSLayoutAttributeBottom) {
                        // self.bottom = parent.bottom * k + b
                        insets.bottom = parentInsets.bottom * constraint.multiplier + constraint.constant;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeLeft) {
                    if (constraint.secondAttribute == NSLayoutAttributeLeft) {
                        // self.left = parent.left * k + b
                        insets.left = parentInsets.left * constraint.multiplier + constraint.constant;
                    } else if (constraint.secondAttribute == NSLayoutAttributeRight) {
                        // self.left = parent.right * k + b
                        insets.bottom = parentInsets.bottom * constraint.multiplier + constraint.constant;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeRight) {
                    if (constraint.secondAttribute == NSLayoutAttributeLeft) {
                        // self.right = parent.left * k + b
                        insets.right = parentInsets.left * constraint.multiplier + constraint.constant;
                    } else if (constraint.secondAttribute == NSLayoutAttributeRight) {
                        // self.right = parent.right * k + b
                        insets.right = parentInsets.right * constraint.multiplier + constraint.constant;
                    }
                }
            } else if (constraint.firstItem == parent && constraint.secondItem == self) {
                if (constraint.firstAttribute == NSLayoutAttributeTop) {
                    if (constraint.secondAttribute == NSLayoutAttributeTop) {
                        // parent.top = self.top * k + b
                        insets.top = (parentInsets.top - constraint.constant) / constraint.multiplier;
                    } else if (constraint.secondAttribute == NSLayoutAttributeBottom) {
                        // parent.top = self.bottom * k + b
                        insets.bottom = (parentInsets.top - constraint.constant) / constraint.multiplier;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeBottom) {
                    if (constraint.secondAttribute == NSLayoutAttributeTop) {
                        // parent.bottom = self.top * k + b
                        insets.top = (parentInsets.bottom - constraint.constant) / constraint.multiplier;
                    } else if (constraint.secondAttribute == NSLayoutAttributeBottom) {
                        // parent.bottom = self.bottom * k + b
                        insets.bottom = (parentInsets.bottom - constraint.constant) / constraint.multiplier;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeLeft) {
                    if (constraint.secondAttribute == NSLayoutAttributeLeft) {
                        // parent.left = self.left * k + b
                        insets.left = (parentInsets.left - constraint.constant) / constraint.multiplier;
                    } else if (constraint.secondAttribute == NSLayoutAttributeRight) {
                        // parent.left = self.right * k + b
                        insets.right = (parentInsets.left - constraint.constant) / constraint.multiplier;
                    }
                } else if (constraint.firstAttribute == NSLayoutAttributeRight) {
                    if (constraint.secondAttribute == NSLayoutAttributeLeft) {
                        // parent.right = self.left * k + b
                        insets.left = (parentInsets.right - constraint.constant) / constraint.multiplier;
                    } else if (constraint.secondAttribute == NSLayoutAttributeRight) {
                        // parent.right = self.right * k + b
                        insets.right = (parentInsets.right - constraint.constant) / constraint.multiplier;
                    }
                }
            }
        }
        
        if (insets.left >= 0 && insets.right >= 0) {
            size.width = insets.right - insets.left;
        } else if (insets.top >= 0 && insets.bottom >= 0) {
            size.height = insets.bottom - insets.top;
        }
    }
    
    if (size.height == 0 && size.width == 0) {
        return size;
    }
    
    // Calculate height or width by the ratio of self
    for (NSLayoutConstraint *constraint in constraints) {
        if (constraint.firstItem == self && constraint.secondItem == self) {
            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                if (constraint.secondAttribute == NSLayoutAttributeWidth) {
                    // self.height = self.width * k + b
                    if (size.height == 0) {
                        size.height = size.width * constraint.multiplier + constraint.constant;
                    } else {
                        size.width = (size.height - constraint.constant) / constraint.multiplier;
                    }
                }
            } else if (constraint.firstAttribute == NSLayoutAttributeWidth) {
                if (constraint.secondAttribute == NSLayoutAttributeHeight) {
                    // self.width = self.height * k + b
                    if (size.width == 0) {
                        size.width = size.height * constraint.multiplier + constraint.constant;
                    } else {
                        size.height = (size.width - constraint.constant) / constraint.multiplier;
                    }
                }
            }
        }
    }
    
    return size;
}

@end
