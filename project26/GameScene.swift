//
//  GameScene.swift
//  project26
//
//  Created by Tamim Khan on 27/3/23.
//
import CoreMotion
import SpriteKit


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum CollisionTypes: UInt32 {
        case player = 1
        case wall = 2
        case star = 4
        case vortex = 8
        case finish = 16
    }
    var player: SKSpriteNode!
    
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager!
    
    var scoreLable: SKLabelNode!
    
    var score = 0 {
        didSet{
            scoreLable?.text = "score: \(score)"
        }
    }
    
    var isGameOver = false
    
    
    override func didMove(to view: SKView) {
        
        
        
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        
        scoreLable = SKLabelNode(fontNamed: "Chalkduster")
        scoreLable.text = "score: 0"
        scoreLable.position = CGPoint(x: 16, y: 16)
        scoreLable.horizontalAlignmentMode = .left
        scoreLable.zPosition = 2
        addChild(scoreLable)
        
        
        loadLevel()
        creatPlayer()
        
        
        physicsWorld.gravity = .zero
        
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        physicsWorld.contactDelegate = self
    }
    
    func loadLevel(){
        guard let levelUrl = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
            fatalError("could not find level1.txt in app bundle")
        }
        guard let levelString = try? String(contentsOf: levelUrl) else {
            fatalError("could not load level1.txt from app bundle")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated(){
            for (column, letter) in line.enumerated(){
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x"{
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position
                    
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    addChild(node)
                    
                    
                }else if letter == "v"{
                    let node = SKSpriteNode(imageNamed: "vortex")
                    node.name = "vortex"
                    node.position = position
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                    
                    
                }else if letter == "s"{
                    let node = SKSpriteNode(imageNamed: "star")
                    node.name = "star"
                    node.position = position
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                
                    
                    
                }else if letter == "f"{
                    let node = SKSpriteNode(imageNamed: "finish")
                    node.name = "finish"
                    node.position = position
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    
                    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                    
                    
                }else if letter == " "{
                    
                }else{
                    fatalError("unknown level letter \(letter)")
                }
                
            }
        }
    }
    
    
    func creatPlayer(){
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
 
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
         let location = touch.location(in: self)
         lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else {return}
        
        
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition{
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
            
        }
        #else
        if let acceleromotorData = motionManager.accelerometerData{
            physicsWorld.gravity = CGVector(dx: acceleromotorData.acceleration.y * -50, dy: acceleromotorData.acceleration.x * 50)
        }
        #endif
    }
 
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return}
        guard let nodeB = contact.bodyB.node else {return}
        
        
        if nodeA == player{
            playerCollided(with: nodeB)
        } else if nodeB == player{
            playerCollided(with: nodeA)
        }
        
    }
    
    func playerCollided(with node: SKNode){
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scle = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scle, remove])
            
            
            player.run(sequence) {[weak self] in
                self?.creatPlayer()
                self?.isGameOver = false
            }
        }else if node.name == "star" {
            node.removeFromParent()
            score += 1
        }else if node.name == "finish"{
            
        }
    }
    
    
}
