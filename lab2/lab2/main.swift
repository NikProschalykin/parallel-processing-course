import Foundation

let isDisplayMatrix = false
let group = DispatchGroup()

let matrixA = generateRandomMatrix(rows: 100, cols: 100)
let matrixB = generateRandomMatrix(rows: 100, cols: 100)
let matrixC = generateRandomMatrix(rows: 100, cols: 80)

if isDisplayMatrix {
    print("Матрица A:")
    matrixA.display()
    print("Матрица B:")
    matrixB.display()
    print("Матрица C:")
    matrixC.display()
}

measureExecutionTime(label: "Сложение") { 
    MatrixOperations.add(matrixA, matrixB)
}

measureExecutionTime(label: "Умножение") { 
    do {
        return try MatrixOperations.multiply(matrixA, matrixC)
    } catch(let error) {
        guard let error = error as? MatrixErrors else { return nil }
        
        switch error {
        case .multiplyError(let text):
            print(text ?? "")
        }
    }
    
    return nil
}

parallelMeasureExecutionTime(label: "Сложение (параллельное)") { completion in
    MatrixOperations.parallelAdd(matrixA, matrixB, completion: completion)
}

parallelMeasureExecutionTime(label: "Умножение (параллельное)") { completion in
    MatrixOperations.parallelMultiply(matrixA, matrixC, completion: completion)
}

Task {
    await measureAsyncExecutionTime(label: "Сложение (ассинхронно)") {
        try await MatrixOperations.parallelAddAsync(matrixA, matrixB)
    }

    await measureAsyncExecutionTime(label: "Умножение (ассинхронно)") {
        try await MatrixOperations.parallelMultiplyAsync(matrixA, matrixC)
    }
}

RunLoop.main.run()
