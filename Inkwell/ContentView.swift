import SwiftUI

struct ContentView: View {
    var session: SheetSession

    var body: some View {
        SheetHostRepresentable(session: session)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView(session: SheetSession())
}
