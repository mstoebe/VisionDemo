//
//  RectanglesViewController.swift
//  VisionDemo
//
//  Created by Markus Stöbe on 27.07.17.
//  Copyright © 2017 Markus Stöbe. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class RectanglesViewController: UIViewController {
	@IBOutlet weak var imageView: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let image = UIImage(named: "rects")
		let cgimage = image?.cgImage
		
		guard image != nil, cgimage != nil else {
			print ("error while loading and converting image")
			return
		}
		
		imageView.image = image
		
		//Requesthandler anlegen
		let requestHandler = VNImageRequestHandler(cgImage: cgimage!)
		
		//VNRequest erzeugen
		let request = VNDetectRectanglesRequest { (request, error) in
			//completion-handler
			print ("finished detection")
			
			if let results = request.results as? [VNRectangleObservation] {
				print ("found \(results.count) results")
				
				for result in results {
					
					//Größe des Ergebnis umwandeln
					let boundingBox     = result.boundingBox
					let scaledImageRect = AVMakeRect(aspectRatio: image!.size,
					                                 insideRect: self.view.frame)
					self.imageView.frame = scaledImageRect
					
					let size = CGSize(width:  boundingBox.width  * scaledImageRect.size.width,
					                  height: boundingBox.height * scaledImageRect.size.height)
					let origin = CGPoint(x: scaledImageRect.origin.x + (boundingBox.origin.x * scaledImageRect.size.width),
					                     y: scaledImageRect.origin.y + ((1 - boundingBox.origin.y) * scaledImageRect.size.height) - size.height)
					
					let layer = CAShapeLayer()
					layer.frame = CGRect(origin: origin, size: size)
					layer.borderColor = UIColor.red.cgColor
					layer.borderWidth = 2
					
					self.imageView.layer.addSublayer(layer)
				}
			}
		}
		
		request.maximumObservations = 0
		request.minimumConfidence   = 0.5
		
		//perform request
		do {
			try requestHandler.perform([request])
		} catch {
			print(error)
		}
	}
}
