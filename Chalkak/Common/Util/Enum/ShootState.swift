//
//  ShootState.swift
//  Chalkak
//
//  Created by 배현진 on 7/12/25.
//

enum ShootState: Hashable {
    case firstShoot
    case followUpShoot(guide: Guide)
    case appendShoot(guide: Guide)
}
