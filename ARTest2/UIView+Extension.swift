//
//  UIView+Extension.swift
//  doughpack
//
//  Created by steven on 2020/2/4.
//  Copyright © 2020 謝榮泰. All rights reserved.
//

import UIKit
enum ExtensionViewTag: Int {
    case toastViewTag = 1001
    case noContentImageViewTag = 1002
    case noContentLabelTag = 1003
}

//抖動方向枚舉
public enum ShakeDirection: Int {
    case horizontal  //水平抖動
    case vertical  //垂直抖動
}


/// MARK - UIView
extension UIView {
    /**
     擴展UIView增加抖動方法
     @param direction：抖動方向（默認是水平方向）
     @param times：抖動次數（默認5次）
     @param interval：每次抖動時間（默認0.1秒）
     @param delta：抖動偏移量（默認2）
     @param completion：抖動動畫結束後的回調
     */
    public func shake(direction: ShakeDirection = .horizontal, times: Int = 3,
                      interval: TimeInterval = 0.05, delta: CGFloat = 4,
                      completion: (() -> Void)? = nil) {
        //播放動畫
        UIView.animate(withDuration: interval, animations: { () -> Void in
            switch direction {
            case .horizontal:
                self.layer.setAffineTransform( CGAffineTransform(translationX: delta, y: 0))
                break
            case .vertical:
                self.layer.setAffineTransform( CGAffineTransform(translationX: 0, y: delta))
                break
            }
        }) { (complete) -> Void in
            //如果當前是最後一次抖動，則將位置還原，並調用完成回調函數
            if (times == 0) {
                UIView.animate(withDuration: interval, animations: { () -> Void in
                    self.layer.setAffineTransform(CGAffineTransform.identity)
                }, completion: { (complete) -> Void in
                    completion?()
                })
            }
                //如果當前不是最後一次抖動，則繼續播放動畫（總次數減1，偏移位置變成相反的）
            else {
                self.shake(direction: direction, times: times - 1,  interval: interval,
                           delta: delta * -1, completion:completion)
            }
        }
    }
    
    /**
     * 顯示 Toast 訊息方塊
     * @param text 顯示文字
     */
    func showToast(text: String){
        self.removeToast()
        let toastLb = UILabel()
        toastLb.numberOfLines = 0
        toastLb.lineBreakMode = .byWordWrapping
        toastLb.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLb.textColor = UIColor.white
        toastLb.layer.cornerRadius = 10.0
        toastLb.textAlignment = .center
        toastLb.font = UIFont.systemFont(ofSize: 15.0)
        toastLb.text = text
        toastLb.layer.masksToBounds = true
        toastLb.tag = ExtensionViewTag.toastViewTag.rawValue//tag：hideToast實用來判斷要remove哪個label
        
        let maxSize = CGSize(width: self.bounds.width - 40, height: self.bounds.height)
        var expectedSize = toastLb.sizeThatFits(maxSize)
        var lbWidth = maxSize.width
        var lbHeight = maxSize.height
        if maxSize.width >= expectedSize.width{
            lbWidth = expectedSize.width
        }
        if maxSize.height >= expectedSize.height{
            lbHeight = expectedSize.height
        }
        expectedSize = CGSize(width: lbWidth, height: lbHeight)
        toastLb.frame = CGRect(x: ((self.bounds.size.width)/2) - ((expectedSize.width + 20)/2), y: self.bounds.height - expectedSize.height - 40 - 100, width: expectedSize.width + 20, height: expectedSize.height + 20)
        self.addSubview(toastLb)
        
        UIView.animate(withDuration: 1, delay: 1, animations: {
            toastLb.alpha = 0.0
        }) { (complete) in
            toastLb.removeFromSuperview()
        }
    }
    
    /**
     * 移除 Toast 訊息方塊
     * @param text 顯示文字
     */
    func removeToast(){
        for view in self.subviews{
            if view is UILabel , view.tag == ExtensionViewTag.toastViewTag.rawValue{
                view.removeFromSuperview()
            }
        }
    }
    
    /**
     * 顯示無資料訊息
     */
    func showNoContentView(){
        let noContentImageView = UIImageView()
        noContentImageView.frame = CGRect.init(x: self.center.x-self.frame.width*0.3/2, y: self.center.y-self.frame.width*0.3/2, width: self.frame.width*0.3, height: self.frame.width*0.3)
        noContentImageView.image = UIImage.init(named: "icon_norecord")
        noContentImageView.tag = ExtensionViewTag.noContentImageViewTag.rawValue
        noContentImageView.contentMode = .scaleAspectFit
        self.addSubview(noContentImageView)
        
        let noContentLabel = UILabel()
        noContentLabel.frame = CGRect.init(x: self.center.x-self.frame.width*0.3/2, y: noContentImageView.frame.maxY + 20, width: self.frame.width*0.3, height: 25)
        noContentLabel.text = "暫無邀請紀錄~"
        noContentLabel.tag = ExtensionViewTag.noContentLabelTag.rawValue
        noContentLabel.textAlignment = .center
        self.addSubview(noContentLabel)
    }
    
    /**
     * 移除無資料訊息
     */
    func removeNoContentView(){
        for view in self.subviews{
            if view is UILabel , view.tag == ExtensionViewTag.noContentLabelTag.rawValue{
                view.removeFromSuperview()
            }else if view is UIImageView , view.tag == ExtensionViewTag.noContentImageViewTag.rawValue{
                view.removeFromSuperview()
            }
        }
    }
    
    /**
     * 單邊圓角
     */
    func corner(byRoundingCorners corners: UIRectCorner, radii: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radii, height: radii))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
    
    fileprivate var bezierPathIdentifier:String { return "bezierPathBorderLayer" }

    fileprivate var bezierPathBorder:CAShapeLayer? {
        return (self.layer.sublayers?.filter({ (layer) -> Bool in
            return layer.name == self.bezierPathIdentifier && (layer as? CAShapeLayer) != nil
        }) as? [CAShapeLayer])?.first
    }

    func bezierPathBorder(_ color:UIColor = .white, width:CGFloat = 1) {

        var border = self.bezierPathBorder
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius:self.layer.cornerRadius)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask

        if (border == nil) {
            border = CAShapeLayer()
            border!.name = self.bezierPathIdentifier
            self.layer.addSublayer(border!)
        }

        border!.frame = self.bounds
        let pathUsingCorrectInsetIfAny =
            UIBezierPath(roundedRect: border!.bounds, cornerRadius:self.layer.cornerRadius)

        border!.path = pathUsingCorrectInsetIfAny.cgPath
        border!.fillColor = UIColor.clear.cgColor
        border!.strokeColor = color.cgColor
        border!.lineWidth = width * 2
    }

    func removeBezierPathBorder() {
        self.layer.mask = nil
        self.bezierPathBorder?.removeFromSuperlayer()
    }
    
    func addBottomBorder(color:CGColor) {
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.masksToBounds = false
        self.layer.shadowColor = color
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UIView {
    //選擇範圍圓角
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    //自定義shadow
    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float) {
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        
        let backgroundCGColor = backgroundColor?.cgColor
        backgroundColor = nil
        layer.backgroundColor =  backgroundCGColor
    }
}

/// 初始化.xib View
extension UIView {
    class func initFromNib() -> Self {
        return initFromNib(self)
    }
    
    private class func initFromNib<T: UIView>(_ type: T.Type) -> T {
        let objects = Bundle.main.loadNibNamed(String(describing: self), owner: self, options: [:])
        return objects?.first as? T ?? T()
    }
}

