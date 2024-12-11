import Foundation

protocol WeatherService {
    func getWeatherForDate(loc: Loc, targetDates: [Date], mode: String) async throws -> [WeatherModel]
}

struct Loc {
    let lat: Double
    let lon: Double
}

struct WeatherModel {
    let weatherType: String
}

struct MetWeatherService: WeatherService {
    private let baseUrl = "https://api.met.no/weatherapi/locationforecast/2.0/compact"
    private let userAgent = "MyApp/1.0 (pabloasens@gmail.com)"

    func getWeatherForDate(loc: Loc, targetDates: [Date], mode: String) async throws -> [WeatherModel] {
        var weatherModels: [WeatherModel] = []
        
        // Realizamos la solicitud de datos UNA sola vez para todas las fechas
        let url = URL(string: "\(baseUrl)?lat=\(loc.lat)&lon=\(loc.lon)")!
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Realizamos la solicitud
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Verificamos si la respuesta es correcta
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "MetWeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch weather data"])
        }

        // Decodificamos los datos recibidos
        let parser = try JSONDecoder().decode(WeatherResponse.self, from: data)
        // Recorremos todas las fechas de targetDates y filtramos los pronósticos correspondientes
        for targetDate in targetDates {
            // Filtramos los pronósticos que coinciden con targetDate
            guard let match = filterForecasts(parser.properties.timeseries, targetDate: targetDate) else {
                throw NSError(domain: "MetWeatherService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No matching forecast found for date \(targetDate)"])
            }
            let weatherModel = try createWeatherModel(from: match, mode: mode)
            weatherModels.append(weatherModel)
        }

        // Devolvemos la lista de WeatherModels
        return weatherModels
    }



    private func filterForecasts(_ timeseries: [TimeSeries], targetDate: Date) -> TimeSeries? {
        // Buscar el pronóstico más cercano
        let closestForecast = timeseries.min { forecast1, forecast2 in
            guard let forecastDate1 = ISO8601DateFormatter().date(from: forecast1.time),
                  let forecastDate2 = ISO8601DateFormatter().date(from: forecast2.time) else {
                return false
            }

            // Calcular la diferencia en tiempo (en segundos) entre el targetDate y los pronósticos
            let diff1 = abs(forecastDate1.timeIntervalSince(targetDate))
            let diff2 = abs(forecastDate2.timeIntervalSince(targetDate))

            return diff1 < diff2
        }
        
        return closestForecast
    }

    private func createWeatherModel(from forecast: TimeSeries, mode: String) throws -> WeatherModel {
        // Intentamos obtener el symbolCode de next_1_hours
        let symbolCode: String?
        if let next1Hours = forecast.data.next_1_hours {
            symbolCode = next1Hours.summary.symbol_code
        } else if let next6Hours = forecast.data.next_6_hours {
            // Si next_1_hours es nil, intentamos next_6_hours
            symbolCode = next6Hours.summary.symbol_code
        } else if let next12Hours = forecast.data.next_12_hours {
            // Si next_6_hours también es nil, intentamos next_12_hours
            symbolCode = next12Hours.summary.symbol_code
        } else {
            // Si todos los intentos fallan, lanzamos un error
            return WeatherModel(weatherType: "")
        }

        guard let weather = WeatherCode(rawValue: symbolCode ?? "") else {
            throw NSError(domain: "WeatherError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid symbol code."])
        }

        return WeatherModel(weatherType: "\(weather.code)_\(mode)")
    }
}

struct WeatherResponse: Codable {
    let properties: Properties
}

struct Properties: Codable {
    let timeseries: [TimeSeries]
}

struct TimeSeries: Codable {
    let time: String
    let data: DataBlock
}

struct DataBlock: Codable {
    let next_1_hours: NextHour?
    let next_6_hours: NextHour?
    let next_12_hours: NextHour?
}

struct NextHour: Codable {
    let summary: NextHourSymbol
}

struct NextHourSymbol: Codable {
    let symbol_code: String?
}

enum WeatherCode: String, CaseIterable{
    case clearsky_day
    case clearsky_night
    case clearsky_polartwilight
    case fair_day
    case fair_night
    case fair_polartwilight
    case partlycloudy_day
    case partlycloudy_night
    case partlycloudy_polartwilight
    case cloudy
    case rainshowers_day
    case rainshowers_night
    case rainshowers_polartwilight
    case rainshowersandthunder_day
    case rainshowersandthunder_night
    case rainshowersandthunder_polartwilight
    case sleetshowers_day
    case sleetshowers_night
    case sleetshowers_polartwilight
    case snowshowers_day
    case snowshowers_night
    case snowshowers_polartwilight
    case rain
    case heavyrain
    case heavyrainandthunder
    case sleet
    case snow
    case snowandthunder
    case fog
    case sleetshowersandthunder_day
    case sleetshowersandthunder_night
    case sleetshowersandthunder_polartwilight
    case snowshowersandthunder_day
    case snowshowersandthunder_night
    case snowshowersandthunder_polartwilight
    case rainandthunder
    case sleetandthunder
    case lightrainshowersandthunder_day
    case lightrainshowersandthunder_night
    case lightrainshowersandthunder_polartwilight
    case heavyrainshowersandthunder_day
    case heavyrainshowersandthunder_night
    case heavyrainshowersandthunder_polartwilight
    case lightssleetshowersandthunder_day
    case lightssleetshowersandthunder_night
    case lightssleetshowersandthunder_polartwilight
    case heavysleetshowersandthunder_day
    case heavysleetshowersandthunder_night
    case heavysleetshowersandthunder_polartwilight
    case lightssnowshowersandthunder_day
    case lightssnowshowersandthunder_night
    case lightssnowshowersandthunder_polartwilight
    case heavysnowshowersandthunder_day
    case heavysnowshowersandthunder_night
    case heavysnowshowersandthunder_polartwilight
    case lightrainandthunder
    case lightsleetandthunder
    case heavysleetandthunder
    case lightsnowandthunder
    case heavysnowandthunder
    case lightrainshowers_day
    case lightrainshowers_night
    case lightrainshowers_polartwilight
    case heavyrainshowers_day
    case heavyrainshowers_night
    case heavyrainshowers_polartwilight
    case lightsleetshowers_day
    case lightsleetshowers_night
    case lightsleetshowers_polartwilight
    case heavysleetshowers_day
    case heavysleetshowers_night
    case heavysleetshowers_polartwilight
    case lightsnowshowers_day
    case lightsnowshowers_night
    case lightsnowshowers_polartwilight
    case heavysnowshowers_day
    case heavysnowshowers_night
    case heavysnowshowers_polartwilight
    case lightrain
    case lightsleet
    case heavysleet
    case lightsnow
    case heavysnow

    // Propiedad calculada para devolver el código
    var code: String {
        switch self {
        case .clearsky_day:
            return "01d"
        case .clearsky_night:
            return "01n"
        case .clearsky_polartwilight:
            return "01m"
        case .fair_day:
            return "02d"
        case .fair_night:
            return "02n"
        case .fair_polartwilight:
            return "02m"
        case .partlycloudy_day:
            return "03d"
        case .partlycloudy_night:
            return "03n"
        case .partlycloudy_polartwilight:
            return "03m"
        case .cloudy:
            return "04"
        case .rainshowers_day:
            return "05d"
        case .rainshowers_night:
            return "05n"
        case .rainshowers_polartwilight:
            return "05m"
        case .rainshowersandthunder_day:
            return "06d"
        case .rainshowersandthunder_night:
            return "06n"
        case .rainshowersandthunder_polartwilight:
            return "06m"
        case .sleetshowers_day:
            return "07d"
        case .sleetshowers_night:
            return "07n"
        case .sleetshowers_polartwilight:
            return "07m"
        case .snowshowers_day:
            return "08d"
        case .snowshowers_night:
            return "08n"
        case .snowshowers_polartwilight:
            return "08m"
        case .rain:
            return "09"
        case .heavyrain:
            return "10"
        case .heavyrainandthunder:
            return "11"
        case .sleet:
            return "12"
        case .snow:
            return "13"
        case .snowandthunder:
            return "14"
        case .fog:
            return "15"
        case .sleetshowersandthunder_day:
            return "20d"
        case .sleetshowersandthunder_night:
            return "20n"
        case .sleetshowersandthunder_polartwilight:
            return "20m"
        case .snowshowersandthunder_day:
            return "21d"
        case .snowshowersandthunder_night:
            return "21n"
        case .snowshowersandthunder_polartwilight:
            return "21m"
        case .rainandthunder:
            return "22"
        case .sleetandthunder:
            return "23"
        case .lightrainshowersandthunder_day:
            return "24d"
        case .lightrainshowersandthunder_night:
            return "24n"
        case .lightrainshowersandthunder_polartwilight:
            return "24m"
        case .heavyrainshowersandthunder_day:
            return "25d"
        case .heavyrainshowersandthunder_night:
            return "25n"
        case .heavyrainshowersandthunder_polartwilight:
            return "25m"
        case .lightssleetshowersandthunder_day:
            return "26d"
        case .lightssleetshowersandthunder_night:
            return "26n"
        case .lightssleetshowersandthunder_polartwilight:
            return "26m"
        case .heavysleetshowersandthunder_day:
            return "27d"
        case .heavysleetshowersandthunder_night:
            return "27n"
        case .heavysleetshowersandthunder_polartwilight:
            return "27m"
        case .lightssnowshowersandthunder_day:
            return "28d"
        case .lightssnowshowersandthunder_night:
            return "28n"
        case .lightssnowshowersandthunder_polartwilight:
            return "28m"
        case .heavysnowshowersandthunder_day:
            return "29d"
        case .heavysnowshowersandthunder_night:
            return "29n"
        case .heavysnowshowersandthunder_polartwilight:
            return "29m"
        case .lightrainandthunder:
            return "30"
        case .lightsleetandthunder:
            return "31"
        case .heavysleetandthunder:
            return "32"
        case .lightsnowandthunder:
            return "33"
        case .heavysnowandthunder:
            return "34"
        case .lightrainshowers_day:
            return "40d"
        case .lightrainshowers_night:
            return "40n"
        case .lightrainshowers_polartwilight:
            return "40m"
        case .heavyrainshowers_day:
            return "41d"
        case .heavyrainshowers_night:
            return "41n"
        case .heavyrainshowers_polartwilight:
            return "41m"
        case .lightsleetshowers_day:
            return "42d"
        case .lightsleetshowers_night:
            return "42n"
        case .lightsleetshowers_polartwilight:
            return "42m"
        case .heavysleetshowers_day:
            return "43d"
        case .heavysleetshowers_night:
            return "43n"
        case .heavysleetshowers_polartwilight:
            return "43m"
        case .lightsnowshowers_day:
            return "44d"
        case .lightsnowshowers_night:
            return "44n"
        case .lightsnowshowers_polartwilight:
            return "44m"
        case .heavysnowshowers_day:
            return "45d"
        case .heavysnowshowers_night:
            return "45n"
        case .heavysnowshowers_polartwilight:
            return "45m"
        case .lightrain:
            return "46"
        case .lightsleet:
            return "47"
        case .heavysleet:
            return "48"
        case .lightsnow:
            return "49"
        case .heavysnow:
            return "50"
        }
    }
}
