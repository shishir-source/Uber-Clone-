//
//  View+Properties.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 17/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import MapKit

extension UITextField {
    
    func textField(withPlaceholder placeholder: String, isSecureTextEntry: Bool) -> UITextField {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.tintColor = .white
        tf.textColor = .white
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.keyboardAppearance = .dark
        tf.isSecureTextEntry = isSecureTextEntry
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray ])
        return tf
    }
}

extension UIView {
    func inputContainerView(image: UIImage, textField: UITextField? = nil,
    segmentedControl: UISegmentedControl? = nil) -> UIView{
        let view = UIView()
        let imageView = UIImageView()
        imageView.image = image
        imageView.alpha = 0.87
        view.addSubview(imageView)
        
        
        if let textField = textField {
            imageView.centerY(inView: view)
            imageView.anchor(top: nil, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 8, bottom: 0, right: 0), size: .init(width: 24, height: 24))
            
            view.addSubview(textField)
            textField.centerY(inView: view)
            textField.anchor(top: nil, leading: imageView.trailingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 8, bottom: 8, right: 0))
        }
        
        if let sc = segmentedControl {
            imageView.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: -8, left: 8, bottom: 0, right: 0), size: .init(width: 24, height: 24))
            
            view.addSubview(sc)
            sc.anchor(top:nil, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 8, bottom: 8, right: 8))
            sc.centerY(inView: view, constant: 8)
        }

        let seperatorView = UIView()
        seperatorView.backgroundColor = .lightGray
        view.addSubview(seperatorView)
        seperatorView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor , padding: .init(top: 0, left: 8, bottom: 0, right: 0), size: .init(width: view.frame.width, height: 0.75))
        return view
    }
    
}

extension MKPlacemark{
    var address: String?{
        get{
            guard let subThoroughfare = subThoroughfare else{return nil}
            guard let thoroughfare = thoroughfare else{return nil}
            guard let locality = locality else{return nil}
            guard let adminArea = administrativeArea else{return nil}
            
            return "\(subThoroughfare) \(thoroughfare) \(locality) \(adminArea)"
        }
    }
}

extension MKMapView {
    func zoomToFit(annotations: [MKAnnotation]) {
        var zoomRect = MKMapRect.null
        
        annotations.forEach { (annotation) in
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y,
                                      width: 0.01, height: 0.01)
            zoomRect = zoomRect.union(pointRect)
        }
        
        let insets = UIEdgeInsets(top: 100, left: 100, bottom: 300, right: 100)
        setVisibleMapRect(zoomRect, edgePadding: insets, animated: true)
    }
    
    func addAnnotationAndSelect(forCoordinate coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        addAnnotation(annotation)
        selectAnnotation(annotation, animated: true)
    }
}
