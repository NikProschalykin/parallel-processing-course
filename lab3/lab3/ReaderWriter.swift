import Foundation

class ReaderWriter {
    private var data: String = "Initial Data"
    private let queue = DispatchQueue(label: "ReaderWriterQueue", attributes: .concurrent)
    
    func readData(readerId: Int) {
        queue.sync {
            print("🔹 Reader \(readerId) reads: \(data)")
            usleep(500_000)
        }
    }
    
    func writeData(newData: String, writerId: Int) {
        queue.async(flags: .barrier) {
            print("✍️ Writer \(writerId) is writing...")
            usleep(800_000)
            self.data = newData
            print("✅ Writer \(writerId) updated data to: \(self.data)")
        }
    }
}

func task4() {
    let sharedResource = ReaderWriter()
    
    // Запуск нескольких читателей
    for i in 1...3 {
        DispatchQueue.global(qos: .background).async {
            for _ in 1...3 {
                sharedResource.readData(readerId: i)
            }
        }
    }
    
    // Запуск нескольких писателей
    for i in 1...2 {
        DispatchQueue.global(qos: .background).async {
            for j in 1...2 {
                sharedResource.writeData(newData: "Data from writer \(i)-\(j)", writerId: i)
            }
        }
    }
    
    sleep(5)
}
