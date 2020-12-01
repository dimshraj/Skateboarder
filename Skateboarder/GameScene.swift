//
//  GameScene.swift
//  Skateboarder
//
//  Created by Dmitriy Shrayber on 01.12.2020.
//

import SpriteKit
import GameplayKit
/// Эта структура содержит различные физические категории, 8 и мы можем определить,
/// какие типы объектов сталкиваются или контактируют друг с другом
struct PhysicsCategory {
    static let skater: UInt32 = 0x1 << 0
    static let brick: UInt32 = 0x1 << 1
    static let gem: UInt32 = 0x1 << 2
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    // Массив, содержащий все текущие секции тротуара
    var bricks = [SKSpriteNode]()
    // Размер секций на тротуаре
    var brickSize = CGSize.zero
    // Настройка скорости движения направо для игры
    // Это значение может увеличиваться по мере продвижения пользователя в игре
    var scrollSpeed: CGFloat = 5.0
    // Константа для гравитации (того, как быстро объекты падают 8 на Землю)
    let gravitySpeed: CGFloat = 1.5
    // Время последнего вызова для метода обновления
    var lastUpdateTime: TimeInterval?
   
    let startingScrollSpeed: CGFloat = 5.0
    
    // Здесь мы создаем героя игры - скейтбордистку
    let skater = Skater(imageNamed: "skater")
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -6.0)
        physicsWorld.contactDelegate = self
        anchorPoint = CGPoint.zero
        
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        // Создаем скейтбордистку и добавляем ее к сцене
        skater.setupPhysicsBody()
        // Настраиваем свойства скейтбордистки и добавляем ее в сцену
        
        addChild(skater)
        // Добавляем распознаватель нажатия, чтобы знать, когда 8 пользователь нажимает на экран
        let tapMethod = #selector(GameScene.handleTap(tapGesture:))
        let tapGesture = UITapGestureRecognizer(target: self, action: tapMethod)
        view.addGestureRecognizer(tapGesture)
        startGame()
    }
    
    func resetSkater() {
        // Задаем начальное положение скейтбордистки, zPosition и minimumY
        let skaterX = frame.midX / 2.0
        let skaterY = skater.frame.height / 2.0 + 64.0
        skater.position = CGPoint(x: skaterX, y: skaterY)
        skater.zPosition = 10
        skater.minimumY = skaterY
        
        skater.zRotation = 0.0
        skater.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        skater.physicsBody?.angularVelocity = 0.0
    }
    func startGame() {
        // Возвращение к начальным условиям при запуске новой игры
        resetSkater()
        scrollSpeed = startingScrollSpeed
        lastUpdateTime = nil
        for brick in bricks {
            brick.removeFromParent()
        }
        bricks.removeAll(keepingCapacity: true)
    }
    func gameOver() {
        startGame()
    }
    
    func spawnBrick(atPosition position: CGPoint) -> SKSpriteNode {
        // Создаем спрайт секции и добавляем его к сцене
        let brick = SKSpriteNode(imageNamed: "sidewalk")
        brick.position = position
        brick.zPosition = 8
        addChild(brick)
        // Обновляем свойство brickSize реальным значением размера секции
        brickSize = brick.size
        // Добавляем новую секцию к массиву
        bricks.append(brick)
        // Настройка физического тела секции
        let center = brick.centerRect.origin
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size, center: center)
        brick.physicsBody?.affectedByGravity = false
        brick.physicsBody?.categoryBitMask = PhysicsCategory.brick
        brick.physicsBody?.collisionBitMask = 0
        // Возвращаем новую секцию вызывающему коду
        return brick
    }
    
    func updateBricks(withScrollAmount currentScrollAmount: CGFloat) {
        // Отслеживаем самое большое значение по оси x для всех существующих секций
        var farthestRightBrickX: CGFloat = 0.0
        
        for brick in bricks {
            
            let newX = brick.position.x - currentScrollAmount
            // Если секция сместилась слишком далеко влево (за пределы 8 экрана), удалите ее
            if newX < -brickSize.width {
                
                brick.removeFromParent()
                
                if let brickIndex = bricks.index(of: brick) {
                    bricks.remove(at: brickIndex)
                }
                
            } else {
                // Для секции, оставшейся на экране, обновляем положение
                brick.position = CGPoint(x: newX, y: brick.position.y)
                //Обновляем значение для крайней правой секции
                if brick.position.x > farthestRightBrickX {
                    farthestRightBrickX = brick.position.x
                }
            }
        }
        // Цикл while, обеспечивающий постоянное наполнение экрана секциями
        while farthestRightBrickX < frame.width {
            
            var brickX = farthestRightBrickX + brickSize.width + 1.0
            let brickY = brickSize.height / 2.0
            // Время от времени мы оставляем разрывы, через которые 8 герой должен перепрыгнуть
            let randomNumber = arc4random_uniform(99)
            
            if randomNumber < 10 {
                // 10-процентный шанс на то, что у нас
                // возникнет разрыв между секциями
                let gap = 20.0 * scrollSpeed
                brickX += gap
            }
            // Добавляем новую секцию и обновляем положение самой правой
            let newBrick = spawnBrick(atPosition: CGPoint(x: brickX, y: brickY))
            farthestRightBrickX = newBrick.position.x
        }
    }
    
    func updateSkater() {
        
        // Определяем, находится ли скейтбордистка на земле
        if let velocityY = skater.physicsBody?.velocity.dy {
            if !skater.isOnGround {
                if velocityY < -100.0 || velocityY > 100.0 {
                    skater.isOnGround = false
                }
            }
            // Проверяем, должна ли игра закончиться
            let isOffScreen = skater.position.y < 0.0 ||  skater.position.x < 0.0
            let maxRotation = CGFloat(GLKMathDegreesToRadians(85.0))
            let isTippedOver = skater.zRotation > maxRotation || skater.zRotation < -maxRotation
            if isOffScreen || isTippedOver {
                gameOver() }
        }
    }
    // Вызывается перед отрисовкой каждого кадра
    override func update(_ currentTime: TimeInterval) {
        // Определяем время, прошедшее с момента последнего вызова update
        var elapsedTime: TimeInterval = 0.0
        if let lastTimeStamp = lastUpdateTime {
            elapsedTime = currentTime - lastTimeStamp
        }
        
        lastUpdateTime = currentTime
        
        let expectedElapsedTime: TimeInterval = 1.0 / 60.0
        // Рассчитываем, насколько далеко должны сдвинуться объекты при данном обновлении
        let scrollAdjustment = CGFloat(elapsedTime / expectedElapsedTime)
        let currentScrollAmount = scrollSpeed * scrollAdjustment
        
        updateBricks(withScrollAmount: currentScrollAmount)
        
        updateSkater()
    }
    
    @objc func handleTap(tapGesture: UITapGestureRecognizer) {
        // Заставляем скейтбордистку прыгнуть нажатием на экран, пока она находится на земле
              if skater.isOnGround {
        skater.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 260.0))
        }
    }
    // MARK:- SKPhysicsContactDelegate Methods
    func didBegin(_ contact: SKPhysicsContact) {
        // Проверяем, есть ли контакт между скейтбордисткой и секцией
        if contact.bodyA.categoryBitMask == PhysicsCategory.skater && contact.bodyB.categoryBitMask == PhysicsCategory.brick {
            skater.isOnGround = true
        }
    }
}
