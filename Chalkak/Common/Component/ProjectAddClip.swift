import SwiftUI
import TipKit

struct ProjectAddClip: Tip {
    var title: Text {
        Text("장면 추가하기")
            .foregroundStyle(.matcha600)
    }

    var message: Text? {
        Text("버튼을 눌러 장면 촬영 시작")
            .foregroundStyle(.matcha400)
    }

    var options: [TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
