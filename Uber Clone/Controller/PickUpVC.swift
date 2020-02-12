//
//  PickUpVC.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 23/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import MapKit

protocol PickUpVCDelegate: class {
    func didAcceptTrip(_ trip: Trip)
}

class PickUpVC: UIViewController {
    
    private let mapView = MKMapView()
    let trip: Trip
    weak var delegate: PickUpVCDelegate?
    // MARK: - Properties
    
    private lazy var circularProgressView: CircularProgressView = {
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let cp = CircularProgressView(frame: frame)

        cp.addSubview(mapView)
        mapView.setDimensions(height: 268, width: 268)
        mapView.layer.cornerRadius = 268 / 2
        mapView.centerX(inView: cp)
        mapView.centerY(inView: cp, constant: 32)

        return cp
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
        return button
    }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "Would you like to pickup this passsenger?"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    private let acceptTripButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
        button.backgroundColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.black, for: .normal)
        button.setTitle("ACCEPT TRIP", for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
        configureUI()
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    //MARK:: Selectors
    
    @objc func handleDismissal(){
        
    }
    
    @objc func handleAcceptTrip(){
        Service.shared.acceptTrip(trip: trip) { (error, reff) in
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
    
    // MARK: - API
     
    // MARK: - Helper Functions
     
     func configureMapView() {
         let region = MKCoordinateRegion(center: trip.pickUpCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
         mapView.setRegion(region, animated: false)
         mapView.addAnnotationAndSelect(forCoordinate: trip.pickUpCoordinates)
     }
     
     func configureUI() {
         view.backgroundColor = .backgroundColor
         
         view.addSubview(cancelButton)
         cancelButton.anchorView(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                             paddingLeft: 16)
         
         view.addSubview(circularProgressView)
         circularProgressView.setDimensions(height: 360, width: 360)
         circularProgressView.anchorView(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
         circularProgressView.centerX(inView: view)
         
         view.addSubview(pickupLabel)
         pickupLabel.centerX(inView: view)
         pickupLabel.anchorView(top: circularProgressView.bottomAnchor, paddingTop: 32)
         
         view.addSubview(acceptTripButton)
         acceptTripButton.anchorView(top: pickupLabel.bottomAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, paddingTop: 16, paddingLeft: 32,
                                 paddingRight: 32, height: 50)
         
         
     }
}
