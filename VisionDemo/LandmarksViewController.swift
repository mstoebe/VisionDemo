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

	let image = UIImage(named: "faces.jpg")
	var requestHandler : VNImageRequestHandler?

	override func viewDidLoad() {
		super.viewDidLoad()
		imageView.image = image
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		findFaces(in: image)
	}

	func findFaces(in image:UIImage?) {
		let cgimage = image?.cgImage
		guard image != nil, cgimage != nil else {
			print ("error while loading and converting image")
			return
		}

		//Requesthandler anlegen
		self.requestHandler = VNImageRequestHandler(cgImage: cgimage! , options: [:])
		guard self.requestHandler != nil else {
			print ("error generating requestHandler")
			return
		}

		//VNRequest erzeugen
		let request = VNDetectFaceRectanglesRequest { (request, error) in
			//completion-handler
			print ("finished face detection")

			if let error = error {
				print ("…with error:" + error.localizedDescription)
				return
			}

			if let results = request.results as? [VNFaceObservation] {
				print ("found \(results.count) faces")

				for result in results {
					//Größe des Ergebnis umwandeln
					let boundingBox     = result.boundingBox
					let scaledImageRect = AVMakeRect(aspectRatio: self.image!.size, insideRect: self.view.frame)
					self.imageView.frame = scaledImageRect

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
				}

				//jetzt gehts weiter mit den Face Landmarks
				self.findLandmarks(in: results)
			}
		}

		//perform request
		do {
			try requestHandler!.perform([request])
		} catch {
			print(error)
		}
	}

	func findLandmarks(in faces:[VNFaceObservation]) {
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
						var pointsForThisNose = [CGPoint]()

						//calc bounding box for face, again
						let boundingBox     = face.boundingBox
						let scaledImageRect = AVMakeRect(aspectRatio: self.image!.size, insideRect: self.view.frame)
						self.imageView.frame = scaledImageRect

						let size = CGSize(width:  boundingBox.width  * scaledImageRect.size.width,
						                  height: boundingBox.height * scaledImageRect.size.height)
						let origin = CGPoint(x: scaledImageRect.origin.x + (boundingBox.origin.x * scaledImageRect.size.width),
						                     y: scaledImageRect.origin.y + ((1 - boundingBox.origin.y) * scaledImageRect.size.height) - size.height)

						for i in 0...nose.pointCount {
							let point    = nose.point(at: i)
							let newPoint = CGPoint(x: origin.x + (     CGFloat(point.x)  * size.width),
							                       y: origin.y + ((1 - CGFloat(point.y)) * size.height))
							pointsForThisNose.append(newPoint)
						}

						allNoses.append(pointsForThisNose)
					}
				}

				self.highlightNoses(in: self.imageView, noses: allNoses)
			}
		}

		//die bereits gefundenen Gesichter übergeben
		request.inputFaceObservations = faces

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
