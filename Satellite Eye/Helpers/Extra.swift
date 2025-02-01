import Foundation

class Extra {
    
    // Función para calcular la magnitud de un vector (representado como una tupla de 3 componentes)
    static func magnitude(of vector: (x: Double, y: Double, z: Double)) -> Double {
        return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
    
    static func cross(v1: (x: Double, y: Double, z: Double), v2: (x: Double, y: Double, z: Double)) -> (x: Double, y: Double, z: Double) {
        let vx = v1.y * v2.z - v1.z * v2.y
        let vy = v1.z * v2.x - v1.x * v2.z
        let vz = v1.x * v2.y - v1.y * v2.x
                
        return (x: vx, y: vy, z: vz) // Devolvemos el vector cruzado
    }
    
    // Función para calcular el producto punto entre dos vectores (tuplas de 3 componentes)
    static func dotProduct(of v1: (x: Double, y: Double, z: Double),
                           and v2: (x: Double, y: Double, z: Double)) -> Double {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    }
    
    // Función para calcular el ángulo entre dos vectores (tuplas de 3 componentes)
    static func angleBetween(v1: (x: Double, y: Double, z: Double), v2: (x: Double, y: Double, z: Double)) -> Double {
        let magnitude1 = magnitude(of: v1)
        let magnitude2 = magnitude(of: v2)
        
        let dotProd = dotProduct(of: v1, and: v2)
        
        // Calculamos el ángulo entre los vectores utilizando el coseno inverso
        return acos(dotProd / (magnitude1 * magnitude2))
    }
    
    // Función para calcular la posición solar (x, y, z)
    static func calculateSolarPosition(timedt: Date) -> (Double, Double, Double, Double, Double, Double) {
        // Constantes y funciones auxiliares
        let time = jdays(fecha: timedt)
        
        let secday: Double = 86400.0
        let twopi: Double = 2.0 * Double.pi
        let AU: Double = 149597870.7  // Unidad astronómica en kilómetros
        
        func radians(_ degrees: Double) -> Double {
            return degrees * Double.pi / 180.0
        }
        
        func modulus(_ a: Double, _ b: Double) -> Double {
            return a.truncatingRemainder(dividingBy: b) < 0 ? a.truncatingRemainder(dividingBy: b) + b : a.truncatingRemainder(dividingBy: b)
        }
        
        func sqr(_ value: Double) -> Double {
            return value * value
        }
        
        func deltaET(_ year: Double) -> Double {
            // Estimación simple del Delta ET para años recientes
            return 26.465 + 0.747622 * (year - 1950) + 1.886913 * sin(2 * Double.pi * (year - 1975) / 33)
        }
        
        // Cálculos principales
        let mjd = time - 2415020.0
        let year = 1900.0 + mjd / 365.25
        let T = (mjd + deltaET(year) / secday) / 36525.0
        let M = radians(modulus(358.47583 + modulus(35999.04975 * T, 360.0) - (0.000150 + 0.0000033 * T) * sqr(T), 360.0))
        let L = radians(modulus(279.69668 + modulus(36000.76892 * T, 360.0) + 0.0003025 * sqr(T), 360.0))
        let e = 0.01675104 - (0.0000418 + 0.000000126 * T) * T
        let C = radians((1.919460 - (0.004789 + 0.000014 * T) * T) * sin(M) + (0.020094 - 0.000100 * T) * sin(2 * M) + 0.000293 * sin(3 * M))
        let O = radians(modulus(259.18 - 1934.142 * T, 360.0))
        let Lsa = modulus(L + C - radians(0.00569 - 0.00479 * sin(O)), twopi)
        let nu = modulus(M + C, twopi)
        let R = 1.0000002 * (1.0 - sqr(e)) / (1.0 + e * cos(nu))
        let eps = radians(23.452294 - (0.0130125 + (0.00000164 - 0.000000503 * T) * T) * T + 0.00256 * cos(O))
        let R_km = AU * R
        
        // Devolver la tupla con las coordenadas x, y, z
        let x_eci = R_km * cos(Lsa)
        let y_eci = R_km * sin(Lsa) * cos(eps)
        let z_eci = R_km * sin(Lsa) * sin(eps)
        
        let (x_ecef, y_ecef, z_ecef) = ECItoECEF(timedt: timedt, eci_vector: (x_eci, y_eci, z_eci))
        
        return (x_ecef, y_ecef, z_ecef, x_eci, y_eci, z_eci)
    }
    
    static func mag(imag: Double, sat_ecef: (Double, Double, Double), sun_ecef: (Double, Double, Double), obs_ecef: (Double, Double, Double)) -> Double {
        let sat_obs = (sat_ecef.0 - obs_ecef.0, sat_ecef.1 - obs_ecef.1, sat_ecef.2 - obs_ecef.2)
        let sun_obs = (sun_ecef.0 - obs_ecef.0, sun_ecef.1 - obs_ecef.1, sun_ecef.2 - obs_ecef.2)
        let beta = (Extra.angleBetween(v1: sat_obs, v2: sun_obs))
        let a = magnitude(of: sun_obs)
        let b = magnitude(of: sat_obs)
        let c = sqrt(a * a + b * b - 2 * a * b * cos(beta))
        let angleA = acos((b * b + c * c - a * a) / (2 * b * c))
        let disttosat = Extra.magnitude(of: (sat_obs))
        //print("Distancia al satélite: \(disttosat)")
        //print("AnguloA: \(angleA)")
        //print("Magnitud ajustada: \(imag - 15 + 5 * log10(disttosat) - 2.5 * log10(sin(angleA) + (Double.pi - angleA) * cos(angleA)))")
        return imag + 5*log10(disttosat/1000) - 2.5*log10(sin(angleA) + (Double.pi-angleA)*cos(angleA))
    }
    
    static func ECItoElevAz(timedt: Date, objectPosition: (Double, Double, Double), observerPosition: (Double, Double, Double), observerLat: Double, observerLon: Double, observerAlt: Double) -> (az: Double, el: Double, SEZ: (Double, Double, Double)){
        let (sposX, sposY, sposZ) = (objectPosition.0, objectPosition.1, objectPosition.2)
        let (oposX, oposY, oposZ) = (observerPosition.0, observerPosition.1, observerPosition.2)

        let observerLonRad = observerLon * .pi / 180.0
        let observerLatRad = observerLat * .pi / 180.0
        
        let theta = (gmst(utcTime: timedt) + observerLonRad).truncatingRemainder(dividingBy: 2 * .pi)
        
        let rx = sposX - oposX
        let ry = sposY - oposY
        let rz = sposZ - oposZ
        
        let sinLat = sin(observerLatRad)
        let cosLat = cos(observerLatRad)
        let sinTheta = sin(theta)
        let cosTheta = cos(theta)
        
        let topS = sinLat * cosTheta * rx + sinLat * sinTheta * ry - cosLat * rz
        let topE = -sinTheta * rx + cosTheta * ry
        let topZ = cosLat * cosTheta * rx + cosLat * sinTheta * ry + sinLat * rz
        
        var azimuth = atan2(-topE, topS) + .pi
        azimuth.formTruncatingRemainder(dividingBy: 2 * .pi)
        
        let rg = Extra.magnitude(of: (rx, ry, rz))
        var elevation = asin(topZ / rg)
        
        azimuth = azimuth * 180.0 / .pi
        elevation = elevation * 180.0 / .pi
        return (azimuth, elevation, (topS, topE, topZ))
    }
    
    static func illuminationDist(timedt: Date, sat_eci: (Double, Double, Double), sunPosition: (Double, Double, Double, Double, Double, Double)) -> Double {
        let rsun = (sunPosition.0, sunPosition.1, sunPosition.2)
        let rsat = ECItoECEF(timedt: timedt, eci_vector: sat_eci)
        let cross = cross(v1: rsun, v2: rsat)
        let numer = magnitude(of: cross)
        let denom = magnitude(of: rsun) * magnitude(of: rsat)
        let sinzeta = numer / denom
        let zeta = asin(sinzeta)
        let dist = magnitude(of: rsat) * cos(zeta - .pi*0.5)
        return dist
    }
    
    static func ECItoECEF(timedt: Date, eci_vector: (Double, Double, Double)) -> (Double, Double, Double) {
        let GMST = gmst(utcTime: timedt)

        let MCR: [[Double]] = [
            [cos(GMST), sin(GMST), 0],
            [-sin(GMST), cos(GMST), 0],
            [0, 0, 1]
        ]
        let CR = matrixProduct3x1(M33: MCR, M31: [[eci_vector.0],[eci_vector.1],[eci_vector.2]])
        
        return (CR[0][0], CR[1][0], CR[2][0])
    }
}
