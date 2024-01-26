//
//  MainNavigationController.swift
//  Toy
//
//  Created by Maxim Kitaygora on 1/21/16.
//  Copyright © 2016 Signe Networks. All rights reserved.
//

import Foundation
import UIKit


//-----------------------------------------------
// MARK MainTabBarController
class MainTabBarController: UITabBarController, UIPageViewControllerDelegate {    

    var recentsTabBarItem: UITabBarItem = UITabBarItem()
    
    //--------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        centralController.toyTabBarController = self
    }
    
    //-----------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        diasbleResentsTabBarItem()
        if centralController.toyStatus == ToyStatus.connected {
            if centralController.cloundService.isCloudSessionEnabled() == true && centralController.last10IsFetching == false
                && centralController.last10ReceivedButNotUpdated == false {
                if recents.isEmpty == false && recents[0].text.isEmpty == false {
                    self.enableResentsTabBarItem()
                } else {
                    centralController.getLast10Played()
                }
            }
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        if centralController.cloundService.isCloudSessionEnabled() == false {
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            navigationItem.leftBarButtonItem?.isEnabled = true
        }
        
        
    }
    
    //-----------------------------------------
    func diasbleResentsTabBarItem(){
        if let arrayOfTabBarItems = self.tabBar.items{
            recentsTabBarItem = arrayOfTabBarItems[1]
            recentsTabBarItem.isEnabled = false
            
        }
    }

    //-----------------------------------------
    func enableResentsTabBarItem(){
        if let arrayOfTabBarItems = self.tabBar.items {
            recentsTabBarItem = arrayOfTabBarItems[1] 
            recentsTabBarItem.isEnabled = true
        }
    }
}


//-----------------------------------------------
// MARK MainNavigationController
class MainNavigationController: UINavigationController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //-----------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    //-----------------------------------------
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralController.myToyViewController?.resetMainScreen()
    }

    
    //-----------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

//-----------------------------------------------
// MARK Custom animation

//---------------------------------------------
class MainNavigationControllerDelegate: NSObject{
    
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerForOperation operation:
        UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            
            return FadeInAnimator()
    }
    
 }

//---------------------------------------------
class FadeInAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
        ) -> TimeInterval {
            return 0.25
    }
   
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning) {
            let containerView = transitionContext.containerView
            _ = transitionContext.viewController(
                forKey: UITransitionContextViewControllerKey.from)
            let toVC = transitionContext.viewController(
                forKey: UITransitionContextViewControllerKey.to)
            
            containerView.addSubview(toVC!.view)
            toVC!.view.alpha = 0.0
            
            let duration = transitionDuration(using: transitionContext)
            UIView.animate(withDuration: duration, animations: {
                toVC!.view.alpha = 1.0
                }, completion: { finished in
                    let cancelled = transitionContext.transitionWasCancelled
                    transitionContext.completeTransition(!cancelled)
            })
    }
}

//---------------------------------------------
class ReplaceTopSegue: UIStoryboardSegue {
    override func perform() {
        let fromVC = source 
        let toVC = destination 
        
        var vcs = fromVC.navigationController?.viewControllers
        vcs?.removeLast()
        vcs?.append(toVC)
        
        fromVC.navigationController?.setViewControllers(vcs!,
            animated: true)
    }
}
