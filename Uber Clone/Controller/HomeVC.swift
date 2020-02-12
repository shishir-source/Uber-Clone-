//
//  HomeVC.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 16/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "reuseIdentifier"
private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfiguration{
    case showMenu
    case dismissActionView
    
    init(){
        self = .showMenu
    }
}

class HomeVC: UIViewController {
    
    //MARK:: Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private final let locationInputViewHeight: CGFloat = 160
    private final let rideActionViewHeight: CGFloat = 300
    private var actionbuttonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    private var user: User?{
        didSet{
            locationInputView.user = user
            if user?.accountType == .passenger{
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            }else{
                observeTrip()
            }
        }
    }
    
    private var trip: Trip?{
        didSet{
            guard let user = user else{return}
            
            if user.accountType == .driver{
                guard let trip = trip else{return}
                let controller = PickUpVC(trip: trip)
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            }else{
                
            }
            
        }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressd), for: .touchUpInside)
        return button
    }()
    
    //MARK:: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationService()
        signOut()
        //Looks for single or multiple taps.
        let keyTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(keyTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let trip = trip else{return}
        
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //MARK:: Selectors
    
    @objc func actionButtonPressd(){
        switch actionbuttonConfig{
        case .showMenu:
            print("Debug Show")
        case .dismissActionView:
            removeAnnotattionAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    
    //MARK:: API
    
    func fetchUserData(){
        guard let currentUid = Auth.auth().currentUser?.uid else {
            return
        }
        Service.shared.fetchUserData(uid: currentUid, completion:  { (user) in
            self.user = user
        })
    }
    
    func fetchDrivers(){
        guard let location = locationManager?.location else{return}
        Service.shared.fetchDrivers(location: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else {return}
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            var driverIsVisible: Bool{
                return self.mapView.annotations.contains { (annotation) -> Bool in
                    guard let driverAnno = annotation as? DriverAnnotation else {return false}
                    if driverAnno.uid == driver.uid{
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        self.zoomForActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                }
            }
            if !driverIsVisible{
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func checkIfUserIsLoggedIn(){
        if Auth.auth().currentUser?.uid == nil{
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginVC() )
                self.present(nav, animated: true, completion: nil)
            }
        }else{
            configure()
        }
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut()
        }catch{
            print("Error SignOut")
        }
    }
    
    func observeTrip(){
        Service.shared.overveTrips { (trip) in
            self.trip = trip
        }
    }
    
    func observeCurrentTrip(){
        Service.shared.observeCurrentTrip { (trip) in
            self.trip = trip
            guard let state = trip.state else{return}
            guard let driverUid = trip.driverUid else{return}
        
            switch state{
                
            case .requested:
                break
            case .denied:
                break
            case .accepted:
                self.shouldPresentLoadingView(false)
                self.removeAnnotattionAndOverlays()
                self.zoomForActiveTrip(withDriverUid: driverUid)
                Service.shared.fetchUserData(uid: driverUid) { (driver) in
                    self.animateRideActionView(shouldShow: true,  config: .tripAccepted, user: driver)
                }
                
            case .driverArrived:
                self.rideActionView.config = .driverArrived
            case .inProgress:
                self.rideActionView.config = .tripInProgress
            case .arrivedAtDestination:
                break
            case .completed:
                break
            }
            
            if self.trip?.state == .accepted{
                
            }
        }
    }
    
    func startTrip(){
        guard let trip = self.trip else{return}
        Service.shared.updateTripState(trip: trip, state: .inProgress) { (error, reff) in
            self.rideActionView.config = .tripInProgress
            self.removeAnnotattionAndOverlays()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let placeMark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placeMark)
            self.generatePolyline(toDestination: mapItem)
        }
    }
    
    //MARK:: Helper Functions
    
    func configure(){
        configureUI()
        fetchUserData()
    }
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration){
        switch config{
        case .showMenu:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            actionbuttonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            actionbuttonConfig = .dismissActionView
        }
    }
    
    func configureUI(){
        configureMapView()
        configureRiderActionView()
        
        view.addSubview(actionButton)
        actionButton.anchorView(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 39)
        
        configureTableView()
    }
    
    func configureLocationInputActivationView(){
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchorView(top: actionButton.bottomAnchor, paddingTop: 16)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
           self.inputActivationView.alpha = 1
       }
    }
    
    func configureMapView(){
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.delegate = self
    }
    
    func configureLocationInputView(){
        view.addSubview(locationInputView)
        
        locationInputView.anchorView(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        locationInputView.delegate = self
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight + 25
            }
        }
    }
    
    func configureRiderActionView(){
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView(){
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight - 30
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil){
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        if shouldShow{
            guard let config = config else{return}
            
            if let destination = destination{
                rideActionView.destination = destination
            }
            if let user = user{
                rideActionView.user = user
            }
            
            rideActionView.config = config
        }
    }
}

//MARK:: MAP Helper Function

private extension HomeVC{
    func searchBy( naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void){
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else{return}
            
            response.mapItems.forEach { (item) in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    
    func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, error) in
            guard let responsed = response else { return }
            self.route = responsed.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotattionAndOverlays(){
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation{
                self.mapView.removeAnnotation(anno)
            }
        }
        
        if mapView.overlays.count > 0{
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    func dismissLocationView( completion: ((Bool) -> Void )?  = nil){

        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()

        }, completion: completion)
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withCoordinates coordinates: CLLocationCoordinate2D){
        let region = CLCircularRegion(center: coordinates, radius: 100, identifier: "driver")
        locationManager?.startMonitoring(for: region)
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? DriverAnnotation{
                if anno.uid == uid{
                    annotations.append(annotation)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation{
                annotations.append(userAnno)
            }
        }
        self.mapView.zoomToFit(annotations: annotations)
    }
}

//MARK:: MKMAPViewDelegate

extension HomeVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else{return}
        guard user.accountType == .driver else{return}
        guard let location = userLocation.location else{return}
        Service.shared.updateDriverLocation(location: location)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "bike")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}

//MARK:: Location Seriveces Delegates

extension HomeVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("DEBUG: Start Monitoring \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.rideActionView.config = .pickupPassenger
        guard let trip = self.trip else{return}
        Service.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
            self.rideActionView.config = .pickupPassenger
        }
    }
    
    func enableLocationService(){
        
        locationManager?.delegate = self
        
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            locationManager?.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        @unknown default:
            break
        }
    }
}

extension HomeVC: LocationInputActivationViewDelegate{
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

//MARK:: InputLocationView Deleagte

extension HomeVC: LocationInputViewDelegate{

    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

//MARK:: UITableViewDataSource/delegate

extension HomeVC: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Test"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        
        if indexPath.section == 1{
            cell.placemark = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        configureActionButton(config: .dismissActionView)
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        dismissLocationView { _ in
            
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            let annotaions = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) })
            self.mapView.zoomToFit(annotations: annotaions)
            
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
    
}

//MARK:: RideActionViewDelegate

extension HomeVC: RideActionViewDelegate{

    func uploadTrip(_ view: RideActionView) {
        guard let pickUpCoordinates = locationManager?.location?.coordinate else{return}
        guard let destinationCoordinates = view.destination?.coordinate else{return}
        
        shouldPresentLoadingView(true, message: "Finding you a ride..")
        
        Service.shared.uploadTrip(pickUpCoordinates, destinationCoordinates) { (err, ref) in
            if let error = err{
                print("DEBUG: Failed to upload Trip \(error)")
            }
            
            print("DEBUG: Trip Upload Successfully")
        }
    }
    
    func cancelTrip() {
        Service.shared.deleteTrip { (error, reff) in
            if let error = error{
                print("DEBUG: Cancel Trip Error \(error)")
                return
            }
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotattionAndOverlays()
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionbuttonConfig = .showMenu
            self.inputActivationView.alpha = 1
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
}

//MARK:: PickUpVCDelegate

extension HomeVC: PickUpVCDelegate{
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickUpCoordinates)
        
        setCustomRegion(withCoordinates: trip.pickUpCoordinates)
        
        let placeMark = MKPlacemark(coordinate: trip.pickUpCoordinates)
        let mapItem = MKMapItem(placemark: placeMark)
        generatePolyline(toDestination: mapItem)
        mapView.zoomToFit(annotations: mapView.annotations)
        
        Service.shared.observeTripCancelled(trip: trip) {
            self.removeAnnotattionAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlertController( withTitle: "Cancel", message: "The passenger has cancelled the trip.")
        }
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { (passenger) in
                self.animateRideActionView(shouldShow: true,  config: .tripAccepted, user: passenger)
            }
        }
    }
}
