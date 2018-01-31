//
//  WeatherDataManager.swift
//  mindful
//
//  Created by Daniel Moreno on 1/30/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import Foundation
import CoreLocation

struct API {
    static let APIKey = "14a4afea71ccf85a189f14480acebc52"
    static let BaseURL = URL(string: "https://api.darksky.net/forecast/")!
    
    static var AuthenticatedBaseURL : URL {
        return BaseURL.appendingPathComponent(APIKey)
    }
}

struct Defaults {
    static let Latitude: Double = 37.8267
    static let Longitude: Double = -122.423
    
}

enum WeatherDataManagerError : Error {
    case Unknown
    case FailedRequest
    case InvalidResponse
}

final class WeatherDataManager {
    typealias WeatherDataCompletion = (Any?, WeatherDataManagerError?) -> ()
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation!


    let baseURL : URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
        locationManager.requestWhenInUseAuthorization()
    }
    
    func weatherDataForCurrentLocation(completion: @escaping WeatherDataCompletion) {
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locationManager.location
            geocode(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) { placemark, error in
                guard let placemark = placemark, error == nil else { return }
                // you should always update your UI in the main thread
                DispatchQueue.main.async {
                    //  update UI here
                    print("address1:", placemark.thoroughfare ?? "")
                    print("address2:", placemark.subThoroughfare ?? "")
                    print("city:",     placemark.locality ?? "")
                    print("state:",    placemark.administrativeArea ?? "")
                    print("zip code:", placemark.postalCode ?? "")
                    print("country:",  placemark.country ?? "")
                }
            }
        }
        if (currentLocation != nil) {
            let URL = baseURL.appendingPathComponent("\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)")
            URLSession.shared.dataTask(with: URL) {
                (data, response, error) in self.didFetchWeatherData(data:data, response: response, error: error, completion: completion)}.resume()
        }
    }
    
    func weatherDataForLocation(latitude: Double, longitude: Double, completion: @escaping WeatherDataCompletion) {
        
        let URL = baseURL.appendingPathComponent("\(latitude),\(longitude)")
        URLSession.shared.dataTask(with: URL) {
            (data, response, error) in self.didFetchWeatherData(data:data, response: response, error: error, completion: completion)}.resume()
        }
    
    private func didFetchWeatherData(data: Data?, response: URLResponse?, error: Error?, completion: WeatherDataCompletion) {
        if let _ = error {
            completion(nil, .FailedRequest)
            
        } else if let data = data, let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                processWeatherData(data: data, completion: completion)
            } else {
                completion(nil, .FailedRequest)
            }
            
        } else {
            completion(nil, .Unknown)
        }
    }
    func geocode(latitude: Double, longitude: Double, completion: @escaping (CLPlacemark?, Error?) -> ())  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                completion(nil, error)
                return
            }
            completion(placemark, nil)
        }
    }
    private func processWeatherData(data: Data, completion: WeatherDataCompletion) {
        if let JSON = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject {
            completion(JSON, nil)
        } else {
            completion(nil, .InvalidResponse)
        }
    }
}




