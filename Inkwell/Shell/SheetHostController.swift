import SwiftUI
import UIKit

/// UIKit owns the window chrome. This controller hosts the practice sheet
/// and keeps that canvas mounted. Other surfaces are hosted SwiftUI sheets.
@MainActor
final class SheetHostController: UIViewController {
    private let session: SheetSession
    private var host: UIHostingController<PracticeRoot>?

    init(session: SheetSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(DesignTokens.bg)
        let host = UIHostingController(rootView: PracticeRoot(session: session))
        host.view.backgroundColor = UIColor(DesignTokens.bg)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host
    }
}

struct SheetHostRepresentable: UIViewControllerRepresentable {
    var session: SheetSession

    func makeUIViewController(context: Context) -> SheetHostController {
        SheetHostController(session: session)
    }

    func updateUIViewController(_ controller: SheetHostController, context: Context) {}
}
