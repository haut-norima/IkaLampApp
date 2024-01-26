//
//  BoundingBoxView.swift
//  MLModelCamera
//
//  Created by Shuichi Tsutsumi on 2020/03/22.
//  Copyright © 2020 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Vision
import AVFoundation.AVUtilities

@available(iOS 12.0, *)
class BoundingBoxView:  UIView, AVAudioPlayerDelegate {
    var friends_alive_old: Int = 0
    var enemies_alive_old: Int = 0
    private let strokeWidth: CGFloat = 2
    private var imageRect: CGRect = CGRect.zero
    var observations: [VNRecognizedObjectObservation]!
    var player:AVAudioPlayer!
    func updateSize(for imageSize: CGSize) {
        imageRect = AVMakeRect(aspectRatio: imageSize, insideRect: self.bounds)
        print(imageSize)
        print(self.bounds)
    }
    
    override func draw(_ rect: CGRect) {
        guard observations != nil && observations.count > 0 else { return }
        subviews.forEach({ $0.removeFromSuperview() })

        let context = UIGraphicsGetCurrentContext()!
        
        for m in 0..<observations.count {
            print("m:",m)
            print("ocount:",observations.count)
            
            var observation = observations[m]
            var color = UIColor(hue: CGFloat(m) / CGFloat(observations.count), saturation: 1, brightness: 1, alpha: 1)
            if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                let firstLabelHash = recognizedObjectObservation.labels.first?.identifier.hashValue ?? 0.hashValue
                color = UIColor(hue: (CGFloat(firstLabelHash % 256) / 512.0) + 1.0, saturation: 1, brightness: 1, alpha: 1)
            }

            let rect = drawBoundingBox(context: context, observation: observation, color: color)
            
            if #available(iOS 12.0, *), let recognizedObjectObservation = observation as? VNRecognizedObjectObservation {
                addLabel(on: rect, observation: recognizedObjectObservation, color: color)
            }
        }
    }
    
    private func drawBoundingBox(context: CGContext, observation: VNDetectedObjectObservation, color: UIColor) -> CGRect {
        let convertedRect = VNImageRectForNormalizedRect(observation.boundingBox, Int(imageRect.width), Int(imageRect.height))
        let x = convertedRect.minX + imageRect.minX
//        let x2 = convertedRect.minX
        let y = (imageRect.height - convertedRect.maxY) + imageRect.minY
        let rect = CGRect(origin: CGPoint(x: x, y: y), size: convertedRect.size)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(strokeWidth)
        context.stroke(rect)
        
        
//        let rect2 = CGRect(origin: CGPoint(x: x2, y: 0), size: convertedRect.size)
//        context.stroke(rect2)

        return rect
    }

    @available(iOS 12.0, *)
    private func addLabel(on rect: CGRect, observation: VNRecognizedObjectObservation, color: UIColor) {
        guard let firstLabel = observation.labels.first?.identifier else { return }
                
        let label = UILabel(frame: .zero)
        label.text = firstLabel
        print(observations.count)
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: rect.origin.x-strokeWidth/2,
                             y: rect.origin.y - label.frame.height,
                             width: label.frame.width,
                             height: label.frame.height)
        addSubview(label)
        if observations.count == 8{
            struct Lamp{
                var X :CGFloat
                var DoA :String}
            var Lamps = [
                Lamp(X: observations[0].boundingBox.minX,DoA: observations[0].labels.first?.identifier ?? "undetect"),Lamp(X: observations[1].boundingBox.minX,DoA: observations[1].labels.first?.identifier ?? "undetect"),Lamp(X: observations[2].boundingBox.minX,DoA: observations[2].labels.first?.identifier ?? "undetect"),Lamp(X: observations[3].boundingBox.minX,DoA: observations[3].labels.first?.identifier ?? "undetect"),Lamp(X: observations[4].boundingBox.minX,DoA: observations[4].labels.first?.identifier ?? "undetect"),Lamp(X: observations[5].boundingBox.minX,DoA: observations[5].labels.first?.identifier ?? "undetect"),Lamp(X: observations[6].boundingBox.minX,DoA: observations[6].labels.first?.identifier ?? "undetect"),Lamp(X: observations[7].boundingBox.minX,DoA: observations[7].labels.first?.identifier ?? "undetect")
            ]
            Lamps.sort(by: {$0.X < $1.X})
            let friends = Lamps[0..<4]
            let enemies = Lamps[4..<8]
            let friends_alive = friends.map(\.DoA).filter({ $0.contains("up") }).count
            let enemies_alive = enemies.map(\.DoA).filter({ $0.contains("up") }).count
            print("friends_alive:",friends_alive)
            print("enemies_alive:",enemies_alive)
            if (friends_alive != friends_alive_old || enemies_alive != enemies_alive_old) {
                
                let friends_str = String(friends_alive)
                let enemies_str = String(enemies_alive)
                let FvE = "v_" + friends_str + "_" + enemies_str
                let path = Bundle.main.path(forResource: FvE, ofType: "mp3")
                do {player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path!))
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.player?.play()
                    }
                }
            }
            friends_alive_old = friends_alive
            enemies_alive_old = enemies_alive
        }
    }
    }

