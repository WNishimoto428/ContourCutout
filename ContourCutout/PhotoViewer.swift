//
//  PhotoViewer.swift
//
//  撮影した画像を表示する。Portrait Matteのテスト
//  Created by WataruNishimoto on 2018/10/20.
//  Copyright © 2018 WataruNishimoto. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class PhotoViewer: UIViewController
{
    /// 表示する画像
    var photo: UIImage!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blue
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel,
                                                                target: self,
                                                                action: #selector(self.OnClickCancelButton))

        let imageView = UIImageView(frame: self.view.frame)
        imageView.contentMode = .scaleAspectFill
        imageView.image = photo
        self.view.addSubview(imageView)
    }
    
    /// キャンセルボタン押下時
    @objc func OnClickCancelButton() {
        self.dismiss(animated: true, completion: nil)
    }
}
