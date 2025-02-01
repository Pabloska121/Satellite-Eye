import Foundation
import SwiftUI
import simd
import Darwin

class SatelliteCalc {
    var tle: TLE
    var orbitElements: OrbitElements
    var sgdp4: SGDP4
    
    init(tle: TLE) {
        self.tle = tle
        self.orbitElements = OrbitElements(tle: self.tle)
        self.sgdp4 = SGDP4(orbitElements: self.orbitElements)
    }
    
    func satelliteCalc(utcTime: Date) -> (lon: Double, lat: Double, alt: Double, vel: Double, pos: (Double, Double, Double)) {
        // Llamar a getPosition para obtener las coordenadas cartesianas y velocidades
        let (position, velocity) = self.getPosition(utcTime: utcTime, normalize: true)
        // Extraer las componentes de la posición y velocidad
        let (pos_x, pos_y, pos_z) = position
        let (vel_x, vel_y, vel_z) = velocity
        // Calcular la longitud, latitud y altitud según el algoritmo proporcionado
        let XKMPER: Double = 6378.135
        let F: Double = 1 / 298.257223563
        let A: Double = 6378.137
        
        var lon = atan2(pos_y * XKMPER, pos_x * XKMPER) - gmst(utcTime: utcTime)
        lon = lon.truncatingRemainder(dividingBy: 2 * .pi)
        
        // Ajustar el valor de la longitud al rango correcto
        if lon > .pi {
            lon -= 2 * .pi
        } else if lon <= -.pi {
            lon += 2 * .pi
        }
        
        let r = sqrt(pos_x * pos_x + pos_y * pos_y)
        var lat = atan2(pos_z, r)
        
        let e2 = F * (2 - F)
        
        var c = 0.0
        while true {
            let lat2 = lat
            c = 1 / sqrt(1 - e2 * pow(sin(lat2), 2))
            lat = atan2(pos_z + c * e2 * sin(lat2), r)
            if abs(lat - lat2) < 1e-10 {
                break
            }
        }
        
        let alt = r / cos(lat) - c
        let altInMeters = alt * A
        
        // Convertir radianes a grados
        let lonDegrees = lon * 180 / .pi
        let latDegrees = lat * 180 / .pi
        
        return (lonDegrees, latDegrees, altInMeters, sqrt(vel_x * vel_x + vel_y * vel_y + vel_z * vel_z), position)
    }

    func getPosition(utcTime: Date, normalize: Bool = true) -> ((Double, Double, Double), (Double, Double, Double)) {
        // Obtener la propagación del satélite usando el modelo SGDP4 para el tiempo UTC dado
        let kep = self.sgdp4.propagate(utc_time: utcTime)
        // Convertir las posiciones y velocidades desde el formato Kepleriano a coordenadas cartesianas
        let (pos, vel) = kep2xyz(kep: kep)

        if normalize {
            // Normalizar la posición y la velocidad (suponiendo que XKMPER, XMNPDA, y SECDAY son constantes definidas)
            let XKMPER: Double = 6378.137
            //let XMNPDA: Double = 1440.0
            //let SECDAY: Double = 86400.0
            
            let normalizedPos = (pos.x / XKMPER, pos.y / XKMPER, pos.z / XKMPER)
            //let normalizedVel = (vel.x / (XKMPER * XMNPDA / SECDAY), vel.y / (XKMPER * XMNPDA / SECDAY), vel.z / (XKMPER * XMNPDA / SECDAY))

            return (normalizedPos, (vel.x, vel.y, vel.z))
        }

        return ((pos.x, pos.y, pos.z), (vel.x, vel.y, vel.z))
    }
    
    func getObserverLook(utcTime: Date, observerLon: Double, observerLat: Double, observerAlt: Double) -> (azimuth: Double, elevation: Double) {
        // Obtener la posición del satélite
        let (satPosition, _) = self.getPosition(utcTime: utcTime, normalize: false)

        // Obtener la posición del observador
        let (observerPosition, _) = observerPosition(utcTime: utcTime, lon: observerLon, lat: observerLat, alt: observerAlt)

        let azelev = Extra.ECItoElevAz(timedt: utcTime, objectPosition: satPosition, observerPosition: observerPosition, observerLat: observerLat, observerLon: observerLon, observerAlt: observerAlt)
        
        return (azelev.az, azelev.el)
    }
    
    func getApparentMagnitude(utcTime: Date, observerLon: Double, observerLat: Double, observerAlt: Double) -> Double {
        let (satPosition, _) = self.getPosition(utcTime: utcTime, normalize: false)
        let (observerPosition, _) = observerPosition(utcTime: utcTime, lon: observerLon, lat: observerLat, alt: observerAlt)
        let sun = Extra.calculateSolarPosition(timedt: utcTime)
        let sun_ecef = (sun.3, sun.4, sun.5)
        let obs_ecef = Extra.ECItoECEF(timedt: utcTime, eci_vector: observerPosition)
        let sat_ecef = Extra.ECItoECEF(timedt: utcTime, eci_vector: satPosition)
        //print(utcTime)
        return Extra.mag(imag: -1.8, sat_ecef: sat_ecef, sun_ecef: sun_ecef, obs_ecef: obs_ecef)
    }
    
    func kep2xyz(kep: [String: Double]) -> (simd_double3, simd_double3) {
        let sinT = sin(kep["theta"]!)
        let cosT = cos(kep["theta"]!)
        let sinI = sin(kep["eqinc"]!)
        let cosI = cos(kep["eqinc"]!)
        let sinS = sin(kep["ascn"]!)
        let cosS = cos(kep["ascn"]!)

        let xmx = -sinS * cosI
        let xmy = cosS * cosI

        let ux = xmx * sinT + cosS * cosT
        let uy = xmy * sinT + sinS * cosT
        let uz = sinI * sinT

        let x = kep["radius"]! * ux
        let y = kep["radius"]! * uy
        let z = kep["radius"]! * uz

        let vx = xmx * cosT - cosS * sinT
        let vy = xmy * cosT - sinS * sinT
        let vz = sinI * cosT

        let v_x = kep["rdotk"]! * ux + kep["rfdotk"]! * vx
        let v_y = kep["rdotk"]! * uy + kep["rfdotk"]! * vy
        let v_z = kep["rdotk"]! * uz + kep["rfdotk"]! * vz

        let position = simd_double3(x, y, z)
        let velocity = simd_double3(v_x, v_y, v_z)
        
        return (position, velocity)
    }
    
    func getNextPasses(utcTime2: Date, length: Int, lon: Double, lat: Double, alt: Double, tol: Double = 0.001, horizon: Double = 0, sunriseDeg: Double = 0) -> [(Date, Date, Double, Date, Visibility)] {
        // Función de elevación
        let utcTime = utcTime2.addingTimeInterval(-60 * 15)
        func elevation(minutes: Double) -> Double {
            return self.getObserverLook(utcTime: utcTime.addingTimeInterval(minutes * 60), observerLon: lon, observerLat: lat, observerAlt: alt).elevation - horizon
        }
        
        // Función de elevación inversa
        func elevationInv(minutes: Double) -> Double {
            return -elevation(minutes: minutes)
        }
        
        // Método de búsqueda de raíces usando el algoritmo de Brent
        func getRoot(fun: @escaping (Double) -> Double, start: Double, end: Double, tol: Double = 0.0001, maxIter: Int = 100) -> Double? {
            let a = start
            let b = end
            let fa = fun(a)
            let fb = fun(b)
            
            // Comprobar que el intervalo contiene una raíz
            guard fa * fb < 0 else {
                print("Error: La función no cambia de signo en el intervalo.")
                return nil
            }
            
            // Variables iniciales de Brent
            var x0 = a
            var x1 = b
            var fx0 = fa
            var fx1 = fb
            var x2: Double = 0.0 // Para el cálculo intermedio
            var fx2: Double = 0.0 // Valor de fun(x2)
            var delta = tol * 2.0
            var scur = b - a
            
            for _ in 0..<maxIter {
                if abs(fx1) < abs(fx0) {
                    swap(&x0, &x1)
                    swap(&fx0, &fx1)
                }
                
                // Condiciones de salida
                delta = (tol * 2.0) + abs(x1) * tol
                let sbis = (x0 - x1) / 2.0
                if abs(sbis) < delta || fx1 == 0.0 {
                    return x1
                }
                
                if abs(scur) > delta && abs(fx1) < abs(fx0) {
                    // Intentar interpolación si cumple con las condiciones
                    let d0 = (fx0 - fx1) / (x0 - x1)
                    let d1 = (fx2 - fx1) / (x2 - x1)
                    let interp = -fx1 * (d0 * d1) / (d0 - d1)
                    
                    if 2.0 * abs(interp) < min(abs(scur), 3.0 * abs(sbis) - delta) {
                        scur = interp
                    } else {
                        scur = sbis
                    }
                } else {
                    scur = sbis
                }
                
                x2 = x1
                fx2 = fx1
                if abs(scur) > delta {
                    x1 += scur
                } else {
                    x1 += sbis > 0 ? delta : -delta
                }
                
                fx1 = fun(x1)
            }
            
            print("No se encontró una raíz dentro del número máximo de iteraciones.")
            return nil
        }
        
        // Interpolación parabólica
        func getMaxParab(fun: @escaping (Double) -> Double, start: Double, end: Double, tol: Double) -> Double {
            var a = start
            var b = (start + end) / 2
            var c = end
            
            var fA = fun(a)
            var fB = fun(b)
            var fC = fun(c)
            
            var x = b
            
            while true {
                let denominator = (b - a) * (fB - fC) - (b - c) * (fB - fA)
                if denominator == 0 {
                    return b
                }
                let numerator = (b - a) * (b - a) * (fB - fC) - (b - c) * (b - c) * (fB - fA)
                x = x - 0.5 * (numerator / denominator)
                
                if abs(b - x) <= tol {
                    return x
                }
                
                let fX = fun(x)
                
                if fX > fB {
                    return b
                }
                
                a = (a + x) / 2
                b = x
                c = (x + c) / 2
                fA = fun(a)
                fB = fX
                fC = fun(c)
            }
        }
        
        // Generación de los tiempos en minutos
        var times = [Date]()
        for minute in 0..<(length * 60) {
            times.append(utcTime.addingTimeInterval(Double(minute) * 60))
        }
        
        // Elevación del satélite
        let elev = times.map {
            self.getObserverLook(utcTime: $0, observerLon: lon, observerLat: lat, observerAlt: alt).elevation - horizon
        }
        
        // Zeros Crossing: Identificación de los momentos de cruce de cero
        let zcs = zip(elev, elev.dropFirst()).enumerated().compactMap { index, pair -> Int? in
            return pair.0 * pair.1 < 0 ? index : nil
        }
        
        var result: [(Date, Date, Double, Date, Visibility)] = []
        var riseTime: Date?
        
        for guess in zcs {
            let horizonMins = getRoot(fun: elevation, start: Double(guess), end: Double(guess + 1), tol: tol / 60.0)
            let horizonTime = utcTime.addingTimeInterval(horizonMins! * 60)
            
            if elev[guess] < 0 {
                riseTime = horizonTime
            } else {
                let fallTime = horizonTime
                if let riseTime = riseTime {
                    let intStart = max(0, Int(floor(riseTime.timeIntervalSince(utcTime) / 60)))
                    let intEnd = min(elev.count, Int(ceil(fallTime.timeIntervalSince(utcTime) / 60)) + 1)
                    
                    var intervalVisibility = Visibility.none // Default to none
                                
                    for i in intStart..<intEnd {
                        let time = utcTime.addingTimeInterval(Double(i) * 60)
                        let visibility = self.determineVisibility(utcTime: time, observerLon: lon, observerLat: lat, observerAlt: alt, sunriseDeg: sunriseDeg)
                        if visibility == .visible || visibility == .daylight {
                            intervalVisibility = visibility
                            break // No es necesario seguir buscando, ya encontramos visibilidad
                        }
                    }
                    
                    if intervalVisibility != .none {
                        // Cálculo del punto máximo de elevación
                        let middle = intStart + elev[intStart..<intEnd].enumerated().max(by: { $0.element < $1.element })!.offset
                        let highest = utcTime.addingTimeInterval(getMaxParab(fun: elevationInv, start: max(riseTime.timeIntervalSince(utcTime) / 60, Double(middle - 1)), end: min(fallTime.timeIntervalSince(utcTime) / 60, Double(middle + 1)), tol: tol / 60.0) * 60)
                        
                        let maxElevation = self.getObserverLook(utcTime: highest, observerLon: lon, observerLat: lat, observerAlt: alt).elevation
                        
                        if maxElevation > 10 {
                            result.append((riseTime, fallTime, maxElevation, highest, intervalVisibility))
                        }
                    }
                }
                riseTime = nil
            }
        }
        return result
    }
    
    func determineVisibility(utcTime: Date, observerLon: Double, observerLat: Double, observerAlt: Double, aosAt: Double = 0, sunriseDeg: Double = -6) -> Visibility {
        // 1. Elevación del satélite
        let observerLook = getObserverLook(utcTime: utcTime, observerLon: observerLon, observerLat: observerLat, observerAlt: observerAlt)
        if observerLook.elevation < aosAt {
            return .none
        }

        // 2. Elevación del Sol
        let (observerPosition, _) = observerPosition(utcTime: utcTime, lon: observerLon, lat: observerLat, alt: observerAlt)
        let sunPosition = Extra.calculateSolarPosition(timedt: utcTime)
        let (_, sunElevation, _) = Extra.ECItoElevAz(timedt: utcTime, objectPosition: (sunPosition.3, sunPosition.4, sunPosition.5), observerPosition: observerPosition, observerLat: observerLat, observerLon: observerLon, observerAlt: observerAlt)
        if sunElevation > sunriseDeg {
            return .daylight
        }
        
        // 3. Distancia y sombra
        let (satPosition, _) = self.getPosition(utcTime: utcTime, normalize: false)
        let dist = Extra.illuminationDist(timedt: utcTime, sat_eci: satPosition, sunPosition: sunPosition)
        let earthRadius: Double = 6378.137
        if dist > earthRadius {
            return .visible
        }
        
        // Si no cumple las condiciones anteriores, está en sombra
        return .sunlit
    }
}

enum Visibility {
    case none        // No visible
    case daylight    // Visible pero en pleno día
    case visible     // Visible en el cielo nocturno
    case sunlit       // No visible por estar en sombra
    var description: String {
        switch self {
        case .none:
            return "hidden"
        case .daylight:
            return "daylight"
        case .visible:
            return "visible"
        case .sunlit:
            return "unlit"
        }
    }
}

