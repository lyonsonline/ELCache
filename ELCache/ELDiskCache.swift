//
//  ELDiskCache.swift
//  ELCache
//
//  Created by Lyons Eric on 2017/3/9.
//  Copyright © 2017年 Lyons Eric. All rights reserved.
//

import Foundation
import UIKit

private let object = ELDiskCache(type: .object)
private let image = ELDiskCache(type: .image)
private let voice = ELDiskCache(type: .voice)

enum CacheFor: String {
    case object = "ELObject"
    case image = "ELImage"
    case voice = "ELVoice"
}

public class ELDiskCache {
    typealias completeHandler = () -> ()
    fileprivate let defaultCacheName = "el_default"
    fileprivate let cachePrex = "com.el.eldisk.cache."
    fileprivate let ioQueueName = "com.el.eldisk.cache.ioQueue"
    
    fileprivate var fileManager: FileManager!
    fileprivate let ioQueue: DispatchQueue
    var diskCachePath: String
    fileprivate var storeType: CacheFor
    
    init(type: CacheFor) {
        self.storeType = type
        let cacheName = cachePrex + type.rawValue
        ioQueue = DispatchQueue(label: ioQueueName + type.rawValue)
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        diskCachePath = (paths.first! as NSString).appendingPathComponent(cacheName)
        
        ioQueue.sync {
            fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                
            }
        }
    }
    
    public class var sharedCacheObj: ELDiskCache {
        return object
    }
    public class var sharedCacheImage: ELDiskCache {
        return image
    }
    public class var sharedCacheVoice: ELDiskCache {
        return voice
    }
    
    /// 本地存储
    ///
    /// - Parameters:
    ///   - key: 键值
    ///   - value: 对象
    ///   - image: 图片
    ///   - data: 语音
    ///   - completeHandler: 完成回调
    func store(for key: String, with value: Any? = nil, image: UIImage?, data: Data?, completeHandler: completeHandler? = nil) {
        
        /// 存储对象
        ///
        /// - Parameters:
        ///   - key: 键值
        ///   - value: 对象
        ///   - path: 存储路径
        ///   - completeHandler: 完成回调
        func storeObject(_ value: Any?, for key: String, path: String, completeHandler: completeHandler? = nil) {
            ioQueue.async {
                let data = NSMutableData()
                let keyArchiver = NSKeyedArchiver(forWritingWith: data)
                keyArchiver.encode(value, forKey: key)
                keyArchiver.finishEncoding()
                
                do {
                    try data.write(toFile: path, options: .atomic)
                    completeHandler?()
                } catch let error {
                    print(error)
                }
            }
        }
        
        /// 存储图片
        ///
        /// - Parameters:
        ///   - image: 图片
        ///   - key: 键值
        ///   - path: 路径
        ///   - completeHandler: 完成回调
        func storeImage(_ image: UIImage, for key: String, path: String, completeHandler: completeHandler? = nil) {
            ioQueue.async {
                let data = UIImageJPEGRepresentation(image.el_normalizedImage(), 0.9)
                if let data = data {
                    guard self.fileManager.createFile(atPath: path, contents: data, attributes: nil) else {
                        fatalError("存储 image 失败")
                    }
                    completeHandler?()
                }
            }
        }
        
        /// 存储音频
        ///
        /// - Parameters:
        ///   - data: 音频文件
        ///   - key: 键值
        ///   - path: 路径
        ///   - completeHandler: 完成回调
        func storeVoice(_ data: Data, for key: String, path: String, completeHandler: completeHandler? = nil) {
            ioQueue.async {
                guard self.fileManager.createFile(atPath: path, contents: data, attributes: nil) else {
                    fatalError("存储 voice 失败")
                }
                completeHandler?()
            }
        }
        
        let path = cachePathForKey(key)
        switch storeType {
        case .image:
            if let image = image {
                storeImage(image, for: key, path: path, completeHandler: completeHandler)
            }
        case .object:
            storeObject(value, for: key, path: path, completeHandler: completeHandler)
        case .voice:
            if let data = data {
                storeVoice(data, for: key, path: path, completeHandler: completeHandler)
            }
        }
    }
    
    
    
}
extension ELDiskCache{
    func cachePathForKey(_ key: String) -> String {
        func cacheFileNameForKey(_ key: String) -> String {
            return key.zz_MD5
        }
        var fileName:String = ""
        if self.storeType == .voice {
            fileName = cacheFileNameForKey(key)+".wav"     //对name进行MD5加密
        }else{
            fileName = cacheFileNameForKey(key)
        }
        
        return (diskCachePath as NSString).appendingPathComponent(fileName)
    }
    
    
}
extension UIImage {
    
    func el_normalizedImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage!;
    }
}
