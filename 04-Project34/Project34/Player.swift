//
//  Player.swift
//  Project34
//
//  Created by clarknt on 2019-10-07.
//  Copyright © 2019 clarknt. All rights reserved.
//

import GameplayKit
import UIKit

// challenge 2
enum PlayerType: String, CaseIterable {
    case human = "Human"
    case easyAI = "AI - Easy"
    case mediumAI = "AI - Medium"
    case hardAI = "AI - Hard"
}

class Player: NSObject, GKGameModelPlayer {
    var chip: ChipColor
    var color: UIColor
    var name: String
    var playerId: Int // GKGameModelPlayer
    var playerType: PlayerType

    static var allPlayers = [Player(chip: .red), Player(chip: .yellow)]

    var opponent: Player {
        if chip == .red {
            return Player.allPlayers[1]
        }
        else {
            return Player.allPlayers[0]
        }
    }

    init(chip: ChipColor) {
        self.chip = chip
        self.playerId = chip.rawValue
        self.playerType = PlayerType.human

        if chip == .red {
            color = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)
            name = "Red"
        }
        else {
            color = UIColor(red: 0.8, green: 0.8, blue: 0.1, alpha: 1)
            name = "Yellow"
        }

        super.init()
    }
}
