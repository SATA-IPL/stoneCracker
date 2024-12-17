import Foundation
import Network

class NetworkService {
    static let shared = NetworkService()
    private let monitor = NWPathMonitor()
    private var isNetworkAvailable = false
    
    #if targetEnvironment(simulator)
    private let serverURL = "http://192.168.1.218:5001/health-data"
    #else
    private let serverURL = "http://192.168.1.218:5001/health-data"
    #endif
    
    private let maxRetries = 3
    
    init() {
        print("Using server URL: \(serverURL)")
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        // Create a custom queue for monitoring
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        // Use parameters that match your local network
        let parameters = NWParameters()
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                print("Network status updated: \(path.status)")
                print("Available interfaces: \(path.availableInterfaces)")
                print("Is expensive: \(path.isExpensive)")
                print("Is constrained: \(path.isConstrained)")
                
                if path.usesInterfaceType(.wifi) {
                    print("Using WiFi interface")
                    self?.isNetworkAvailable = true
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func sendHealthData(heartRate: Double?, spo2: Double?, calories: Double?, distance: Double?, hrv: Double?, vo2Max: Double?, latitude: Double? = nil, longitude: Double? = nil) {
        guard isNetworkAvailable else {
            print("No network connection available")
            return
        }
        sendDataWithRetry(heartRate: heartRate, spo2: spo2, calories: calories, distance: distance, hrv: hrv, vo2Max: vo2Max, latitude: latitude, longitude: longitude, retryCount: 0)
    }
    
    private func sendDataWithRetry(heartRate: Double?, spo2: Double?, calories: Double?, distance: Double?, hrv: Double?, vo2Max: Double?, latitude: Double?, longitude: Double?, retryCount: Int) {
        var dataDict: [String: Any] = [
            "timestamp": Date().ISO8601Format()
        ]
        
        // Only include non-nil values
        if let heartRate = heartRate { dataDict["heart_rate"] = heartRate }
        if let spo2 = spo2 { dataDict["spo2"] = spo2 }
        if let calories = calories { dataDict["calories"] = calories }
        if let distance = distance { dataDict["distance"] = distance }
        if let hrv = hrv { dataDict["hrv"] = hrv }
        if let vo2Max = vo2Max { dataDict["vo2_max"] = vo2Max }
        if let latitude = latitude { dataDict["latitude"] = latitude }
        if let longitude = longitude { dataDict["longitude"] = longitude }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dataDict) else {
            print("Error: Cannot create JSON")
            return
        }
        
        guard let url = URL(string: serverURL) else {
            print("Error: Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 10 // Shorter timeout for local development
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error sending data: \(error.localizedDescription)")
                
                // Retry with shorter delays for local development
                if retryCount < self?.maxRetries ?? 3 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                        print("Retrying... Attempt \(retryCount + 1)")
                        self?.sendDataWithRetry(
                            heartRate: heartRate,
                            spo2: spo2,
                            calories: calories,
                            distance: distance,
                            hrv: hrv,
                            vo2Max: vo2Max,
                            latitude: latitude,
                            longitude: longitude,
                            retryCount: retryCount + 1
                        )
                    }
                }
                return
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Server response data: \(responseString)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Server response code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    print("Data sent successfully")
                default:
                    print("Unexpected status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}
