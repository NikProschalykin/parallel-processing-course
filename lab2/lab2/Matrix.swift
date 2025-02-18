import Foundation

enum MatrixErrors: Error {
    case multiplyError(text: String?)
}

final class Matrix {
    private var data: [[Double]]
    let rows: Int
    let cols: Int
    
    init(rows: Int, cols: Int, fill value: Double = 0.0) {
        self.rows = rows
        self.cols = cols
        self.data = Array(repeating: Array(repeating: value, count: cols), count: rows)
    }
    
    convenience init(_ data: [[Double]]) {
        self.init(rows: data.count, cols: data.first?.count ?? 0)
        self.data = data
    }
    
    func copy() -> Matrix {
        return Matrix(self.data)
    }
    
    subscript(row: Int, col: Int) -> Double {
        get {
            return data[row][col]
        }
        set {
            data[row][col] = newValue
        }
    }
    
    func display() {
        for row in data {
            print(row.map { String(format: "%.2f", $0) }.joined(separator: " \t"))
        }
        print()
    }
    
    func setValue(_ i: Int, _ j: Int, _ value: Double) {
        data[i][j] = value
    }
}

class MatrixOperations {
    static func add(_ matrixA: Matrix, _ matrixB: Matrix) -> Matrix? {
        guard matrixA.rows == matrixB.rows, matrixA.cols == matrixB.cols else { return nil }
        let result = Matrix(rows: matrixA.rows, cols: matrixA.cols)
        for i in 0..<matrixA.rows {
            for j in 0..<matrixA.cols {
                result[i, j] = matrixA[i, j] + matrixB[i, j]
            }
        }
        return result
    }
    
    static func multiply(_ matrixA: Matrix, _ matrixB: Matrix) throws -> Matrix? {
        guard matrixA.cols == matrixB.rows else {
            throw MatrixErrors.multiplyError(text: "count of cols != count of rows")
        }
        
        let result = Matrix(rows: matrixA.rows, cols: matrixB.cols)
        for i in 0..<matrixA.rows {
            for j in 0..<matrixB.cols {
                for k in 0..<matrixA.cols {
                    result[i, j] += matrixA[i, k] * matrixB[k, j]
                }
            }
        }
        
        return result
    }
    
    static func parallelAdd(_ matrixA: Matrix, _ matrixB: Matrix, completion: @escaping (Matrix?) -> Void) {
        guard matrixA.rows == matrixB.rows, matrixA.cols == matrixB.cols else {
            completion(nil)
            return
        }
        
        let result = Matrix(rows: matrixA.rows, cols: matrixA.cols)
        let queue = DispatchQueue.global(qos: .userInitiated)
        let group = DispatchGroup()
        let lock = NSLock()  // Для синхронизации доступа к result
        
        for i in 0..<matrixA.rows {
            group.enter()
            queue.async {
                for j in 0..<matrixA.cols {
                    lock.lock()
                    result[i, j] = matrixA[i, j] + matrixB[i, j]
                    lock.unlock()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .global()) {
            completion(result)
        }
    }
    
    static func parallelMultiply(_ matrixA: Matrix, _ matrixB: Matrix, completion: @escaping (Matrix?) -> Void) {
        guard matrixA.cols == matrixB.rows else {
            completion(nil)
            return
        }
        
        let result = Matrix(rows: matrixA.rows, cols: matrixB.cols)
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        DispatchQueue.concurrentPerform(iterations: matrixA.rows) { i in
            for j in 0..<matrixB.cols {
                var sum = 0.0
                for k in 0..<matrixA.cols {
                    sum += matrixA[i, k] * matrixB[k, j]
                }
                queue.sync {
                    result[i, j] = sum
                }
            }
        }
        
        completion(result)
    }
    
    /// Параллельное сложение матриц с async/await
    static func parallelAddAsync(_ matrixA: Matrix, _ matrixB: Matrix) async throws -> Matrix {
        guard matrixA.rows == matrixB.rows, matrixA.cols == matrixB.cols else {
            throw NSError(domain: "MatrixOperationsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Размеры матриц не совпадают"])
        }
        
        let result = Matrix(rows: matrixA.rows, cols: matrixA.cols)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<matrixA.rows {
                group.addTask {
                    for j in 0..<matrixA.cols {
                        result[i, j] = matrixA[i, j] + matrixB[i, j]
                    }
                }
            }
        }
        
        return result
    }
    
    /// Параллельное умножение матриц с async/await
    static func parallelMultiplyAsync(_ matrixA: Matrix, _ matrixB: Matrix) async throws -> Matrix {
        guard matrixA.cols == matrixB.rows else {
            throw NSError(domain: "MatrixOperationsError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Число столбцов A не равно числу строк B"])
        }

        let result = Matrix(rows: matrixA.rows, cols: matrixB.cols)
        
        // Используем await для потокобезопасной работы
        await withTaskGroup(of: (Int, Int, Double).self) { group in
            for i in 0..<matrixA.rows {
                for j in 0..<matrixB.cols {
                    group.addTask {
                        var sum = 0.0
                        for k in 0..<matrixA.cols {
                            sum += matrixA[i, k] * matrixB[k, j]
                        }
                        return (i, j, sum) // Возвращаем результат, а не пишем сразу
                    }
                }
            }
            
            // Ожидаем завершения всех задач и записываем результат в actor
            for await (i, j, value) in group {
                 result.setValue(i, j, value)
            }
        }

        return result
    }

}

