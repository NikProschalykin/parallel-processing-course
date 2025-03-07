import Foundation

class ThreadSafeQueue<T> {
    private var queue: [T] = []
    private let accessQueue = DispatchQueue(label: "ThreadSafeQueue", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 1)

    func enqueue(_ element: T) {
        accessQueue.async(flags: .barrier) {
            self.queue.append(element)
        }
    }

    func dequeue() -> T? {
        var element: T?
        accessQueue.sync {
            if !self.queue.isEmpty {
                element = self.queue.removeFirst()
            }
        }
        return element
    }

    func isEmpty() -> Bool {
        var result = false
        accessQueue.sync {
            result = self.queue.isEmpty
        }
        return result
    }

    func count() -> Int {
        var result = 0
        accessQueue.sync {
            result = self.queue.count
        }
        return result
    }
}
