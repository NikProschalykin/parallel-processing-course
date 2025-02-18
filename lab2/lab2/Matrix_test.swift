import Foundation

let dateFormatter = ISO8601DateFormatter()

// Тестирование класса Matrix
func generateRandomMatrix(rows: Int, cols: Int) -> Matrix {
    let data = (0..<rows).map { _ in (0..<cols).map { _ in Double.random(in: -10...10) } }
    return Matrix(data)
}

func measureExecutionTime(label: String, operation: () -> Matrix?) {
    let startTime = Date()
    
    let result = operation()
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    let formattedTime = String(format: "%.5f", executionTime)
    print("✅ \(label): ⏱ \(formattedTime) мс")
    
    if isDisplayMatrix {
        result?.display()
    }
}

func parallelMeasureExecutionTime(label: String, operation: (@escaping (Matrix?) -> Void) -> Void) {
    let startTime = Date()
    operation { result in
        
        let executionTime = Date().timeIntervalSince(startTime) * 1000
        let formattedTime = String(format: "%.5f", executionTime)
        
        DispatchQueue.main.async {
            print("✅ \(label): ⏱ \(formattedTime) мс")
            
            if isDisplayMatrix {
                result?.display()
            }
        }
    }
}

func measureAsyncExecutionTime(label: String, operation: @escaping () async throws -> Matrix) async {
    let startTime = Date()
    
    do {
        let result = try await operation()
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime) * 1000
        DispatchQueue.main.async {
            print("✅ \(label): ⏱ \(String(format: "%.2f", executionTime)) мс")
            
            if isDisplayMatrix{
                result.display()
            }
        }
    } catch {
        print("❌ Ошибка: \(error.localizedDescription)")
    }
}
