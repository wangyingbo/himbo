//
//  Tutorial.swift
//  himbo
//
//  Created by Marcus Kida on 30/11/2014.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

import UIKit

typealias aClosure = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> Void

// fixme: make this a struct
class Tutorial: NSObject {
    
    private var parentView: UIView!
    private var haloView: UIView!
    private var haloLayer: PulsingLayer!
    
    private let kMovementDuration = 1.5
    private let kTapDuration = 0.3
    
    private var menuToggle: (() -> Void)?
    private var finished: (() -> Void)?
    
    private var kHue: CGFloat = 0.0
    private var kSat: CGFloat = 0.0
    private var kBri: CGFloat = 0.0
    
    init(view: UIView) {
        super.init()
        self.parentView = view
        UIColor.himboRed().getHue(&kHue, saturation: &kSat, brightness: &kBri, alpha: nil)
    }
    
    func hasForceTouch () -> Bool {
        if #available(iOS 9, *) {
            if parentView.traitCollection.forceTouchCapability == .Available {
                return true
            }
        }
        return false
    }
    
    func conditionalHue () -> CGFloat {
        if hasForceTouch() {
            return kHue
        }
        return 0.6
    }
    
    func start(closure: aClosure, menuToggle: () -> Void, finished: () -> Void) {
        
        self.menuToggle = menuToggle
        self.finished = finished
        
        haloLayer = PulsingLayer(pulseColor: UIColor(white: 1.0, alpha: 1.0))
        haloLayer.radius = 90.0
        haloLayer.animationDuration = 1
        haloLayer.pulseInterval = 0
        
        haloView = UIView(frame: CGRectMake(65, 65, 50, 50))
        haloLayer.position = CGPointMake(CGRectGetWidth(haloView.frame)/2, CGRectGetHeight(haloView.frame)/2)
        haloView.layer.addSublayer(haloLayer)

        haloView.backgroundColor = UIColor.whiteColor()
        haloView.layer.cornerRadius = CGRectGetHeight(haloView.frame) / 2
        
        parentView.addSubview(haloView)
        
        // down / up
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformMakeTranslation(0, self.parentView.frame.size.height - 130)
            closure(hue: 0.6, saturation: self.kSat, brightness: self.kBri)
            }, completion: { (finished: Bool) -> Void in
                if self.hasForceTouch() {
                    return self.forceTouch(closure)
                }
                self.step1(closure)
        })
    }
    
    // right
    func step1(closure: aClosure) {
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformMakeTranslation(self.parentView.frame.size.width - 130, self.parentView.frame.size.height - 130)
            closure(hue: self.conditionalHue(), saturation: self.kSat, brightness: 0.1)
            }, completion: { (finished: Bool) -> Void in
                self.step2(closure)

        })
    }
    
    // left
    func step2(closure: aClosure) {
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformMakeTranslation(0, self.parentView.frame.size.height - 130)
            closure(hue: self.conditionalHue(), saturation: self.kSat, brightness: self.kBri)
            }, completion: { (finished: Bool) -> Void in
                self.step3(closure)
        })
    }
    
    // right (saturation)
    func step3(closure: aClosure) {
        self.haloView.transform = CGAffineTransformIdentity
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformMakeTranslation(self.parentView.frame.size.width - 130, 0)
            closure(hue: self.conditionalHue(), saturation: 0.1, brightness: self.kBri)
            }, completion: { (finished: Bool) -> Void in
                self.step4(closure)
        })
    }
    
    // left (saturation)
    func step4(closure: aClosure) {
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformIdentity
            closure(hue: self.conditionalHue(), saturation: self.kSat, brightness: self.kBri)
            }, completion: { (finished: Bool) -> Void in
                self.step5(closure)
        })
    }
    
    func forceTouch(closure: aClosure) {
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformIdentity
            closure(hue: self.kHue, saturation: self.kSat, brightness: self.kBri)
            }, completion: { (finished: Bool) -> Void in
                UIView.animateWithDuration(self.kMovementDuration, animations: { () -> Void in
                    self.haloView.transform = CGAffineTransformMakeScale(0.5, 0.5)
                    closure(hue: self.kHue, saturation: self.kSat, brightness: 0.1)
                    }, completion: { (finished: Bool) -> Void in
                        UIView.animateWithDuration(self.kMovementDuration, animations: { () -> Void in
                            self.haloView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                            closure(hue: self.kHue, saturation: self.kSat, brightness: self.kBri)
                            }, completion: { (finished: Bool) -> Void in
                                self.step3(closure)
                        })
            })

        })
    }
    
    // Move to center and do double tap
    func step5(closure: aClosure) {
        self.haloView.center = CGPointMake(CGRectGetWidth(self.parentView.frame) / 2, CGRectGetHeight(self.parentView.frame) / 2)
        UIView.animateWithDuration(kMovementDuration, animations: { () -> Void in
            }, completion: { (finished: Bool) -> Void in
                self.stepTap(closure, done: { (doneClosure: aClosure) -> Void in
                    self.stepTap(doneClosure, done: { (doneClosure: aClosure) -> Void in
                        self.step7(doneClosure)
                    })
                })
        })
    }
    
    // Tap
    func stepTap(closure: aClosure, done: (doneClosure: aClosure) -> Void) {
        UIView.animateWithDuration(kTapDuration, animations: { () -> Void in
            self.haloView.transform = CGAffineTransformMakeScale(2.0, 2.0)
            }, completion: { (finished: Bool) -> Void in
                UIView.animateWithDuration(self.kTapDuration, animations: { () -> Void in
                    self.haloView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    }, completion: { (finished: Bool) -> Void in
                    done(doneClosure: closure)
                })
        })
    }
    
    func step7(closure: aClosure) {
        self.menuToggle?()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.stepTap(closure, done: { (doneClosure) -> Void in
                self.stepTap(closure, done: { (doneClosure) -> Void in
                    self.step8(closure)
                })
            })
        }
    }
    
    func step8(closure: aClosure) {
        self.menuToggle?()
        self.step9(closure)
    }
    
    // Remove haloView, end Tutorial
    func step9(closure: aClosure) {
        self.haloView.removeFromSuperview()
        self.finished?()
    }
}