//
//  ViewController.swift
//  VideoCapture
//
//  Created by user on 12/4/17.
//  Copyright © 2017 peoplecanfly. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController
{
    var videoCaptureSession : AVCaptureSession? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupAVCapture()
    }

    func setupAVCapture()
    {
        videoCaptureSession = AVCaptureSession()
        videoCaptureSession?.beginConfiguration()
        videoCaptureSession?.sessionPreset = AVCaptureSessionPreset1280x720
        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let input = try! AVCaptureDeviceInput(device: videoDevice)
        videoCaptureSession?.addInput(input)
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.setSampleBufferDelegate(self.view as! AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.main)
        videoCaptureSession?.addOutput(dataOutput)
        videoCaptureSession?.commitConfiguration()
        videoCaptureSession?.startRunning()
    }
}

