//
//  AppDelegate.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import UIKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set a temporary root view controller to prevent "Application windows are expected to have a root view controller" crash
        // Since Google Sign-In check is asynchronous.
        let launchStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        window?.rootViewController = launchStoryboard.instantiateInitialViewController() ?? UIViewController()
        window?.makeKeyAndVisible()
        
        // Restore previous sign-in
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            let isLoggedIn = user != nil
            
            // If the user isn't logged in, instantly drop them onto the 2nd tab (Profile tab/Login View)
            let selectedIndex = isLoggedIn ? 0 : 1
            self?.showMainTabBar(selectedIndex: selectedIndex)
        }
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CoreDataManager.shared.saveContext()
    }
    
    func showMainTabBar(selectedIndex: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            tabBarVC.selectedIndex = selectedIndex
            window?.rootViewController = tabBarVC
        }
    }
}
