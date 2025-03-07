import Foundation

class ProducerConsumerQueue<T> {
    private var buffer: [T] = []
    private let maxSize: Int
    private let accessQueue = DispatchQueue(label: "ProducerConsumerQueue", attributes: .concurrent)
    private let notEmpty = DispatchSemaphore(value: 0) // Ожидание, если очередь пуста
    private let notFull: DispatchSemaphore
    private let lock = NSLock()

    init(size: Int) {
        self.maxSize = size
        self.notFull = DispatchSemaphore(value: size) // Контролирует заполненность
    }

    func produce(_ item: T) {
        notFull.wait() // Ждет, если очередь заполнена
        lock.lock()
        buffer.append(item)
        print("Produced: \(item). Buffer: \(buffer)")
        lock.unlock()
        notEmpty.signal() // Уведомляет потребителей, что есть элемент
    }

    func consume() -> T? {
        notEmpty.wait() // Ждет, если очередь пуста
        lock.lock()
        let item = buffer.isEmpty ? nil : buffer.removeFirst()
        print("Consumed: \(String(describing: item)). Buffer: \(buffer)")
        lock.unlock()
        notFull.signal() // Уведомляет производителей, что появилось место
        return item
    }
}

func task2() {
    // Создаем очередь с буфером на 5 элементов
    let queue = ProducerConsumerQueue<Int>(size: 5)

    // Запускаем производителей
    DispatchQueue.global(qos: .background).async {
        for i in 1...10 {
            queue.produce(i)
            usleep(500_000) // Задержка для наглядности
        }
    }

    // Запускаем потребителей
    DispatchQueue.global(qos: .background).async {
        for _ in 1...10 {
            _ = queue.consume()
            usleep(800_000) // Задержка для наглядности
        }
    }

    // Даем программе время на выполнение
    sleep(10)
}


