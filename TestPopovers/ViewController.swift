//
//  ViewController.swift
//  TestPopovers
//
//  Created by terhechte on 30.03.21.
//

import UIKit
import SwiftUI
import Combine

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let popoverButton = UIButton(primaryAction: UIAction(title: "Open", handler: self.handleInspector(_:)))
        popoverButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popoverButton)
        NSLayoutConstraint.activate([
            popoverButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            popoverButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func handleInspector(_ action: UIAction) {
        let controller = InspectorController()
        controller.preferredContentSize = CGSize(width: 333, height: 260)
        controller.view.insetsLayoutMarginsFromSafeArea = true
        controller.popoverPresentationController?.canOverlapSourceViewRect = true
        
        let container = UINavigationController(rootViewController: controller)
        container.title = "Hello"
        container.modalPresentationStyle = .popover
        container.popoverPresentationController?.sourceView = action.sender as? UIView
        present(container, animated: false, completion: nil)
    }
}

struct PlaybackInspector: View {
    struct InnerElement: View {
        var body: some View {
            Text("Example").padding()
        }
    }
    var sizePublisher: PassthroughSubject<CGSize, Never>
    @State private var showMore: Bool = false
    var body: some View {
        ScrollView {
            VStack {
                InnerElement()
                InnerElement()
                InnerElement()
                Toggle("More", isOn: $showMore)
                if showMore {
                    InnerElement()
                    InnerElement()
                    InnerElement()
                    InnerElement()
                    InnerElement()
                }
            }
            .padding()
            .overlay(SizeMonitor())
            .onPreferenceChange(SizeMonitor.SizePreferenceKey.self, perform: {
                self.sizePublisher.send($0)
            })

        }
    }
}

final class InspectorController: UIHostingController<PlaybackInspector> {
    
    private let resizePublisher: PassthroughSubject<CGSize, Never> = PassthroughSubject()
    private var resizeCancellable: AnyCancellable?
    private var firstResizeDone: Bool = false
    
    public init() {
        super.init(rootView: PlaybackInspector(
            sizePublisher: resizePublisher
        ))
        
        // Event Resize Handling
        resizeCancellable = resizePublisher.sink(receiveValue: { [weak self] (size) in
            guard let self = self else { return }
            
            let width = self.preferredContentSize.width
            
            if !disableDeprecatedFirstResize {
                if !self.firstResizeDone {
                    DispatchQueue.main.async {
                        CATransaction.stasis {
                            self.navigationController?.preferredContentSize = CGSize(width: width, height: size.height)
                            self.firstResizeDone.toggle()
                        }
                    }
                    return
                }
            }
            
            /// Statis is required as otherwise we get weird animations when switching segments
            /// Dispatch is needed on iOS 14, otherwise there're weird animations
            if disableComplexDispatchStasis {
                self.navigationController?.preferredContentSize = CGSize(width: width, height: size.height)
            } else {
                DispatchQueue.main.async {
                    CATransaction.stasis {
                        self.navigationController?.preferredContentSize = CGSize(width: width, height: size.height)
                    }
                }
            }
        })
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

internal struct SizeMonitor: View {
    internal struct SizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            return Rectangle().preference(key: SizePreferenceKey.self, value: geometry.size).hidden()
        }
    }
}

public extension CATransaction {
    static func stasis(_ action: () -> Void) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        action()
        CATransaction.commit()
    }
}
