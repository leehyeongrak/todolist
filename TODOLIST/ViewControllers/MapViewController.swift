//
//  MapViewController.swift
//  TODOLIST
//
//  Created by RAK on 25/02/2019.
//  Copyright © 2019 RAK. All rights reserved.
//

import UIKit

class MapViewController: UIViewController, MTMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var delegate: SetLocationDelegate?
    
    var searchResult: LocationSearchResult?
    var selectedLocation: Location?
    var currentCoordinate: MTMapPointGeo?
    var currentAddress: String?
    
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var resultPlaceNameLabel: UILabel!
    @IBOutlet var resultAddressNameLabel: UILabel!
    @IBOutlet var resultMapView: MTMapView!
    @IBOutlet var resultsTableView: UITableView!
    
    @IBAction func tappedClosedButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tappedSetButton(_ sender: UIButton) {
        if selectedLocation != nil {
            self.delegate?.setLocation(location: selectedLocation!)
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultMapView.delegate = self
        
        setupOutlets()
    }
    
    func setupOutlets() {
        resultPlaceNameLabel.text = "현위치"
        resultAddressNameLabel.text = currentAddress
        resultMapView.setMapCenter(MTMapPoint(geoCoord: currentCoordinate!), animated: true)
    }
    
    func setupMapView(lattitude: String, longitude: String) {
        resultMapView.baseMapType = .standard
        guard let latitude = Double(lattitude), let longitude = Double(longitude) else { return }
        resultMapView.setMapCenter(MTMapPoint(geoCoord: MTMapPointGeo(latitude: latitude, longitude: longitude)), zoomLevel: 1, animated: true)
        
        let marker = MTMapPOIItem()
        marker.markerType = .redPin
        marker.mapPoint = MTMapPoint(geoCoord: MTMapPointGeo(latitude: latitude, longitude: longitude))
        resultMapView.addPOIItems([marker])
    }
    
    func searchLocation(inputText: String, completion: @escaping (LocationSearchResult) -> ()) {
        let baseURL = "https://dapi.kakao.com/v2/local/search/keyword.json?query=\(inputText)"
        let searchURL = baseURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        guard let url = URL(string: searchURL!) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK 33bbf7d7a5dbc781d5e2c3aa46c21ea6", forHTTPHeaderField: "Authorization")
        
        DispatchQueue.global().async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    return
                }
                guard let searchData = String(data: data!, encoding: .utf8) else {
                    return
                }
                
                if let jsonData = searchData.data(using: .utf8) {
                    let result = try! JSONDecoder().decode(LocationSearchResult.self, from: jsonData)
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            }
            task.resume()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let result = searchResult {
            return result.documents.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath)
        cell.textLabel?.text = searchResult?.documents[indexPath.row].placeName
        cell.detailTextLabel?.text = searchResult?.documents[indexPath.row].addressName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let document = searchResult?.documents[indexPath.row] else { return }
        selectedLocation = Location(place: document.placeName, address: document.addressName, x: document.x, y: document.y)
        
        setupMapView(lattitude: (selectedLocation?.y)!, longitude: (selectedLocation?.x)!)
        resultPlaceNameLabel.text = selectedLocation?.placeName
        resultAddressNameLabel.text = selectedLocation?.roadAddressName
        resultsTableView.isHidden = true
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            resultsTableView.isHidden = false
            searchLocation(inputText: text) { (result) in
                self.searchResult = result
                self.resultsTableView.reloadData()
            }
        }
        
        self.view.endEditing(true)
        return true
    }
}
