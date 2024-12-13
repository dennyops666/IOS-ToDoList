//
//  SceneDelegate.swift
//  ToDoList
//
//  Created by Django on 12/8/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var coreDataManager: CoreDataManager?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 初始化 CoreDataManager
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        coreDataManager = CoreDataManager()
        coreDataManager?.context = appDelegate.persistentContainer.viewContext
        
        // 创建主窗口
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // 创建启动画面
        let launchScreenVC = UIViewController()
        launchScreenVC.view.backgroundColor = .black
        
        let titleLabel = UILabel()
        titleLabel.text = "ToDoList"
        titleLabel.font = .boldSystemFont(ofSize: 32)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        launchScreenVC.view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: launchScreenVC.view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: launchScreenVC.view.centerYAnchor)
        ])
        
        // 设置启动画面为根视图控制器
        window.rootViewController = launchScreenVC
        window.makeKeyAndVisible()
        
        // 创建主视图控制器
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "TaskListViewController") as! TaskListViewController
        mainVC.coreDataManager = coreDataManager
        let navigationController = UINavigationController(rootViewController: mainVC)
        
        // 延迟2秒后切换到主界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 使用淡入淡出动画切换视图控制器
            UIView.transition(with: window,
                            duration: 0.3,
                            options: .transitionCrossDissolve,
                            animations: {
                window.rootViewController = navigationController
            }, completion: nil)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
