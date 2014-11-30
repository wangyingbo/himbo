//
//  ViewController.swift
//  Colorig
//
//  Created by Marcus Kida on 19/11/2014.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

import UIKit
import AssetsLibrary

typealias computedValues = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)

class ViewController: UIViewController, SphereMenuDelegate {
    
    @IBOutlet weak var flashView: UIView!

    let defaults = NSUserDefaults.standardUserDefaults()
    
    var doubleTap: UITapGestureRecognizer?
    var lastHue: CGFloat = 0.0
    var lastSaturation: CGFloat = 0.0
    var lastBrightness: CGFloat = 1.0
    var lastTouchPoint: CGPoint?
    
    var infoVisible: Bool = false
//    var menuVisible: Bool = false
    
    var theTutorial: Tutorial?
    var sphereMenu: SphereMenu?
    var infoView: InfoView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        doubleTap = UITapGestureRecognizer(target: self, action: "doubleTap:")
        doubleTap!.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap!)

        let images: [UIImage] = [UIImage(named: "icon-close")!, UIImage(named: "icon-facebook")!, UIImage(named: "icon-twitter")!, UIImage(named: "icon-email")!, UIImage(named: "icon-gallery")!]
        sphereMenu = SphereMenu(startPoint: CGPointMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) / 2), submenuImages: images)
        sphereMenu?.delegate = self
        self.view.addSubview(sphereMenu!)
        
        infoView = InfoView(text: "Start\nTutorial", parentView: self.view)
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        if self.defaults.boolForKey("tutorial_shown") {
//            self.updateColor((hue: 0.95, saturation: 0.8, brightness: 0.9))
//            return;
//        }
        
        self.infoVisible = true
        self.infoView?.show({ () -> Void in
            self.defaults.setBool(true, forKey: "tutorial_shown")
            self.infoVisible = false
            self.tutorial()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if lastTouchPoint == nil {
            lastTouchPoint = touches.allObjects.first?.locationInView(self.view)
        }
//        if !infoVisible && menuVisible {
//            toggleMenu()
//        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if !infoVisible {
            updateColor(colorComponents(touches))
            lastTouchPoint = touches.allObjects.first?.locationInView(self.view)
        }
    }
    
    func updateColor(vals: computedValues) {
        self.view.backgroundColor = UIColor(hue: vals.hue, saturation: vals.saturation, brightness: vals.brightness, alpha: 1.0)
    }
    
    private func colorComponents (touches: NSSet) -> computedValues {
        let viewHeight = CGRectGetHeight(self.view.frame)
        let viewWidth = CGRectGetWidth(self.view.frame)
        
        let touch = touches.allObjects.first as UITouch
        let location = touch.locationInView(self.view)

        // Detect significant change in up/down movement (and set hue accordingly)
        if let last = lastTouchPoint {
            if fabs(location.y - last.y) > 5 && fabs(location.y - last.y) < 100 {
                lastHue = ultimateFormula(viewHeight, y: location.y)
            }
        }
        
        if location.y <= viewHeight / 2 {
            lastSaturation = ultimateFormula(viewWidth, y: location.x)
        } else {
            lastBrightness = ultimateFormula(viewWidth, y: location.x)
        }
        
        return (lastHue, lastSaturation, lastBrightness)
    }
    
    private func lastComponents() -> computedValues {
        return (lastHue, lastSaturation, lastBrightness)
    }
    
    private func ultimateFormula(x: CGFloat, y: CGFloat) -> CGFloat {
        return (1 / x) * (x - y)
    }
    
    func doubleTap(gestureRecognizer: UITapGestureRecognizer) {
//        toggleMenu()
        self.flashView { () -> Void in
            if let url = self.temporaryBackground() {
                let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.presentViewController(activity, animated: true, completion: nil)
            }
        }
    }
    
    private func toggleMenu() {
        if let menu = self.sphereMenu {
            menu.toggle()
        }
    }
    
    private func temporaryBackground() -> NSURL? {
        let image = self.renderedImage()
        let path = NSTemporaryDirectory().stringByAppendingPathComponent("himbo.png")
        UIImagePNGRepresentation(image).writeToFile(path, atomically: true)
        return NSURL.fileURLWithPath(path)?
    }
    
    func checkAssetsAuthorization() -> Bool {
        let status = ALAssetsLibrary.authorizationStatus()
        if status == ALAuthorizationStatus.Denied {
            self.view.shake(10, direction: ShakeDirection.Horizontal)
            return false
        }
        return true
    }
    
    private func flashView(closure: () -> Void) {
        self.flashView.alpha = 1.0
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.flashView.alpha = 0.0
            }, completion: { (completed: Bool) -> Void in
                closure()
        })
    }
    
    private func saveToLibrary() {
        self.flashView { () -> Void in
            let image = self.renderedImage()
            ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation.Up) { (path: NSURL!, error: NSError!) -> Void in
                if error != nil {
                    UIAlertView(title: "Error", message: "The Photo could not be saved.", delegate: nil, cancelButtonTitle: "OK").show()
                }
            }
        }
    }
    
    private func renderedImage() -> UIImage {
        let bounds = UIScreen.mainScreen().bounds
        let scale = UIScreen.mainScreen().scale
        let size = CGSizeMake(bounds.width * scale, CGRectGetHeight(bounds) * scale)
        let rect = CGRectMake(0, 0, size.width, size.height)
        return self.imageWithColor(rect, color: self.view.backgroundColor!)
    }
    
    private func imageWithColor(rect: CGRect, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextFillRect(ctx, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func tutorial() {
        theTutorial = Tutorial(view: self.view)
        theTutorial?.start({ (hue, saturation, brightness) -> Void in
            self.updateColor((hue: hue, saturation: saturation, brightness: brightness))
            }, { () -> Void in
                self.toggleMenu()
        })
    }
    
    func sphereDidSelected(index: Int) {
        if index == 4 {
            if !checkAssetsAuthorization() {
                UIAlertView(title: "Error", message: "Please go into your Device's Settings and allow Album Access for himbo. This App will only save the current Wallpaper to your Albums. No Access to this or other Photos is gained.", delegate: nil, cancelButtonTitle: "OK").show()
                return
            }
            self.saveToLibrary();
        }
    }
    
//    func sphereDidOpen() {
//        menuVisible = true
//    }
//    
//    func sphereDidClose() {
//        menuVisible = false
//    }
}

