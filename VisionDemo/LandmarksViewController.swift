//
//  LandmarksViewController.swift
//  VisionDemo
//
//  Created by Markus Stöbe on 27.07.17.
//  Copyright © 2017 Markus Stöbe. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class LandmarksViewController: UIViewController {
	@IBOutlet weak var imageView: UIImageView!
	
	let image = UIImage(named: "faces")
	var requestHandler : VNImageRequestHandler?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		imageView.image = image

	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		findLandmarks(in: image)
	}
	
	func findLandmarks(in image:UIImage?) {
		//Bild laden
		let cgimage = image?.cgImage
		guard image != nil, cgimage != nil else {
			print ("error while loading and converting image")
			return
		}
		
		//Requesthandler anlegen
		self.requestHandler = VNImageRequestHandler(cgImage: cgimage!)
		guard self.requestHandler != nil else {
			print ("error generating requestHandler")
			return
		}
		
		print("...now looking for noses...")
		var allNoses = [[CGPoint]]()
		
		//VNRequest erzeugen
		let request = VNDetectFaceLandmarksRequest { (request, error) in
			//completion-handler
			print ("finished searching for noses")
			
			//wenns einen Fehler gab, aufhören
			if let error = error {
				print ("…with error:" + error.localizedDescription)
				return
			}
			
			if let results = request.results as? [VNFaceObservation] {
				print ("found \(results.count) landmark-sets")
				
				for face in results {
					if let nose = face.landmarks?.nose {
						//calc bounding box for face, again
						let boundingBox     = face.boundingBox
						let scaledImageRect = AVMakeRect(aspectRatio: self.image!.size, insideRect: self.view.frame)
						
						let size = CGSize(width:  boundingBox.width  * scaledImageRect.size.width,
						                  height: boundingBox.height * scaledImageRect.size.height)
						let origin = CGPoint(x: scaledImageRect.origin.x + (boundingBox.origin.x * scaledImageRect.size.width),
						                     y: scaledImageRect.origin.y + ((1 - boundingBox.origin.y) * scaledImageRect.size.height) - size.height)
						
						//Ergebnis einrahmen
						let layer = CAShapeLayer()
						layer.frame = CGRect(origin: origin, size: size)
						layer.borderColor = UIColor.red.cgColor
						layer.borderWidth = 2
						self.imageView.layer.addSublayer(layer)
						
						//Nasenpunkte konvertieren
						var pointsForThisNose = [CGPoint]()
						
						for i in 0...nose.pointCount {
							let point    = nose.point(at: i)
							let newPoint = CGPoint(x: origin.x + (     CGFloat(point.x)  * size.width),
							                       y: origin.y + ((1 - CGFloat(point.y)) * size.height))
							pointsForThisNose.append(newPoint)
						}
						
						allNoses.append(pointsForThisNose)
					}
				}
				
				//Nasen nachziehen
				self.highlightNoses(in: self.imageView, noses: allNoses)
			}
		}
		
		//…und Nasen suchen lassen!
		do {
			try self.requestHandler!.perform([request])
		} catch {
			print(error)
		}
	}
	
	func highlightNoses(in image:UIImageView, noses:[[CGPoint]]) {
		for nose in noses {
			let layer = CAShapeLayer()
			layer.strokeColor = UIColor.green.cgColor
			layer.lineWidth   = 1.0
			
			let path = UIBezierPath()
			for point in nose {
				if nose.index(of: point) == 0 {
					path.move(to: point)
				} else if nose.index(of: point) == nose.count-1 {
					path.move(to: point)
				} else {
					path.addLine(to: point)
					path.move(to: point)
				}
			}
			layer.path = path.cgPath
			image.layer.addSublayer(layer)
		}
	}
}
