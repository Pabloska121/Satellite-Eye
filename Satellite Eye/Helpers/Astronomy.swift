import Foundation
import Darwin

let F = 1 / 298.257223563  // Flattening de la Tierra (WGS-84)
let A = 6378.137  // Radio ecuatorial de la Tierra (WGS-84)
let MFACTOR = 7.292115E-5  // Factor de la rotación de la Tierra

func jdays2000(utcTime: Date) -> Double {
    // Obtener los días desde el año 2000
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(abbreviation: "UTC")!
    let refDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 12))!
    let timeInterval = utcTime.timeIntervalSince(refDate)
    return _days(dt: timeInterval)
}

func jdays(fecha: Date) -> Double {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(abbreviation: "UTC")!
    let year = Double(calendar.component(.year, from: fecha))
    let month = Double(calendar.component(.month, from: fecha))
    let day = Double(calendar.component(.day, from: fecha))
    let hour = Double(calendar.component(.hour, from: fecha))
    let minute = Double(calendar.component(.minute, from: fecha))
    let second = Double(calendar.component(.second, from: fecha))
    // Cálculo de la fecha juliana
    let a = floor((14 - month) / 12)
    let y = year + 4800 - a
    let m = month + 12 * a - 3
    let julianDate = day + floor((153 * m + 2) / 5) + 365 * y + floor(y / 4) - floor(y / 100) + floor(y / 400) - 32045 + (hour - 12) / 24 + minute / 1440 + second / 86400

    return julianDate
}


func _days(dt: TimeInterval) -> Double {
    // Obtener los días en punto flotante de dt
    return dt / 86400.0
}

func gmst(utcTime: Date) -> Double {
    // Greenwich Mean Sidereal Time (GMST)
    let ut1 = jdays2000(utcTime: utcTime) / 36525.0
    let theta = 67310.54841 + ut1 * (876600 * 3600 + 8640184.812866 + ut1 * (0.093104 - ut1 * 6.2 * 10e-6))
    return (theta / 240.0 * .pi / 180).truncatingRemainder(dividingBy: 2 * .pi)
}

func _lmst(utcTime: Date, longitude: Double) -> Double {
    // Local Mean Sidereal Time (LMST)
    return gmst(utcTime: utcTime) + longitude
}

func sunEclipticLongitude(utcTime: Date) -> Double {
    // Longitud eclíptica del Sol
    let jdate = jdays2000(utcTime: utcTime) / 36525.0
    let mA = (357.52910 + 35999.05030 * jdate - 0.0001559 * pow(jdate, 2) - 0.00000048 * pow(jdate, 3)) * .pi / 180
    let l0 = (280.46645 + 36000.76983 * jdate + 0.0003032 * pow(jdate, 2))
    let dL = (1.914600 - 0.004817 * jdate - 0.000014 * pow(jdate, 2)) * sin(mA) +
             (0.019993 - 0.000101 * jdate) * sin(2 * mA) + 0.000290 * sin(3 * mA)
    let l = l0 + dL
    return l * .pi / 180
}

func sunRaDec(utcTime: Date) -> (Double, Double) {
    // Ascensión recta y declinación del sol
    let jdate = jdays2000(utcTime: utcTime) / 36525.0
    let eps = (23.0 + 26.0 / 60.0 + 21.448 / 3600.0 - (46.8150 * jdate + 0.00059 * pow(jdate, 2) -
        0.001813 * pow(jdate, 3)) / 3600.0) * .pi / 180
    let eclon = sunEclipticLongitude(utcTime: utcTime)
    let x = cos(eclon)
    let y = cos(eps) * sin(eclon)
    let z = sin(eps) * sin(eclon)
    let r = sqrt(1.0 - z * z)
    let declination = atan2(z, r)
    let rightAscension = 2 * atan2(y, x + r)
    return (rightAscension, declination)
}

func _localHourAngle(utcTime: Date, longitude: Double, rightAscension: Double) -> Double {
    // Hora local del ángulo
    return _lmst(utcTime: utcTime, longitude: longitude) - rightAscension
}

func getAltAz(utcTime: Date, lon: Double, lat: Double) -> (Double, Double) {
    // Obtener la altitud y azimut del sol
    let raDec = sunRaDec(utcTime: utcTime)
    let ra = raDec.0
    let dec = raDec.1
    let lonRad = lon * .pi / 180
    let latRad = lat * .pi / 180
    let h = _localHourAngle(utcTime: utcTime, longitude: lonRad, rightAscension: ra)
    let alt = asin(sin(latRad) * sin(dec) + cos(latRad) * cos(dec) * cos(h))
    let az = atan2(-sin(h), cos(latRad) * tan(dec) - sin(latRad) * cos(h))
    return (alt, az)
}

func cosZen(utcTime: Date, lon: Double, lat: Double) -> Double {
    // Coseno del ángulo cenital del sol
    let raDec = sunRaDec(utcTime: utcTime)
    let ra = raDec.0
    let dec = raDec.1
    let lonRad = lon * .pi / 180
    let latRad = lat * .pi / 180
    let h = _localHourAngle(utcTime: utcTime, longitude: lonRad, rightAscension: ra)
    return sin(latRad) * sin(dec) + cos(latRad) * cos(dec) * cos(h)
}

func sunZenithAngle(utcTime: Date, lon: Double, lat: Double) -> Double {
    // Ángulo cenital del sol
    let cosZenValue = cosZen(utcTime: utcTime, lon: lon, lat: lat)
    return acos(cosZenValue) * 180 / .pi
}

func sunEarthDistanceCorrection(utcTime: Date) -> Double {
    // Correción de la distancia Tierra-Sol
    let corr = 1 - 0.0167 * cos(2 * .pi * (jdays2000(utcTime: utcTime) - 3) / 365.25636)
    return corr
}

func observerPosition(utcTime: Date, lon: Double, lat: Double, alt: Double) -> ((Double, Double, Double), (Double, Double, Double)) {
    // Calcular la posición ECI del observador
    let lonRad = lon * .pi / 180
    let latRad = lat * .pi / 180
    let theta = (gmst(utcTime: utcTime) + lonRad).truncatingRemainder(dividingBy: 2 * .pi)
    let c = 1 / sqrt(1 + F * (F - 2) * pow(sin(latRad), 2))
    let sq = c * pow(1 - F, 2)
    let achcp = (A * c + alt) * cos(latRad)
    let x = achcp * cos(theta)
    let y = achcp * sin(theta)
    let z = (A * sq + alt) * sin(latRad)
    let vx = -MFACTOR * y
    let vy = MFACTOR * x
    let vz = 0.0

    return ((x, y, z), (vx, vy, vz))
}
