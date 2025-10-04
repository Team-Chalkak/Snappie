//import SwiftData
//
//// 앱의 데이터 모델 버전을 정의합니다.
//enum AppSchema: VersionedSchema {
//    // 개선: 모델이 변경되었으므로 버전을 1.0.1로 올립니다.
//    static var versionIdentifier: Schema.Version = .init(1, 0, 1)
//
//    // 현재 최신 버전의 모델 리스트를 정의합니다.
//    static var models: [any PersistentModel.Type] {
//        [Project.self, Guide.self, Clip.self, CameraSetting.self]
//    }
//}
//
//// 마이그레이션 계획을 정의합니다.
//enum MigrationPlan: SchemaMigrationPlan {
//    static var schemas: [any VersionedSchema.Type] {
//        [AppSchema.self] // 현재 앱 스키마를 등록합니다.
//    }
//
//    // 경량 마이그레이션(속성 추가/삭제)은 SwiftData가 자동으로 처리하므로
//    // 별도의 custom stage가 필요하지 않습니다.
//    static var stages: [MigrationStage] {
//        []
//    }
//}
