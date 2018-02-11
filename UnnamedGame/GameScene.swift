//
//  GameScene.swift
//  UnnamedGame
//
//  Created by Josephine Chen on 2/10/18.
//  Copyright © 2018 Josephine Chen. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    let hero = SKSpriteNode(imageNamed: "p1_front")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let heroMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero //2D vector
    
    let playableRect: CGRect //Limit sprite bounds
    var lastTouchLocation = CGPoint.zero
    
    let heroAnimation: SKAction
    
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "bg")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.size.height = self.size.height
        background.size.width = self.size.width
        background.zPosition = -1
        addChild(background)
        
        //Hero
        self.hero.position = CGPoint(x: 400, y: 400)
        addChild(self.hero)
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run() { [weak self] in
                self?.spawnCoin()
                },
                               SKAction.wait(forDuration: 1.0)])))
        //hero.run(SKAction.repeatForever(heroAnimation))
        //debugDrawPlayableArea()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0 }
        lastUpdateTime = currentTime
        boundsCheckHero()
        let offset = CGPoint(x: lastTouchLocation.x - hero.position.x,
                             y: lastTouchLocation.y - hero.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        if length <= Double(heroMovePointsPerSec * CGFloat(dt)) {
            hero.position = lastTouchLocation
            velocity = CGPoint.zero
            stopHeroAnimation()
        } else {
            move(sprite: hero, velocity: velocity)
            rotate(sprite: hero, direction: velocity)
        }
        checkCollisions()
    }
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        //Hero animation
        var textures:[SKTexture] = []
        for i in 1...9 {
            textures.append(SKTexture(imageNamed: "p1_walk0\(i)"))
        }
        for i in 0...1 {
            textures.append(SKTexture(imageNamed: "p1_walk1\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        heroAnimation = SKAction.animate(with: textures,
                                           timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func move(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveHeroToward(location: CGPoint) {
        startHeroAnimation()
        let offset = CGPoint(x: location.x - hero.position.x,
                             y: location.y - hero.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length),
                                y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * heroMovePointsPerSec,
                           y: direction.y * heroMovePointsPerSec)
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        moveHeroToward(location: touchLocation)
        lastTouchLocation = touchLocation
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckHero() {
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        if hero.position.x <= bottomLeft.x {
            hero.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if hero.position.x >= topRight.x {
            hero.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if hero.position.y <= bottomLeft.y {
            hero.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if hero.position.y >= topRight.y {
            hero.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func rotate(sprite: SKSpriteNode, direction: CGPoint) {
        sprite.zRotation = CGFloat(
            atan2(Double(direction.y), Double(direction.x)))
    }
    
    
    func startHeroAnimation() {
        if hero.action(forKey: "animation") == nil {
            hero.run(
                SKAction.repeatForever(heroAnimation),
                withKey: "animation")
        } }
    func stopHeroAnimation() {
        hero.removeAction(forKey: "animation")
    }
    
    // MARK: - Coin
    func spawnCoin() {
        let coin = SKSpriteNode(imageNamed: "coinGold")
        coin.name = "coin"
        coin.position = CGPoint(
            x: CGFloat.random(min: playableRect.minX,
                              max: playableRect.maxX),
            y: CGFloat.random(min: playableRect.minY,
                              max: playableRect.maxY))
        coin.setScale(0)
        addChild(coin)
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        let wait = SKAction.wait(forDuration: 10.0)
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, wait, disappear, removeFromParent]
        coin.run(SKAction.sequence(actions))
    }
    
    // MARK: - Collision
    func heroCollect(coin: SKSpriteNode) {
        coin.removeFromParent()
    }
    
    func checkCollisions() {
        var collectCoins: [SKSpriteNode] = []
        enumerateChildNodes(withName: "coin") { node, _ in
            let coin = node as! SKSpriteNode
            if coin.frame.intersects(self.hero.frame) {
                collectCoins.append(coin)
            }
        }
        for coin in collectCoins {
            heroCollect(coin: coin)
        }
    }
    
    
    // MARK: - Debug
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
//    var entities = [GKEntity]()
//    var graphs = [String : GKGraph]()
//
//    private var lastUpdateTime : TimeInterval = 0
//    private var label : SKLabelNode?
//    private var spinnyNode : SKShapeNode?
//
//    override func sceneDidLoad() {
//
//        self.lastUpdateTime = 0
//
//        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
//
//        // Create shape node to use during mouse interaction
//        let w = (self.size.width + self.size.height) * 0.05
//        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
//
//        if let spinnyNode = self.spinnyNode {
//            spinnyNode.lineWidth = 2.5
//
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
//        }
//    }
//
//
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//
//        // Initialize _lastUpdateTime if it has not already been
//        if (self.lastUpdateTime == 0) {
//            self.lastUpdateTime = currentTime
//        }
//
//        // Calculate time since last update
//        let dt = currentTime - self.lastUpdateTime
//
//        // Update entities
//        for entity in self.entities {
//            entity.update(deltaTime: dt)
//        }
//
//        self.lastUpdateTime = currentTime
//    }
}
