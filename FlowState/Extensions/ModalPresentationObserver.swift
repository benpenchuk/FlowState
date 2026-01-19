//
//  ModalPresentationObserver.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/18/26.
//

import SwiftUI
import UIKit

struct ModalPresentationObserver: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ObserverViewController {
        ObserverViewController { isPresented in
            context.coordinator.update(isPresented: isPresented)
        }
    }
    
    func updateUIViewController(_ uiViewController: ObserverViewController, context: Context) {
        uiViewController.checkPresentation()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    final class Coordinator {
        @Binding private var isPresented: Bool
        private var lastValue: Bool = false
        
        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }
        
        func update(isPresented: Bool) {
            guard isPresented != lastValue else { return }
            lastValue = isPresented
            self.isPresented = isPresented
        }
    }
    
    final class ObserverViewController: UIViewController {
        private let onChange: (Bool) -> Void
        
        init(onChange: @escaping (Bool) -> Void) {
            self.onChange = onChange
            super.init(nibName: nil, bundle: nil)
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            checkPresentation()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            checkPresentation()
        }
        
        func checkPresentation() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let isPresented = self.rootPresentedViewController != nil
                self.onChange(isPresented)
            }
        }
        
        private var rootPresentedViewController: UIViewController? {
            guard let window = view.window,
                  let rootViewController = window.rootViewController else {
                return nil
            }
            return rootViewController.presentedViewController
        }
    }
}
