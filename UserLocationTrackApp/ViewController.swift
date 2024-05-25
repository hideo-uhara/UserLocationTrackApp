//
// ViewController.swift
//

import MapKit
import UIKit

class ViewController: UIViewController {
	var locationManager: CLLocationManager! = nil
	var locList: [CLLocationCoordinate2D] = []
	var polyline: MKPolyline! = nil
	
	@IBOutlet var mapView: MKMapView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.mapView.delegate = self
		self.mapView.showsUserLocation = true
		self.mapView.showsScale = true
		
		self.locationManager = CLLocationManager()
		self.locationManager.delegate = self // locationManagerDidChangeAuthorizationが呼び出される
		
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		self.locationManager.distanceFilter = kCLDistanceFilterNone
		self.locationManager.allowsBackgroundLocationUpdates = true
		self.locationManager.activityType = .other
		self.locationManager.pausesLocationUpdatesAutomatically = false
		
	}
	
	func showDialog(title: String = NSLocalizedString("Confirmation", comment: ""), message: String, actions: [UIAlertAction]? = nil) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		if let actions = actions {
			for action in actions {
				alertController.addAction(action)
			}
			
		} else {
			let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) { (action) in
			}
			alertController.addAction(defaultAction)
		}
		
		self.present(alertController, animated: true, completion: nil)
	}

}

extension ViewController: CLLocationManagerDelegate {
	
	// 設定アプリにあるこのアプリの設定の変更でもコールされる
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		
		switch manager.authorizationStatus {
		case .notDetermined:
			self.locationManager.requestWhenInUseAuthorization() // 位置情報取得の許可ダイアログ表示
		case .denied:
			let defaultAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (action) in
				
				// ローカライズファイルがあれば設定アプリにこのアプリの設定が表示される。(たぶん、言語の切り替え設定のため)
				UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
			}
			self.showDialog(message: NSLocalizedString("Please enable location service settings.", comment: ""), actions: [defaultAction])
		case .restricted:
			self.showDialog(message: NSLocalizedString("Location services are unavailable.", comment: ""))
		case .authorizedAlways:
			fallthrough
		case .authorizedWhenInUse:
			switch manager.accuracyAuthorization {
			case .reducedAccuracy: // 位置情報取得許可ダイアログで取得可で正確な位置情報がオフの場合
				// 正確な位置情報利用の許可確認
				manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "NSLocationTemporaryUsageDescription") { error in
					
					if error != nil {
						NSLog(error!.localizedDescription)
						return
					}
					
					if manager.accuracyAuthorization == .reducedAccuracy {
						let defaultAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (action) in
							
							UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
						}
						self.showDialog(message: NSLocalizedString("This app need precise location information.", comment: ""), actions: [defaultAction])
					}
				}
			case .fullAccuracy:
				self.locationManager.startUpdatingLocation()
				self.mapView.setUserTrackingMode(.followWithHeading, animated: true)
			default:
				break
			}
		default:
			break
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		if let location: CLLocation = locations.last { // 最後の位置データが最新
			
			if location.horizontalAccuracy < 0.0 { // データ不正の場合
				return
			}
			
			self.locList.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
			
			// 軌跡の表示
			if self.polyline != nil {
				self.mapView.removeOverlay(self.polyline)
			}
			self.polyline = MKPolyline(coordinates: self.locList, count: self.locList.count)
			self.mapView.insertOverlay(self.polyline, at: 0)
		}
	}
}

extension ViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		
		if let polyline: MKPolyline = overlay as? MKPolyline {
			let polylineRenderer: MKPolylineRenderer = MKPolylineRenderer(polyline: polyline)
			
			polylineRenderer.strokeColor = .blue
			polylineRenderer.lineWidth = 2.0
			
			return polylineRenderer
		}
		
		return MKOverlayRenderer()
	}
	
}
