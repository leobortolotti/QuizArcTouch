//
//  LoadingView.swift
//  QuizArcTouch
//
//  Created by Leonardo Bortolotti on 08/12/19.
//  Copyright © 2019 Leonardo Bortolotti. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        instanceFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        instanceFromNib()
    }
    
    private func instanceFromNib() {
        UINib(nibName: "LoadingView", bundle: nil).instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        
        containerView.layer.cornerRadius = 20
        activityIndicatorView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5) // Scale the activityIndicator size
    }

}
