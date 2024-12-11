import Foundation
import simd
import Darwin

class SGDP4 {
    var mode: Int?
    var eo: Double
    var xincl: Double
    var xno: Double
    var bstar: Double
    var omegao: Double
    var xmo: Double
    var xnodeo: Double
    var t_0: Date
    var xn_0: Double
    
    // Atributos internos
    var cosIO: Double = 0.0
    var sinIO: Double = 0.0
    var x3thm1: Double = 0.0
    var x1mth2: Double = 0.0
    var x7thm1: Double = 0.0
    var xnodp: Double = 0.0
    var aodp: Double = 0.0
    var perigee: Double = 0.0
    var apogee: Double = 0.0
    var period: Double = 0.0
    var eta: Double = 0.0
    var c2: Double = 0.0
    var c1: Double = 0.0
    var c4: Double = 0.0
    var c5: Double = 0.0
    var c3: Double = 0.0
    var omgcof: Double = 0.0
    var xmdot: Double = 0.0
    var omgdot: Double = 0.0
    var xnodot: Double = 0.0
    var xmcof: Double = 0.0
    var xnodcf: Double = 0.0
    var t2cof: Double = 0.0
    var xlcof: Double = 0.0
    var aycof: Double = 0.0
    var cosXMO: Double = 0.0
    var sinXMO: Double = 0.0
    var delmo: Double = 0.0
    var d2: Double = 0.0
    var d3: Double = 0.0
    var d4: Double = 0.0
    var t3cof: Double = 0.0
    var t4cof: Double = 0.0
    var t5cof: Double = 0.0
    
    // Constantes numéricas
    let ECC_EPS: Double = 1.0e-6            // Muy bajo para cálculos adicionales
    let ECC_LIMIT_LOW: Double = -1.0e-3
    let ECC_LIMIT_HIGH: Double = 1.0 - 1.0e-6 // Muy cerca de 1
    let ECC_ALL: Double = 1.0e-4

    let EPS_COS: Double = 1.5e-12
    let NR_EPS: Double = 1.0e-12

    let CK2: Double = 5.413080e-4
    let CK4: Double = 0.62098875e-6
    let E6A: Double = 1.0e-6
    let QOMS2T: Double = 1.88027916e-9
    let S: Double = 1.01222928
    let S0: Double = 78.0
    let XJ3: Double = -0.253881e-5
    let XKE: Double = 0.743669161e-1
    let XKMPER: Double = 6378.135
    let XMNPDA: Double = 1440.0
    let AE: Double = 1.0
    let SECDAY: Double = 86400.0

    let F: Double = 1 / 298.257223563  // Aplanamiento de la Tierra WGS-84
    let A: Double = 6378.137           // Radio ecuatorial WGS-84

    // Modos para SGDP4
    let SGDP4_ZERO_ECC: Int = 0
    let SGDP4_DEEP_NORM: Int = 1
    let SGDP4_NEAR_SIMP: Int = 2
    let SGDP4_NEAR_NORM: Int = 3

    // Cálculo adicional
    let KS: Double = 1.0 * (1.0 + 78.0 / 6378.135)
    let A3OVK2: Double = (0.253881e-5 / 5.413080e-4) * pow(1.0, 3)
    
    // Inicializador
    init(orbitElements: OrbitElements) {
        self.eo = orbitElements.excentricity
        self.xincl = orbitElements.inclination
        self.xno = orbitElements.originalMeanMotion
        self.bstar = orbitElements.bstar
        self.omegao = orbitElements.argPerigee
        self.xmo = orbitElements.meanAnomaly
        self.xnodeo = orbitElements.rightAscension
        self.t_0 = orbitElements.epoch
        self.xn_0 = orbitElements.meanMotion
        
        if self.eo <= 0 || self.eo >= ECC_LIMIT_HIGH {
            // Error: Eccentricity out of range
            fatalError("Eccentricity out of range")
        } else if !(0.0035 * 2 * .pi / XMNPDA < self.xn_0 && self.xn_0 < 18 * 2 * .pi / XMNPDA) {
            // Error: Mean motion out of range
            fatalError("Mean motion out of range")
        } else if self.xincl <= 0 || self.xincl >= .pi {
            // Error: Inclination out of range
            fatalError("Inclination out of range")
        }
        
        self.cosIO = cos(self.xincl)
        self.sinIO = sin(self.xincl)
        let theta2 = self.cosIO * self.cosIO
        let theta4 = theta2 * theta2
        self.x3thm1 = 3.0 * theta2 - 1.0
        self.x1mth2 = 1.0 - theta2
        self.x7thm1 = 7.0 * theta2 - 1.0
        
        let a1 = pow(XKE / self.xn_0, 2.0 / 3.0)
        let betao2 = 1.0 - self.eo * self.eo
        let betao = sqrt(betao2)
        var temp0 = 1.5 * CK2 * self.x3thm1 / (betao * betao2)
        let del1 = temp0 / (a1 * a1)
        let a0 = a1 * (1.0 - del1 * (1.0 / 3.0 + del1 * (1.0 + del1 * 134.0 / 81.0)))
        let del0 = temp0 / (a0 * a0)
        self.xnodp = self.xn_0 / (1.0 + del0)
        self.aodp = a0 / (1.0 - del0)
        self.perigee = (self.aodp * (1.0 - self.eo) - AE) * XKMPER
        self.apogee = (self.aodp * (1.0 + self.eo) - AE) * XKMPER
        self.period = (2 * .pi * 1440.0 / XMNPDA) / self.xnodp
        
        if self.period >= 225 {
            self.mode = SGDP4_DEEP_NORM // Deep-Space model
        } else if self.perigee < 220 {
            self.mode = SGDP4_NEAR_SIMP // Near-space, simplified equations
        } else {
            self.mode = SGDP4_NEAR_NORM // Near-space, normal equations
        }
        
        var s4: Double = 0.0
        var qoms24: Double = 0.0
        if self.perigee < 156 {
            s4 = self.perigee - 78
            if s4 < 20 {
                s4 = 20
            }
            qoms24 = ((120 - s4) * (AE / XKMPER))*((120 - s4) * (AE / XKMPER))*((120 - s4) * (AE / XKMPER))*((120 - s4) * (AE / XKMPER))
            s4 = (s4 / XKMPER + AE)
        } else {
            s4 = KS
            qoms24 = QOMS2T
        }
        
        let pinvsq = 1.0 / (pow(self.aodp, 2) * pow(betao2, 2))
        let tsi = 1.0 / (self.aodp - s4)
        self.eta = self.aodp * self.eo * tsi
        let etasq = pow(self.eta, 2)
        let eeta = self.eo * self.eta
        let psisq = abs(1.0 - etasq)
        let coef = qoms24 * pow(tsi, 4)
        let coef_1 = coef / pow(psisq, 3.5)

        self.c2 = coef_1 * self.xnodp * (self.aodp * (1.0 + 1.5 * etasq + eeta * (4.0 + etasq)) +
                                         (0.75 * CK2) * tsi / psisq * self.x3thm1 *
                                         (8.0 + 3.0 * etasq * (8.0 + etasq)))
        self.c1 = self.bstar * self.c2
        
        self.c4 = 2.0 * self.xnodp * coef_1 * self.aodp * betao2 * (
            self.eta * (2.0 + 0.5 * etasq) +
            self.eo * (0.5 + 2.0 * etasq) -
            (2.0 * CK2) * tsi / (self.aodp * psisq) *
            (-3.0 * self.x3thm1 * (1.0 - 2.0 * eeta + etasq * (1.5 - 0.5 * eeta)) +
             0.75 * self.x1mth2 * (2.0 * etasq - eeta * (1.0 + etasq)) * cos(2.0 * self.omegao))
        )

        self.c5 = 0.0
        self.c3 = 0.0
        self.omgcof = 0.0

        if self.mode == SGDP4_NEAR_NORM {
            self.c5 = (2.0 * coef_1 * self.aodp * betao2 * (1.0 + 2.75 * (etasq + eeta) + eeta * etasq))
            if self.eo > ECC_ALL {
                self.c3 = coef * tsi * A3OVK2 * self.xnodp * AE * self.sinIO / self.eo
            }
            self.omgcof = self.bstar * self.c3 * cos(self.omegao)
        }
        
        let temp1 = 3.0 * CK2 * pinvsq * self.xnodp
        let temp2 = temp1 * CK2 * pinvsq
        let temp3 = 1.25 * CK4 * pow(pinvsq, 2) * self.xnodp

        self.xmdot = (self.xnodp + (0.5 * temp1 * betao * self.x3thm1 + 0.0625 *
                                    temp2 * betao * (13.0 - 78.0 * theta2 +
                                                     137.0 * theta4)))

        let x1m5th = 1.0 - 5.0 * theta2

        self.omgdot = (-0.5 * temp1 * x1m5th + 0.0625 * temp2 *
                       (7.0 - 114.0 * theta2 + 395.0 * theta4) +
                       temp3 * (3.0 - 36.0 * theta2 + 49.0 * theta4))

        let xhdot1 = -temp1 * self.cosIO
        self.xnodot = (xhdot1 + (0.5 * temp2 * (4.0 - 19.0 * theta2) + 2.0 * temp3 * (3.0 - 7.0 * theta2)) * self.cosIO)
        
        if self.eo > ECC_ALL {
            self.xmcof = (-(2.0 / 3.0) * AE) * coef * self.bstar / eeta
        } else {
            self.xmcof = 0.0
        }

        self.xnodcf = 3.5 * betao2 * xhdot1 * self.c1
        self.t2cof = 1.5 * self.c1

        temp0 = 1.0 + self.cosIO
        if abs(temp0) < EPS_COS {
            temp0 = sign(temp0) * EPS_COS
        }

        self.xlcof = 0.125 * A3OVK2 * self.sinIO * (3.0 + 5.0 * self.cosIO) / temp0

        self.aycof = 0.25 * A3OVK2 * self.sinIO

        self.cosXMO = cos(self.xmo)
        self.sinXMO = sin(self.xmo)
        self.delmo = pow(1.0 + self.eta * self.cosXMO, 3)

        if self.mode == SGDP4_NEAR_NORM {
            let c1sq = self.c1 * self.c1
            self.d2 = 4.0 * self.aodp * tsi * c1sq
            temp0 = self.d2 * tsi * self.c1 / 3.0
            self.d3 = (17.0 * self.aodp + s4) * temp0
            self.d4 = 0.5 * temp0 * self.aodp * tsi * (221.0 * self.aodp + 31.0 * s4) * self.c1
            self.t3cof = self.d2 + 2.0 * c1sq
            self.t4cof = 0.25 * (3.0 * self.d3 + self.c1 * (12.0 * self.d2 + 10.0 * c1sq))
            self.t5cof = 0.2 * (3.0 * self.d4 + 12.0 * self.c1 * self.d3 + 6.0 * self.d2 * self.d2 +
                                15.0 * c1sq * (2.0 * self.d2 + c1sq))
        } else if self.mode == SGDP4_DEEP_NORM {
            let c1sq = self.c1 * self.c1
            self.d2 = 4.0 * self.aodp * tsi * c1sq
            temp0 = self.d2 * tsi * self.c1 / 3.0
            self.d3 = (17.0 * self.aodp + s4) * temp0
            self.d4 = 0.5 * temp0 * self.aodp * tsi * (221.0 * self.aodp + 31.0 * s4) * self.c1
            self.t3cof = self.d2 + 2.0 * c1sq
            self.t4cof = 0.25 * (3.0 * self.d3 + self.c1 * (12.0 * self.d2 + 10.0 * c1sq))
            self.t5cof = 0.2 * (3.0 * self.d4 + 12.0 * self.c1 * self.d3 + 6.0 * self.d2 * self.d2 +
                                15.0 * c1sq * (2.0 * self.d2 + c1sq))
        }

    }
    
    // Método de propagación
    func propagate(utc_time: Date) -> [String: Double] {
        var kep: [String: Double] = [:]

        // Get the time delta in minutes
        let ts = utc_time.timeIntervalSince(t_0) / 60.0
        let em = self.eo
        let xinc = self.xincl

        var xmp = self.xmo + self.xmdot * ts
        let xnode = self.xnodeo + ts * (self.xnodot + ts * self.xnodcf)
        var omega = self.omegao + self.omgdot * ts
        
        // Mode-based calculations
        var delm: Double = 0.0
        var temp0: Double = 0.0
        var tempa: Double = 0.0
        var tempe: Double = 0.0
        var templ: Double = 0.0
        var a: Double = 0.0
        var e: Double = 0.0
        var xl: Double = 0.0
        switch mode {
        case SGDP4_ZERO_ECC:
            fatalError("Mode SGDP4_ZERO_ECC not implemented")

        case SGDP4_NEAR_SIMP:
            fatalError("Mode SGDP4_NEAR_SIMP not implemented")

        case SGDP4_NEAR_NORM:
            delm = self.xmcof * (pow((1.0 + self.eta * cos(xmp)), 3) - self.delmo)
            temp0 = ts * self.omgcof + delm
            xmp += temp0
            omega -= temp0
            tempa = 1.0 - (ts * (self.c1 + ts * (self.d2 + ts * (self.d3 + ts * self.d4))))
            tempe = self.bstar * (self.c4 * ts + self.c5 * (sin(xmp) - self.sinXMO))
            templ = ts * ts * (self.t2cof + ts * (self.t3cof + ts * (self.t4cof + ts * self.t5cof)))
            a = self.aodp * pow(tempa, 2)
            e = em - tempe
            xl = xmp + omega + xnode + self.xnodp * templ

        default:
            delm = self.xmcof * (pow((1.0 + self.eta * cos(xmp)), 3) - self.delmo)
            temp0 = ts * self.omgcof + delm
            xmp += temp0
            omega -= temp0
            tempa = 1.0 - (ts * (self.c1 + ts * (self.d2 + ts * (self.d3 + ts * self.d4))))
            tempe = self.bstar * (self.c4 * ts + self.c5 * (sin(xmp) - self.sinXMO))
            templ = ts * ts * (self.t2cof + ts * (self.t3cof + ts * (self.t4cof + ts * self.t5cof)))
            a = self.aodp * pow(tempa, 2)
            e = em - tempe
            xl = xmp + omega + xnode + self.xnodp * templ
        }

        if a < 1 {
            // Si 'a' es menor que 1, lanzar excepción
            fatalError("Satellite crashed at time \(utc_time)")
        } else if e < ECC_LIMIT_LOW {
            // Si 'e' es menor que 'ECC_LIMIT_LOW', lanzar un ValueError
            fatalError("Satellite modified eccentricity too low: \(e) < \(ECC_LIMIT_LOW)")
        }


        e = e < ECC_EPS ? ECC_EPS : e
        e = e > ECC_LIMIT_HIGH ? ECC_LIMIT_HIGH : e

        // Continue with orbital calculations
        let beta2 = 1.0 - pow(e,2)
        let sinOMG = sin(omega)
        let cosOMG = cos(omega)

        temp0 = 1.0 / (a * beta2)
        let axn = e * cosOMG
        let ayn = e * sinOMG + temp0 * self.aycof
        let xlt = xl + temp0 * self.xlcof * axn

        let elsq = pow(axn,2) + pow(ayn,2)

        if elsq >= 1 {
            fatalError("e**2 >= 1 at \(utc_time)")
        }

        kep["ecc"] = sqrt(elsq)

        var epw = fmod(xlt - xnode, 2 * Double.pi)
        let capu = epw
        let maxnr = kep["ecc"]!
        var ecosE: Double = 0.0
        var esinE: Double = 0.0
        var sinEPW: Double = 0.0
        var cosEPW: Double = 0.0
        for _ in 0..<10 {
            sinEPW = sin(epw)
            cosEPW = cos(epw)
            ecosE = axn * cosEPW + ayn * sinEPW
            esinE = axn * sinEPW - ayn * cosEPW
            let f = capu - epw + esinE
            if abs(f) < NR_EPS {
                break
            }

            let df = 1.0 - ecosE
            var nr = f / df

            nr = max(min(nr, maxnr), -maxnr)

            epw += nr
        }

        temp0 = 1.0 - elsq
        let betal = sqrt(temp0)
        let pl = a * temp0
        let r = a * (1.0 - ecosE)
        let invR = 1.0 / r
        var temp2 = a * invR
        let temp3 = 1.0 / (1.0 + betal)
        let cosu = temp2 * (cosEPW - axn + ayn * esinE * temp3)
        let sinu = temp2 * (sinEPW - ayn - axn * esinE * temp3)
        let u = atan2(sinu, cosu)
        let sin2u = 2.0 * sinu * cosu
        let cos2u = 2.0 * cosu * cosu - 1.0
        temp0 = 1.0 / pl
        let temp1 = CK2 * temp0
        temp2 = temp1 * temp0

        // Update for short-term periodics
        let rk = r * (1.0 - 1.5 * temp2 * betal * self.x3thm1) +
                0.5 * temp1 * self.x1mth2 * cos2u
        let uk = u - 0.25 * temp2 * self.x7thm1 * sin2u
        let xnodek = xnode + 1.5 * temp2 * self.cosIO * sin2u
        let xinck = xinc + 1.5 * temp2 * self.cosIO * self.sinIO * cos2u
        
        if rk < 1 {
            fatalError("Satellite crashed at time \(utc_time)")
        }
        
        temp0 = sqrt(a)
        temp2 = XKE / (a * temp0)
        let rdotk = ((XKE * temp0 * esinE * invR - temp2 * temp1 * self.x1mth2 * sin2u) *
                     (XKMPER / AE * XMNPDA / 86400.0))

        let rfdotk = ((XKE * sqrt(pl) * invR + temp2 * temp1 *
                       (self.x1mth2 * cos2u + 1.5 * self.x3thm1)) *
                      (XKMPER / AE * XMNPDA / 86400.0))

        kep["radius"] = rk * XKMPER / AE
        kep["theta"] = uk
        kep["eqinc"] = xinck
        kep["ascn"] = xnodek
        kep["argp"] = omega
        kep["smjaxs"] = a * XKMPER / AE
        kep["rdotk"] = rdotk
        kep["rfdotk"] = rfdotk
        return kep
    }
}
