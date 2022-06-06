//
//  ViewController.swift
//  portraitEffectsMatte_Sample
//
//  Created by WataruNishimoto on 2019/05/23.
//

import UIKit
import AVFoundation
import CoreImage

class ViewController: UIViewController,
                      AVCapturePhotoCaptureDelegate,
                      AVCaptureDepthDataOutputDelegate,
                      UIGestureRecognizerDelegate
{
    // セッション.
    var mySession: AVCaptureSession!
    // デバイス.
    var myDevice: AVCaptureDevice!
    // キャプチャーの出力データを受け付けるオブジェクト
    var photoOutput: AVCapturePhotoOutput!
    // キャプチャ用のImageView
    var captureImageView: UIImageView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.captureImageView = UIImageView()
    }

    override func viewDidAppear(_ animated: Bool)
    {
        self.addTapGesture()
        self.setCaptureSessionOfPhoto()

        // プレビューを表示設定
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.mySession)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.addSublayer(previewLayer)

        self.mySession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        self.mySession.stopRunning()
    }
    
    /// 撮影設定
    func setCaptureSessionOfPhoto()
    {
        do
        {
            self.mySession = AVCaptureSession()
            self.mySession.beginConfiguration()
            self.mySession.sessionPreset = .photo
            
            // メモ：インカメでもtrueDepthCamera搭載のものなら設定可能
            self.myDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
            // 指定したデバイスを使用するために入力を初期化
            let captureDeviceInput = try AVCaptureDeviceInput(device: self.myDevice!)
            // 指定した入力をセッションに追加
            self.mySession.addInput(captureDeviceInput)
            // 出力データを受け取るオブジェクトの作成
            self.photoOutput = AVCapturePhotoOutput()
            self.mySession.addOutput(self.photoOutput)
            self.mySession.commitConfiguration()
            
            self.photoOutput.isDepthDataDeliveryEnabled = true // メモ:commitConfiguration後でないとエラー？
            self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = true // メモ:commitConfiguration後でないとエラー？
        }
        catch
        {
            print(error)
        }
    }
    
    /// タップジェスチャ登録
    func addTapGesture()
    {
        let tapGesture:UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.tapEvent(_:)))
        
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    /// 画面タップした時
    /// - Parameter sender: UITapGestureRecognizer
    @objc func tapEvent(_ sender: UITapGestureRecognizer)
    {
        let settings = AVCapturePhotoSettings()
        settings.isDepthDataDeliveryEnabled = true
        settings.embedsDepthDataInPhoto = true
        settings.isDepthDataFiltered = true
        settings.isPortraitEffectsMatteDeliveryEnabled = true
        settings.embedsPortraitEffectsMatteInPhoto = true
        // 撮影された画像をdelegateメソッドで処理
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    /// 撮影完了時のデリゲート
    /// - Parameters:
    ///   - output: 実行したoutput
    ///   - photo: 撮影データ
    ///   - error: 失敗時のエラーオブジェクト。正常動作時はnil
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let originalImageData = photo.fileDataRepresentation()
        {
            let originalImage = UIImage(data: originalImageData)?.cgImage
            let originalCiImage = CIImage(cgImage: originalImage!)
            let maskImage = CIImage(portaitEffectsMatte: photo.portraitEffectsMatte!)!.resizeToSameSize(as: originalCiImage)
            
            guard let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                kCIInputImageKey: originalCiImage,
                kCIInputMaskImageKey: maskImage]) else {
                return
            }

            guard let outputImage = filter.outputImage else {
                print("imageView doesn't have an image!")
                return
            }
            
            // 一度CGImageを経由しなければなぜか変換されず
            let context = CIContext()
            guard let cgimgtmp = context.createCGImage(outputImage, from: outputImage.extent) else { return }
            let image = UIImage(cgImage: cgimgtmp, scale: 1.0, orientation: UIImage.Orientation.right)

            // 画面遷移
            let nextViewController = PhotoViewer()
            nextViewController.photo = image
            self.present(UINavigationController(rootViewController: nextViewController),
                         animated: true,
                         completion: nil)
        }
    }
}

// CIImageの拡張
extension CIImage {
    func resizeToSameSize(as anotherImage: CIImage) -> CIImage {
        let size1 = extent.size
        let size2 = anotherImage.extent.size
        let transform = CGAffineTransform(scaleX: size2.width / size1.width, y: size2.height / size1.height)
        return transformed(by: transform)
    }
    
    func createCGImage() -> CGImage {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: extent) else { fatalError() }
        return cgImage
    }
}
