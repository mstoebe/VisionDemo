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

class TrackingViewController: UIViewController {

	@IBOutlet weak var livePreView: UIView!
	@IBOutlet weak var selectionView: UIView!

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		setupVideoPreview(withView: livePreView)
	}

	





	//******************************************************************************************************************
	//* MARK: - Videofeed von der Kamera
	//******************************************************************************************************************
	public func setupVideoPreview (withView : UIView) {
		//AVCaptureSession einrichten und Kamera als Quelle wählen
		let liveSession = AVCaptureSession()
		liveSession.sessionPreset = AVCaptureSession.Preset.photo
		if let cam   = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
			let input = try? AVCaptureDeviceInput(device: cam) {
			liveSession.addInput(input)
		}

		//Preview-Layer erzeugen und an die View im UI hängen
		let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session:liveSession)
		cameraPreviewLayer.frame = withView.bounds
		cameraPreviewLayer.videoGravity = .resize
		cameraPreviewLayer.connection?.videoOrientation = .landscapeRight
		withView.layer.addSublayer(cameraPreviewLayer)

		//Video-Stream starten
		liveSession.startRunning()
	}





}

