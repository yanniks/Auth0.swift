#if os(iOS)
    import SafariServices
    import UIKit

    public extension WebAuthentication {
        /// Creates a Web Auth provider that uses `SFSafariViewController` as the external user agent.
        ///
        /// ## Usage
        ///
        /// ```swift
        /// Auth0
        ///     .webAuth()
        ///     .provider(WebAuthentication.safariProvider())
        ///     .start { result in
        ///         // ...
        /// }
        /// ```
        ///
        /// If you need specify a custom `UIModalPresentationStyle`:
        ///
        /// ```swift
        /// Auth0
        ///     .webAuth()
        ///     .provider(WebAuthentication.safariProvider(style: .formSheet))
        ///     .start { result in
        ///         // ...
        /// }
        /// ```
        ///
        /// - Parameter style: `UIModalPresentationStyle` to be used. Defaults to `.fullScreen`.
        /// - Returns: A ``WebAuthProvider`` instance.
        static func safariProvider(style: UIModalPresentationStyle = .fullScreen) -> WebAuthProvider {
            { url, callback in
                let safari = SFSafariViewController(url: url)
                #if !os(visionOS)
                    safari.dismissButtonStyle = .cancel
                #endif
                safari.modalPresentationStyle = style
                return SafariUserAgent(controller: safari, callback: callback)
            }
        }
    }

    extension SFSafariViewController {
        var topViewController: UIViewController? {
            guard let root = UIApplication.shared()?.windows.last(where: \.isKeyWindow)?.rootViewController else {
                return nil
            }
            return self.findTopViewController(from: root)
        }

        func present() {
            self.topViewController?.present(self, animated: true, completion: nil)
        }

        private func findTopViewController(from root: UIViewController) -> UIViewController? {
            if let presented = root.presentedViewController { return self.findTopViewController(from: presented) }

            switch root {
            case let split as UISplitViewController:
                guard let last = split.viewControllers.last else { return split }
                return self.findTopViewController(from: last)
            case let navigation as UINavigationController:
                guard let top = navigation.topViewController else { return navigation }
                return self.findTopViewController(from: top)
            case let tab as UITabBarController:
                guard let selected = tab.selectedViewController else { return tab }
                return self.findTopViewController(from: selected)
            default:
                return root
            }
        }
    }

    class SafariUserAgent: NSObject, WebAuthUserAgent {
        let controller: SFSafariViewController
        let callback: (WebAuthResult<Void>) -> Void

        init(controller: SFSafariViewController, callback: @escaping (WebAuthResult<Void>) -> Void) {
            self.controller = controller
            self.callback = callback
            super.init()
            #if !os(visionOS)
                self.controller.delegate = self
            #endif
            self.controller.presentationController?.delegate = self
        }

        func start() {
            self.controller.present()
        }

        func finish(with result: WebAuthResult<Void>) {
            if case let .failure(cause) = result, case .userCancelled = cause {
                DispatchQueue.main.async { [callback] in
                    callback(result)
                }
            } else {
                DispatchQueue.main.async { [callback, weak controller] in
                    guard let presenting = controller?.presentingViewController else {
                        let error = WebAuthError(code: .unknown("Cannot dismiss SFSafariViewController"))
                        return callback(.failure(error))
                    }
                    presenting.dismiss(animated: true) {
                        callback(result)
                    }
                }
            }
        }

        override var description: String {
            String(describing: SFSafariViewController.self)
        }
    }

    #if !os(visionOS)
        extension SafariUserAgent: SFSafariViewControllerDelegate {
            func safariViewControllerDidFinish(_: SFSafariViewController) {
                // If you are developing a custom Web Auth provider, call WebAuthentication.cancel() instead
                // TransactionStore is internal
                TransactionStore.shared.cancel()
            }
        }
    #endif

    extension SafariUserAgent: UIAdaptivePresentationControllerDelegate {
        func presentationControllerDidDismiss(_: UIPresentationController) {
            // If you are developing a custom Web Auth provider, call WebAuthentication.cancel() instead
            // TransactionStore is internal
            TransactionStore.shared.cancel()
        }
    }
#endif
