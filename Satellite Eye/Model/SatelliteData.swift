import Foundation

struct TLE: Identifiable, Codable {
    var id: String { OBJECT_ID }
    var OBJECT_NAME: String
    var OBJECT_ID: String
    var EPOCH: String
    var MEAN_MOTION: Double
    var ECCENTRICITY: Double
    var INCLINATION: Double
    var RA_OF_ASC_NODE: Double
    var ARG_OF_PERICENTER: Double
    var MEAN_ANOMALY: Double
    var EPHEMERIS_TYPE: Int
    var CLASSIFICATION_TYPE: String
    var NORAD_CAT_ID: Int
    var ELEMENT_SET_NO: Int
    var REV_AT_EPOCH: Int
    var BSTAR: Double
    var MEAN_MOTION_DOT: Double
    var MEAN_MOTION_DDOT: Double

    enum CodingKeys: String, CodingKey {
        case OBJECT_NAME, OBJECT_ID, EPOCH, MEAN_MOTION, ECCENTRICITY, INCLINATION, RA_OF_ASC_NODE, ARG_OF_PERICENTER,
             MEAN_ANOMALY, EPHEMERIS_TYPE, CLASSIFICATION_TYPE, NORAD_CAT_ID, ELEMENT_SET_NO, REV_AT_EPOCH, BSTAR,
             MEAN_MOTION_DOT, MEAN_MOTION_DDOT
    }
}
