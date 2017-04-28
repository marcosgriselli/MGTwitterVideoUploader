//
//  ViewController.swift
//  MGTwitterVideoUploader
//
//  Created by marcosgriselli on 04/28/2017.
//  Copyright (c) 2017 marcosgriselli. All rights reserved.
//

import UIKit
import MGTwitterVideoUploader

class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBAction func shareTapped(_ sender: UIButton) {
        guard let videoPath = Bundle.main.path(forResource: "superKaioken", ofType:"mp4") else {
            debugPrint("superKaioken.mp4 not found")
            return
        }
        
        let twitterUploader = MGTwitterVideoUploader()
        twitterUploader.successCallback = { message in
            DispatchQueue.main.async {
                sender.isEnabled = true
                self.setLoader(visible: false)
                debugPrint(message ?? "Success without message")
            }
        }
        twitterUploader.errorCallback = { error in
            DispatchQueue.main.async {
                sender.isEnabled = true
                self.setLoader(visible: false)
                print(error.localizedDescription)
            }
        }
        
        sender.isEnabled = false
        setLoader(visible: true)
        twitterUploader.postVideo(videoURL: URL(fileURLWithPath: videoPath), withStatus: textView.text)
    }
    
    func setLoader(visible: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = visible
    }
}

