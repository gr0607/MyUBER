//
//  HomeController.swift
//  MyUBER
//
//  Created by admin on 14.06.2022.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "Location Cell"
private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView

    init() {
        self = .showMenu
    }
}

class HomeController: UIViewController {

    //MARK: - Properties

    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager

    private let inputActivationView = LocationInputActivationView()
    private let rideActionView = RideActionView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?

    private var user: User? {
        didSet {
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            } else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user = user else { return }

            if user.accountType == .driver {
                guard let trip = trip else { return }
                let controller = PickupController(trip: trip)
                controller.modalPresentationStyle = .fullScreen
                controller.delegate = self
                self.present(controller, animated: true, completion: nil)
            } else {
                print("DEBUG: show ride action view for accepret trip")
            }

        }
    }

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
      //  signOut()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let trip = trip else { return}
        print("DEBUG: trip state is \(trip.state)")
    }

    //MARK: - Selectors

    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            print("DEBUG: show meny")
        case .dismissActionView:
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)

            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }

    //MARK: - API

    func observeCurrentTrip() {
        Service.shared.observeCurrentTrip { trip in
            self.trip = trip
            guard let state = trip.state else { return }
            guard let driverUid = trip.driverUid else { return }

            switch state {
            case .requested:
                break

            case .accepted:
                self.shouldPresentLoadingView(false)
                self.removeAnnotationsAndOverlays()
                self.zoomForActiveTrip(withDriveUid: driverUid)

                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }

            case .driverArrived:
                self.rideActionView.config = .driverArrived

            case .inProgress:
                break
            case .completed:
                break
            }


        }
    }
    
    func fetchDrivers() {
        guard let location = locationManager?.location else { return }

        Service.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)


            var driverIsVisible: Bool {
                return self.mapView.annotations.contains { annotation in
                    guard let driverAnno = annotation as? DriverAnnotation else { return false}
                    if driverAnno.uid == driver.uid {
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        self.zoomForActiveTrip(withDriveUid: driver.uid)
                        return true
                    }
                    return false
                }
            }

            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }

    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData (uid: currentUid) { user in
            self.user = user
        }
    }

    func observeTrips() {
        Service.shared.observeTrips { trip in
            self.trip = trip
        }
    }

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }

        } else {
            configure()
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            }
        } catch {
            print("DEBUG: Error signing out")
        }
    }

    //MARK: - Helpers

    func configure() {
        configureUI()
        fetchUserData()
    }

    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }

    func configureUI() {
        configureMapView()
        configureRideActionView()

        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)




        configureTableVIew()
    }

    func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop:  32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self

        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }

    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame

        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }

    func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0


        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }

    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }

    func configureTableVIew() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()

        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)

        view.addSubview(tableView)
    }

    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations:  {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
            }, completion: completion)
    }

    func animateRideActionView(shouldShow: Bool,
                               destination: MKPlacemark? = nil,
                               config: RideActionViewConfiguration? = nil,
                               user: User? = nil) {
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height

        UIView.animate(withDuration: 0.4) {
            self.rideActionView.frame.origin.y = yOrigin
        }

        if shouldShow {
            guard let config = config else { return }

            if let destination = destination {
                rideActionView.destination = destination
            }

            if let user = user {
                rideActionView.user = user
            }

            rideActionView.config = config
        }
    }
}

//MARK: - MapView Helper Functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping ([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()

        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }

            response.mapItems.forEach { item in
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
        directionRequest.calculate { response, error in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }

    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }

        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }

    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }

    func setCustomRegion(withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: "pickup")
        locationManager?.startMonitoring(for: region)
    }

    func zoomForActiveTrip(withDriveUid uid: String) {
        var annotations = [MKAnnotation]()

        self.mapView.annotations.forEach { annotation in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }

            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }

        self.mapView.zoomToFit(annotations: annotations)
    }
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else { return }
        guard  user.accountType == .driver else { return }
        guard let location = userLocation.location  else { return }
        Service.shared.updateDriverLocation(location: location)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
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

//MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate{

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("DEBUG: did start monitoring for region \(region)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("DEBUG: Driver did enter passenger region")

        self.rideActionView.config = .pickupPassenger
        guard let trip = self.trip else { return }
        Service.shared.updateTripState(trip: trip, state: .driverArrived)
    }

    func enableLocationServices() {
        locationManager?.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            print("DEBUG: not determined")
            locationManager!.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth, always")
            locationManager!.startUpdatingLocation()
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Auth when in use")
            locationManager!.requestAlwaysAuthorization()
        @unknown default:
           break
        }
    }
}

//MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

//MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }

    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5,animations: {
                self.inputActivationView.alpha = 1
            })
        }
    }
}

//MARK: - TableViewDelegate TableViewDataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
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

        if indexPath.section == 1 {
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
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)

            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
            self.mapView.zoomToFit(annotations: annotations)

            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)

        }
    }
}

//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }

        shouldPresentLoadingView(true, message: "Finding you a ride")

        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { err, ref in
            if let error = err {
                print("DEBUG: failed to upload tipn with \(error.localizedDescription)")
                return
            }

            UIView.animate(withDuration: 0.3, animations: {
                self.rideActionView.frame.origin.y = self.view.frame.height
            })
        }
    }

    func cancelTrip() {
        Service.shared.cancelTrip { error, ref in
            if let error = error {
                print("DEBUG: ERROR deleting trip \(error.localizedDescription)")
                return
            }

            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()

            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu

            self.inputActivationView.alpha = 1
        }
    }
}

//MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        let anno = MKPointAnnotation()
        anno.coordinate = trip.pickupCoordinates
        mapView.addAnnotation(anno)
        mapView.selectAnnotation(anno, animated: true)

        setCustomRegion(withCoordinates: trip.pickupCoordinates)

        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)

        mapView.zoomToFit(annotations: mapView.annotations)

        Service.shared.observeTripCancel(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlertController(withTitle: "Oops!" ,withMessage: "The passenger has cancelled this trip")
        }

        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid, completion: { passenger in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            })
        }
    }
}
