//
//  MGTwitterVideoUploader.swift
//  Pods
//
//  Created by Marcos Griselli on 4/28/17.
//
//

import Accounts
import Social

public enum TwitterVideoUploadError: Error {
    // Accounts
    case noAccountsFound
    case noPermissionsToAccessAccounts
    // File
    case noFileFound
    case noFileSizeFound
    // Request error
    case custom(Error)
}

extension TwitterVideoUploadError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .noAccountsFound:
            return "No Accounts where found for Twitter on iOS Settings."
        case .noPermissionsToAccessAccounts:
            return "No permission to access Accounts on iOS Settings."
        case .noFileFound:
            return "No video vas found at that URL."
        case .noFileSizeFound:
            return "Wrong video format."
        case .custom(let error):
            return error.localizedDescription
        }
    }
}

public class MGTwitterVideoUploader: NSObject {
    
    public typealias TwitterVideoUploaderResponseSuccessCallback = (_ message: [String: AnyObject]?) -> ()
    public typealias TwitterVideoUploaderShareResponseFailureCallback = (_ error: TwitterVideoUploadError) -> ()
    
    // MARK: - Public
    public var successCallback: TwitterVideoUploaderResponseSuccessCallback?
    public var errorCallback: TwitterVideoUploaderShareResponseFailureCallback?
    
    // MARK: - Private
    private var account: ACAccount?
    private var tweetStatus: String?
    
    /// Start the video posting flow
    ///
    /// - Parameters:
    ///   - videoURL: video local url
    ///   - status: tweet content
    public func postVideo(videoURL: URL, withStatus status: String) {
        tweetStatus = status
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
            if let fileSizeNumber = fileAttributes[FileAttributeKey.size] as? NSNumber {
                requestAccessToTwitterAccount(videoURL: videoURL, fileSize: fileSizeNumber.uint32Value)
            } else {
                errorCallback?(.noFileSizeFound)
            }
        } catch {
            errorCallback?(.noFileFound)
        }
    }
    
    /// Request Twitter Account
    ///
    /// - Parameters:
    ///   - videoURL: url of the video to upload to twitter
    ///   - fileSize: video to upload size in bytes
    private func requestAccessToTwitterAccount(videoURL: URL, fileSize: UInt32){
        
        let accountStore = ACAccountStore()
        let twitterAccountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: twitterAccountType, options: nil) { granted, error in
            
            if granted {
                let accounts = accountStore.accounts(with: twitterAccountType)
                if let account = accounts?.first as? ACAccount {
                    self.account = account
                    self.uploadVideoToTwitter(videoURL: videoURL, fileSize: fileSize)
                } else {
                    self.errorCallback?(.noAccountsFound)
                }
            } else {
                self.errorCallback?(.noPermissionsToAccessAccounts)
            }
        }
    }
    
    /// Upload Video to twitter
    ///
    /// - Parameters:
    ///   - videoURL: url of the video to upload to twitter
    ///   - fileSize: video to upload size in bytes
    private func uploadVideoToTwitter(videoURL: URL, fileSize:UInt32){
        do {
            let videoData = try Data(contentsOf: videoURL)
            tweetVideoInit(videoData: videoData, videoSize: Int(videoData.count))
        } catch {
            self.errorCallback?(.custom(error))
        }
    }
    
    /// Twitter media/upload INIT command.
    ///
    /// - Parameters:
    ///   - videoData: video to upload converted to Data
    ///   - videoSize: video to upload size in bytes
    private func tweetVideoInit(videoData: Data, videoSize: Int) {
        
        guard let uploadURL = URL(string:"https://upload.twitter.com/1.1/media/upload.json") else { return }
        
        var params = [String:String]()
        
        params["command"] = "INIT"
        params["total_bytes"]  = String(videoData.count)
        params["media_type"]  = "video/mov"
        
        let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.POST,
                                    url: uploadURL,
                                    parameters: params)
        
        postRequest?.account = account
        
        postRequest?.perform(handler: { responseData, urlResponse, error in
            if let error = error {
                self.errorCallback?(.custom(error))
            } else {
                do {
                    let object = try JSONSerialization.jsonObject(with: responseData! as Data, options: .allowFragments)
                    if let dictionary = object as? [String: AnyObject] {
                        if let tweetID = dictionary["media_id_string"] as? String{
                            self.tweetVideoApped(videoData: videoData, videoSize: videoSize, mediaId: tweetID, chunk: 0)
                        }
                    }
                }
                catch {
                    DispatchQueue.main.async { self.errorCallback?(.custom(error)) }
                }
            }
        })
    }
    
    /// Twitter media/upload append command.
    ///
    /// - Parameters:
    ///   - videoData: videoData
    ///   - videoSize: videoSize
    ///   - mediaId  : mediaId
    ///   - chunk    : video chunk number
    private func tweetVideoApped(videoData: Data, videoSize: Int , mediaId: String, chunk: NSInteger) {
        
        guard let uploadURL = URL(string:"https://upload.twitter.com/1.1/media/upload.json") else { return }
        
        var params = [String:String]()
        
        params["command"] = "APPEND"
        params["media_id"]  = mediaId
        params["segment_index"]  = String(chunk)
        
        let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.POST,
                                    url: uploadURL,
                                    parameters: params)
        
        postRequest?.account = account
        postRequest?.addMultipartData(videoData, withName: "media", type: "video/mov", filename:"mediaFile")
        
        postRequest?.perform(handler: { responseData, urlREsponse, error in
            if let error = error {
                self.errorCallback?(.custom(error))
            }else{
                self.tweetVideoFinalize(mediaId: mediaId)
            }
        })
    }
    
    
    /// Twitter media/upload finalize command.
    ///
    /// - Parameter mediaId: mediaId
    private func tweetVideoFinalize(mediaId: String) {
        
        guard let uploadURL = URL(string:"https://upload.twitter.com/1.1/media/upload.json") else { return }
        
        var params = [String : String]()
        
        params["command"] = "FINALIZE"
        params["media_id"]  = mediaId
        
        let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.POST,
                                    url: uploadURL,
                                    parameters: params)
        
        postRequest?.account = account
        
        postRequest?.perform(handler: { responseData, urlREsponse, error in
            if let error = error {
                self.errorCallback?(.custom(error))
            } else {
                do {
                    let object = try JSONSerialization.jsonObject(with: responseData! as Data, options: .allowFragments)
                    if let dictionary = object as? [String: AnyObject] {
                        print(dictionary)
                        self.postStatus(mediaId: mediaId)
                    }
                }
                catch {
                    self.errorCallback?(.custom(error))
                }
            }
        })
    }
    
    
    /// Twitter post media/upload
    ///
    /// - Parameter mediaId: mediaId
    private func postStatus(mediaId:String) {
        
        guard let uploadURL = URL(string:"https://api.twitter.com/1.1/statuses/update.json") else { return }
        
        var params = [String : String]()
        
        params["status"] = tweetStatus
        params["media_ids"]  = mediaId
        
        let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                    requestMethod: SLRequestMethod.POST,
                                    url: uploadURL,
                                    parameters: params)
        
        postRequest?.account = account;
        
        postRequest?.perform(handler: { responseData, urlResponse, error in
            if let error = error {
                self.errorCallback?(.custom(error))
            }else{
                do {
                    let object = try JSONSerialization.jsonObject(with: responseData! as Data, options: .allowFragments)
                    if let dictionary = object as? [String: AnyObject] {
                        debugPrint(dictionary)
                        self.successCallback?(dictionary)
                    }
                }
                catch {
                    self.errorCallback?(.custom(error))
                }
            }
        })
    }
}
