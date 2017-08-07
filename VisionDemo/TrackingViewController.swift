//
//  ViewController.swift
//  VisionDemo
//
//  Created by Markus Stöbe on 27.07.17.
//  Copyright © 2017 Markus Stöbe. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class TrackingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

	//******************************************************************************************************************
	//* MARK: - Outlets
	//******************************************************************************************************************
	@IBOutlet weak var livePreView: UIView!
	@IBOutlet weak var selectionView: UIView! {
		didSet {
			self.selectionView.backgroundColor = .clear
			self.selectionView.layer.borderColor = UIColor.blue.cgColor
			self.selectionView.layer.borderWidth = 2
		}
	}

	//******************************************************************************************************************
	//* MARK: - Lifecycle
	//******************************************************************************************************************
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		//Video-Stream einrichten
		setupVideoPreview(withView: livePreView)

		//Auswahl zu Beginn ausblenden, Frame wird später durch den Tap-Delegate neu gesetzt
		selectionView.frame = .zero
	}

	//******************************************************************************************************************
	//* MARK: - Videofeed von der Kamera einbinden
	//******************************************************************************************************************
	private let liveSession = AVCaptureSession()
	private var cameraPreviewLayer : AVCaptureVideoPreviewLayer?

	public func setupVideoPreview (withView : UIView) {
		//AVCaptureSession einrichten und Kamera als Quelle wählen
		self.liveSession.sessionPreset = AVCaptureSession.Preset.photo
		if let  cam   = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
			let input = try? AVCaptureDeviceInput(device: cam) {
			self.liveSession.addInput(input)
		}

		//Preview-Layer erzeugen und an die View im UI hängen
		self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session:liveSession)
		self.cameraPreviewLayer!.frame = withView.bounds
		self.cameraPreviewLayer!.videoGravity = .resize
		self.cameraPreviewLayer!.connection?.videoOrientation = .landscapeRight
		withView.layer.addSublayer(self.cameraPreviewLayer!)

		//Video-Stream starten
		self.liveSession.startRunning()

		//ViewController als OutpoutDelegate eintragen (dieser Teil löst das eigentliche Tracking-Verfahren aus)
		let output = AVCaptureVideoDataOutput()
		output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
		self.liveSession.addOutput(output)
	}

	//******************************************************************************************************************
	//* MARK: - Objekt-Tracking
	//******************************************************************************************************************
	//* Delegate Callback (AVCaptureVideoDataOutputSampleBufferDelegate)
	//******************************************************************************************************************
	private let sequenceRequestHandler = VNSequenceRequestHandler()
	private var lastObservation: VNDetectedObjectObservation?

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
			  let lastObservation = self.lastObservation
		else {
			return
		}

		// create the request
		let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation, completionHandler: self.objectTrackingDidFinish)
		// set the accuracy to high
		// this is slower, but it works a lot better
		request.trackingLevel = .accurate

		// perform the request
		do {
			try self.sequenceRequestHandler.perform([request], on: pixelBuffer)
		} catch {
			print("Throws: \(error)")
		}
	}

	//******************************************************************************************************************
	//* completionHandler für den VNTrackObjectRequest
	//******************************************************************************************************************
	private func objectTrackingDidFinish(_ request: VNRequest, error: Error?) {
		// Dispatch to the main queue because we are touching non-atomic, non-thread safe properties of the view controller
		DispatchQueue.main.async {
			// make sure we have an actual result
			guard let newObservation = request.results?.first as? VNDetectedObjectObservation else { return }

			// prepare for next loop
			self.lastObservation = newObservation

			// check the confidence level before updating the UI
			guard newObservation.confidence >= 0.3 else {
				// hide the rectangle when we lose accuracy so the user knows something is wrong
				self.selectionView.frame = .zero
				return
			}

			// calculate view rect
			var transformedRect = newObservation.boundingBox
			transformedRect.origin.y = 1 - transformedRect.origin.y
			let convertedRect = self.cameraPreviewLayer?.layerRectConverted(fromMetadataOutputRect: transformedRect)

			// move the highlight view
			self.selectionView.frame = convertedRect ?? .zero
		}
	}

	//******************************************************************************************************************
	//* MARK: - Tap-Handler
	//******************************************************************************************************************
	@IBAction private func userTapped(_ sender: UITapGestureRecognizer) {
		//User-Tap markieren
		self.selectionView.frame.size = CGSize(width: 120, height: 120)
		self.selectionView.center = sender.location(in: self.view)

		//Bildausschnitt zur Observation speichern/vormerken
		var convertedRect = self.cameraPreviewLayer?.metadataOutputRectConverted(fromLayerRect: self.selectionView.frame)
		if convertedRect != nil {
			convertedRect!.origin.y = 1 - convertedRect!.origin.y
			// set the observation
			let newObservation = VNDetectedObjectObservation(boundingBox: convertedRect!)
			self.lastObservation = newObservation
		}
	}




}

