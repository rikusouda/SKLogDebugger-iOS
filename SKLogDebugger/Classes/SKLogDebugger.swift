//
//  SKLogDebugger.swift
//  SKLogDebuggerDemo
//
//  Created by yukithehero on 2017/04/20.
//  Copyright © 2017年 yukithehero. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public class SKLogDebugger {
    public static let shared = SKLogDebugger()
    
    internal let logsObserver = PublishSubject<(logs: [SKLDLog], omitActions: [String])>()
    internal var logs: [SKLDLog] = []
    internal var validOmitActions: [String] = SKLDDefaults.validOmitActions.getStrings()
    private weak var parentViewController: UIViewController?

    private var omitActions: [String] = []
    private var menuTrackView: SKLDMenuTrackView?
    private var listTrackView: SKLDListTrackView?
    
    private var isShowTrackView = false
    private let addLogMutex = NSLock()
    private let disposeBag = DisposeBag()
    
    public func setOmitActions(_ actions: [String]) {
        omitActions = actions.unique()
    }
    
    public func addLog(action: String, data: [String: Any]) {
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
        let jsonStr = jsonData.flatMap { String(bytes: $0, encoding: .utf8) }
        addLog(action: action, string: jsonStr ?? "")
    }
    
    public func addLog(action: String, string: String) {
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self = self else { return }
            self.addLogMutex.lock()
            defer { self.addLogMutex.unlock() }
            
            if SKLDDefaults.isDebugMode.getBool() && !self.isShowTrackView {
                self.isShowTrackView = true
                DispatchQueue.main.async {
                    SKLogDebugger.shared.showTrackView()
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.logs.insert(SKLDLog(action: action, string: string), at: 0)
                self.logsObserver.onNext((logs: self.logs, omitActions: self.validOmitActions))
            }
        }
    }
    
    public func openSettingView() {
        let vc = UIStoryboard.instantiate("SKLDSettingViewController") as! SKLDSettingViewController
        vc.omitActions = omitActions
        vc.omitActionsObserver.onNext(omitActions)
        topViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
        hideTrackView()
    }
    
    public func setParentViewController(_ viewController: UIViewController?) {
        parentViewController = viewController
    }
}

extension SKLogDebugger {
    func showTrackView() {
        guard SKLDDefaults.isDebugMode.getBool() else {
            return
        }
        guard let baseWindow = UIApplication.shared.delegate?.window.flatMap({ $0 }) else {
            return
        }
        
        let w = baseWindow.bounds.width
        let h = baseWindow.bounds.height
        
        if let view = menuTrackView {
            view.removeFromSuperview()
            baseWindow.addSubview(view)
        } else {
            let view = SKLDMenuTrackView(frame: CGRect(x: (w/2)-125, y: 20, width: 250, height: 50))
            let gesture = UIPanGestureRecognizer()
            gesture.rx.event.subscribe(onNext: { gesture in
                let p = gesture.location(in: baseWindow)
                switch gesture.state {
                case .changed:
                    view.center.x = p.x
                    view.center.y = p.y
                default:
                    break
                }
            }).disposed(by: view.disposeBag)
            view.addGestureRecognizer(gesture)
            view.realtimeButton.rx.tap.subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let listTrackView = self.listTrackView {
                    listTrackView.isHidden = !listTrackView.isHidden
                }
            }).disposed(by: view.disposeBag)
            view.logListButton.rx.tap.subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.openLogListView()
            }).disposed(by: view.disposeBag)
            view.settingButton.rx.tap.subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.openSettingView()
            }).disposed(by: view.disposeBag)
            baseWindow.addSubview(view)
            menuTrackView = view
        }
        
        if let view = self.listTrackView {
            view.removeFromSuperview()
            baseWindow.addSubview(view)
        } else {
            let view = SKLDListTrackView(frame: CGRect(x: (w/2)-150, y: h-220, width: 300, height: 200))
            let gesture = UIPanGestureRecognizer()
            gesture.rx.event.subscribe(onNext: { gesture in
                let p = gesture.location(in: baseWindow)
                switch gesture.state {
                case .changed:
                    view.center.x = p.x
                    view.center.y = p.y
                default:
                    break
                }
            }).disposed(by: view.disposeBag)
            view.addGestureRecognizer(gesture)
            baseWindow.addSubview(view)
            listTrackView = view
        }
    }
    
    func hideTrackView() {
        menuTrackView?.removeFromSuperview()
        listTrackView?.removeFromSuperview()
    }
    
    private func openLogListView() {
        let vc = UIStoryboard.instantiate("SKLDListViewController") as! SKLDListViewController
        let nvc = UINavigationController(rootViewController: vc)
        topViewController()?.present(nvc, animated: true, completion: nil)
        hideTrackView()
    }
    
    private func topViewController() -> UIViewController? {
        if let parentViewController = parentViewController {
            return parentViewController
        } else {
            var topViewController = UIApplication.shared.keyWindow?.rootViewController
            while let presentedViewController = topViewController?.presentedViewController {
                topViewController = presentedViewController
            }
            return topViewController
        }
    }
}

