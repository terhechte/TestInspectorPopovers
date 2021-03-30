//
//  AppDelegate.swift
//  TestPopovers
//
//  Created by terhechte on 30.03.21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if !disableAnimationHack {
            fixMacCatalystPopoverAlwaysAnimates()
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

/// via @steipete
private var didInstallPopoverAnimationFix = false
@discardableResult private func fixMacCatalystPopoverAlwaysAnimates() -> Bool {
    guard didInstallPopoverAnimationFix == false else { return false }
    guard let klass = NSClassFromString("NSPopover") else { return false }
    
    let sel = NSSelectorFromString("animates")
    var origIMP : IMP? = nil
    let newHandler: @convention(block) (AnyObject) -> Bool = { blockSelf in
        return false
    }
    guard let method = class_getInstanceMethod(klass, sel) else { return false }
    origIMP = class_replaceMethod(klass, sel, imp_implementationWithBlock(newHandler), method_getTypeEncoding(method))

    let setSel = NSSelectorFromString("setAnimates:")
    var setOrigIMP : IMP? = nil
    let newSetHandler: @convention(block) (AnyObject, Bool) -> Void = { blockSelf, newValue in
        typealias ClosureType = @convention(c) (AnyObject, Selector, Bool) -> Void
        let callableIMP = unsafeBitCast(setOrigIMP, to: ClosureType.self)
        callableIMP(blockSelf, setSel, false)
    }
    guard let setMethod = class_getInstanceMethod(klass, setSel) else { return false }
    setOrigIMP = class_replaceMethod(klass, setSel, imp_implementationWithBlock(newSetHandler), method_getTypeEncoding(setMethod))

    didInstallPopoverAnimationFix = true
    return origIMP != nil && setOrigIMP != nil
}
