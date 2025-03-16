import Foundation

class CustomBarrier {
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
            // Если это последний поток, освобождаем всех
            for _ in 1..<totalThreads {
                semaphore.signal()
            }
            count = 0 // Сбрасываем для повторного использования
        } else {
            // Ждем, пока последний поток не разблокирует барьер
            semaphore.wait()
        }
    }
}

func task5() {
    let barrier = CustomBarrier(threadCount: 3)

    for i in 1...3 {
        DispatchQueue.global(qos: .background).async {
            print("🔹 Поток \(i) выполняет первую часть работы")
            sleep(1)
            
            print("⏳ Поток \(i) ждет у барьера")
            barrier.wait()
            
            print("✅ Поток \(i) продолжает выполнение после барьера")
        }
    }
    
    sleep(5)
}

