//
//  DrawAreaView.swift
//  Story Squad
//
//  Created by Jonalynn Masters on 3/28/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class DrawAreaView: UIView {

    var lastPoint = CGPoint.zero
    var color = UIColor.black
    
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    
    var drawViewController = DrawViewController()
    
    // MARK: - Outlets

    @IBOutlet weak var mainImageView: UIImageView!
       
    @IBOutlet weak var tempImageView: UIImageView!
    
    @IBAction func resetPressed(_ sender: Any) {
      mainImageView.image = nil
    }
    
    @IBAction func pencilPressed(_ sender: UIButton) {
      guard let pencil = Pencil(tag: sender.tag) else {
        return
      }
      color = pencil.color
      if pencil == .eraser {
        opacity = 1.0
      }
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(drawViewController.view.frame.size)
           guard let context = UIGraphicsGetCurrentContext() else {
             return
           }
        tempImageView.image?.draw(in: drawViewController.view.bounds)
           
           context.move(to: fromPoint)
           context.addLine(to: toPoint)
           
           context.setLineCap(.round)
           context.setBlendMode(.normal)
           context.setLineWidth(brushWidth)
           context.setStrokeColor(color.cgColor)
           
           context.strokePath()
           
           tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
           tempImageView.alpha = opacity
           
           UIGraphicsEndImageContext()
         }
         
         override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
           guard let touch = touches.first else {
             return
           }
           swiped = false
            lastPoint = touch.location(in: drawViewController.view)
         }
         
         override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
           guard let touch = touches.first else {
             return
           }
           swiped = true
            let currentPoint = touch.location(in: drawViewController.view)
           drawLine(from: lastPoint, to: currentPoint)
           
           lastPoint = currentPoint
         }
         
         override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
           if !swiped {
             // draw a single point
             drawLine(from: lastPoint, to: lastPoint)
           }
           
           // Merge tempImageView into mainImageView
           UIGraphicsBeginImageContext(mainImageView.frame.size)
            mainImageView.image?.draw(in: drawViewController.view.bounds, blendMode: .normal, alpha: 1.0)
            tempImageView?.image?.draw(in: drawViewController.view.bounds, blendMode: .normal, alpha: opacity)
           mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           
           tempImageView.image = nil
         }
}
