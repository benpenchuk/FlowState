//
//  KeyboardObserver.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/18/26.
//

import Combine
import SwiftUI

final class KeyboardObserver: ObservableObject {
    @Published private(set) var isVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(notificationCenter: NotificationCenter = .default) {
        let willShow = notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }
        
        let willHide = notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }
        
        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] isVisible in
                self?.isVisible = isVisible
            }
            .store(in: &cancellables)
    }
}
