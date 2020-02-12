//
//  LocationInputActivationView.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 17/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit

protocol LocationInputActivationViewDelegate: class {
    func presentLocationInputView()
}

class LocationInputActivationView: UIView {
    
    //MARK:: Properties
    
    weak var delegate: LocationInputActivationViewDelegate?
    
    private let indicatorView: UIView = {
       let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let placeHolderLabel: UILabel = {
        let label = UILabel()
        label.text = "Where to?"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    
    //MARK:: Lifecycle
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        addShadow()
    }
    
    func configureUI(){
        backgroundColor = .white
        addSubview(indicatorView)
        indicatorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        indicatorView.setDimensions(height: 6, width: 6)
        
        addSubview(placeHolderLabel)
        placeHolderLabel.centerY(inView: self, leftAnchor: indicatorView.rightAnchor, paddingLeft: 20)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentLocationInputView))
        addGestureRecognizer(tap)
    }
    
    @objc func presentLocationInputView(){
        delegate?.presentLocationInputView()
    }
}