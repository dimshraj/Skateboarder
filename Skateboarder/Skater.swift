//
//  Skater.swift
//  Skateboarder
//
//  Created by Dmitriy Shrayber on 01.12.2020.
//

import UIKit
import SpriteKit

class Skater: SKSpriteNode {
    var velocity = CGPoint.zero
    var minimumY: CGFloat = 0.0
    var jumpSpeed: CGFloat = 20.0
    var isOnGround = true

}
