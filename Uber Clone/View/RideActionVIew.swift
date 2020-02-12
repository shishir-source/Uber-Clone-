//
//  RiderActionView.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 21/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: class {
    func uploadTrip(_ view: RideActionView)
    func cancelTrip()
    func pickupPassenger()
}

enum RideActionViewConfiguration {
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide: return "CONFIRM UBERX"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTIONS"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

class RideActionView: UIView {
    
    var destination: MKPlacemark?{
        didSet{
            titleLabel.text = destination?.name
            addressLabel.text = destination?.address
        }
    }
    var buttonAction = ButtonAction()
    weak var delegate: RideActionViewDelegate?
    var user: User?
    
    var config = RideActionViewConfiguration(){
        didSet{
            configureUI(withConfig: config)
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Caffe"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        view.addSubview(infoViewLabel)
        infoViewLabel.centerX(inView: view)
        infoViewLabel.centerY(inView: view)
        
        return view
    }()
    
    private let infoViewLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .white
        label.text = "X"
        return label
    }()
    
    private let uberInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "UberX"
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchorView(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchorView(top: stack.bottomAnchor, paddingTop: 16)
        infoView.setDimensions(height: 60, width: 60)
        infoView.layer.cornerRadius = 60 / 2
        
        addSubview(uberInfoLabel)
        uberInfoLabel.anchorView(top: infoView.bottomAnchor, paddingTop: 8)
        uberInfoLabel.centerX(inView: self)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        addSubview(separatorView)
        separatorView.anchorView(top: uberInfoLabel.bottomAnchor, left: leftAnchor,
                             right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchorView(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor,
                            right: rightAnchor, paddingLeft: 12, paddingBottom: 12,
                            paddingRight: 12, height: 50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func actionButtonPressed(){
        switch buttonAction{
        case .requestRide:
            delegate?.uploadTrip(self)
        case .cancel:
            delegate?.cancelTrip()
        case .getDirections:
            print("Direction")
        case .pickup:
            delegate?.pickupPassenger()
        case .dropOff:
            print("Drop")
        }
    }
    
    //MARK:: Helper Function
    
    private func configureUI(withConfig config: RideActionViewConfiguration){
        switch config {
            
        case .requestRide:
            buttonAction = .requestRide
            actionButton.setTitle(buttonAction.description, for: .normal)
        case .tripAccepted:
            guard let user = user else{return}
            
            if user.accountType == .passenger{
                titleLabel.text = "En Route to Passenger"
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }else{
                titleLabel.text = "Driver En Route"
                buttonAction = .cancel
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            infoViewLabel.text = String(user.fullname.first ?? "X")
            uberInfoLabel.text = user.fullname
            
            break
        case .driverArrived:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                titleLabel.text = "Driver Has Arrived"
                addressLabel.text = "Please meet driver at pickup location"
            }
            
        case .pickupPassenger:
            titleLabel.text = "Arrived At Passenger Location"
            buttonAction = .pickup
            actionButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripInProgress:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                actionButton.setTitle("TRIP IN PROGRESS", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            titleLabel.text = "En Route To Destination"
            addressLabel.text = ""
            
        case .endTrip:
            guard let user = user else { return }
            
            if user.accountType == .driver {
                actionButton.setTitle("ARRIVED AT DESTINATION", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .dropOff
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            
            titleLabel.text = "Arrived at Destination"
        }
    }
}
