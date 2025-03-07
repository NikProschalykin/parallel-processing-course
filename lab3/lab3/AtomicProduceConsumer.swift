import Foundation
import Atomics

class AtomicProducerConsumerQueue<T> {
    private var buffer: [T] = []
    private let maxSize: Int
    private let accessQueue = DispatchQueue(label: "ProducerConsumerQueue", attributes: .concurrent)
    
    private let isEmpty = ManagedAtomic<Bool>(true)
    private let isFull: ManagedAtomic<Bool>

    init(size: Int) {
        self.maxSize = size
        self.isFull = ManagedAtomic<Bool>(false)
    }

    func produce(_ item: T) {
        while isFull.load(ordering: .relaxed) { usleep(100) } // Ждем, пока очередь освободится
        
        accessQueue.async(flags: .barrier) {
            self.buffer.append(item)
            print("Produced: \(item). Buffer: \(self.buffer)")
            self.isEmpty.store(false, ordering: .relaxed) // Теперь очередь не пуста
            if self.buffer.count >= self.maxSize {
                self.isFull.store(true, ordering: .relaxed) // Заполняемость очереди
            }
        }
    }

    func consume() -> T? {
        while isEmpty.load(ordering: .relaxed) { usleep(100) } // Ждем, пока появится элемент
        
        var item: T?
        accessQueue.sync {
            if !self.buffer.isEmpty {
                item = self.buffer.removeFirst()
                print("Consumed: \(String(describing: item)). Buffer: \(self.buffer)")
                self.isFull.store(false, ordering: .relaxed) // Теперь есть место
                if self.buffer.isEmpty {
                    self.isEmpty.store(true, ordering: .relaxed) // Очередь пуста
                }
            }
        }
        return item
    }
}

func task3() {
    // Создаем очередь с буфером на 5 элементов
    let queue = AtomicProducerConsumerQueue<Int>(size: 5)

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


