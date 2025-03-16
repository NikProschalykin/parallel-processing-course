import Foundation

class ReductionBarrier {
    private let totalThreads: Int
    private var count: Int = 0
    private let lock = NSLock()
    private let semaphore = DispatchSemaphore(value: 0)
    
    init(threadCount: Int) {
        self.totalThreads = threadCount
    }
    
    func wait() {
        lock.lock()
        count += 1
        let isLast = count == totalThreads
        lock.unlock()
        
        if isLast {
            for _ in 1..<totalThreads {
                semaphore.signal()
            }
            count = 0
        } else {
            semaphore.wait()
        }
    }
}

enum ReductionOperation {
    case sum
    case product
}

func parallelReduce(array: [Float], operation: ReductionOperation, maxThreads: Int) -> Float {
    let barrier = ReductionBarrier(threadCount: maxThreads)
    let chunkSize = (array.count + maxThreads - 1) / maxThreads // Разделение массива на куски
    var partialResults = Array(repeating: (operation == .sum ? 0.0 : 1.0), count: maxThreads)
    
    let queue = DispatchQueue.global(qos: .userInitiated)
    let group = DispatchGroup()
    
    for threadIndex in 0..<maxThreads {
        group.enter()
        queue.async {
            let start = threadIndex * chunkSize
            let end = min(start + chunkSize, array.count)
            
            if start < end {
                if operation == .sum {
                    partialResults[threadIndex] = Double(array[start..<end].reduce(0, +))
                } else {
                    partialResults[threadIndex] = Double(array[start..<end].reduce(1, *))
                }
            }
            
            print("🔹 Поток \(threadIndex) вычислил: \(partialResults[threadIndex])")
            
            barrier.wait()
            
            group.leave()
        }
    }
    
    group.wait()
    
    let result = (operation == .sum) ? partialResults.reduce(0, +) : partialResults.reduce(1, *)
    
    return Float(result)
}

func task6() {
    let array: [Float] = Array(1...10).map { Float($0) }
    let sumResult = parallelReduce(array: array, operation: .sum, maxThreads: 3)
    let productResult = parallelReduce(array: array, operation: .product, maxThreads: 3)

    print("✅ Сумма: \(sumResult)")
    print("✅ Произведение: \(productResult)")
}

