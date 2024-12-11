import Foundation

func matrixProduct3x1(M33: [[Double]], M31: [[Double]]) -> [[Double]] {
    var resultMatrix = [[Double]](repeating: [Double](repeating: 0.0, count: 1), count: 3)
    
    for i in 0..<3 {
        for (a, b) in zip(M33[i], M31) {
            resultMatrix[i][0] += a * b[0]
        }
    }
    return resultMatrix
}
