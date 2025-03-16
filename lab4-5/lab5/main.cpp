#include <iostream>
#include <cmath>
#include <chrono>
#include <mpi.h>

using namespace std;
using namespace std::chrono;

// Функция, подынтегральное выражение для π
double f(double x) {
    return 4.0 / (1.0 + x * x);
}

// ---------------------- 1. Последовательные методы ----------------------

// Метод прямоугольников
double integrate_rectangles_serial(int n) {
    double sum = 0.0, h = 1.0 / n;
    for (int i = 0; i < n; i++) {
        sum += f((i + 0.5) * h);
    }
    return sum * h;
}

// Метод трапеций
double integrate_trapezoidal_serial(int n) {
    double sum = (f(0) + f(1)) / 2.0, h = 1.0 / n;
    for (int i = 1; i < n; i++) {
        sum += f(i * h);
    }
    return sum * h;
}

// Метод Симпсона
double integrate_simpson_serial(int n) {
    if (n % 2 == 1) n++; // Должно быть четным
    double sum = f(0) + f(1), h = 1.0 / n;

    for (int i = 1; i < n; i += 2)
        sum += 4 * f(i * h);
    
    for (int i = 2; i < n; i += 2)
        sum += 2 * f(i * h);

    return sum * h / 3;
}

// ---------------------- 2. Параллельные версии (MPI) ----------------------

// Метод прямоугольников (MPI)
double integrate_rectangles_parallel(int n) {
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    double local_sum = 0.0, h = 1.0 / n;
    for (int i = rank; i < n; i += size) {
        local_sum += f((i + 0.5) * h);
    }
    local_sum *= h;

    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    return global_sum;
}

// Метод трапеций (MPI)
double integrate_trapezoidal_parallel(int n) {
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    double h = 1.0 / n, local_sum = 0.0;
    for (int i = rank + 1; i < n; i += size) {
        local_sum += f(i * h);
    }

    if (rank == 0)
        local_sum += (f(0) + f(1)) / 2.0;

    local_sum *= h;

    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    return global_sum;
}

// Метод Симпсона (MPI)
double integrate_simpson_parallel(int n) {
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (n % 2 == 1) n++; // Четное число разбиений
    double h = 1.0 / n, local_sum = 0.0;

    for (int i = rank + 1; i < n; i += size) {
        if (i % 2 == 0)
            local_sum += 2 * f(i * h);
        else
            local_sum += 4 * f(i * h);
    }

    if (rank == 0)
        local_sum += f(0) + f(1);

    local_sum *= h / 3.0;

    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    return global_sum;
}

// ---------------------- 3. Функция тестирования ----------------------
void test_integration(int n) {
    if (n < 1) return;

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    if (rank == 0) cout << "\nTesting with " << n << " intervals\n";

    auto start = high_resolution_clock::now();
    double pi_rect_serial = integrate_rectangles_serial(n);
    auto end = high_resolution_clock::now();
    if (rank == 0) cout << "Serial Rectangles: " << pi_rect_serial << " Time: " << duration<double>(end - start).count() << " s\n";

    start = high_resolution_clock::now();
    double pi_trap_serial = integrate_trapezoidal_serial(n);
    end = high_resolution_clock::now();
    if (rank == 0) cout << "Serial Trapezoidal: " << pi_trap_serial << " Time: " << duration<double>(end - start).count() << " s\n";

    start = high_resolution_clock::now();
    double pi_simpson_serial = integrate_simpson_serial(n);
    end = high_resolution_clock::now();
    if (rank == 0) cout << "Serial Simpson: " << pi_simpson_serial << " Time: " << duration<double>(end - start).count() << " s\n";

    // ---- Parallel versions ----
    start = high_resolution_clock::now();
    double pi_rect_parallel = integrate_rectangles_parallel(n);
    end = high_resolution_clock::now();
    if (rank == 0) cout << "Parallel Rectangles: " << pi_rect_parallel << " Time: " << duration<double>(end - start).count() << " s\n";

    start = high_resolution_clock::now();
    double pi_trap_parallel = integrate_trapezoidal_parallel(n);
    end = high_resolution_clock::now();
    if (rank == 0) cout << "Parallel Trapezoidal: " << pi_trap_parallel << " Time: " << duration<double>(end - start).count() << " s\n";

    start = high_resolution_clock::now();
    double pi_simpson_parallel = integrate_simpson_parallel(n);
    end = high_resolution_clock::now();
    if (rank == 0) cout << "Parallel Simpson: " << pi_simpson_parallel << " Time: " << duration<double>(end - start).count() << " s\n";
}

// ---------------------- 4. Main ----------------------
int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    test_integration(1000);
    test_integration(10000);
    test_integration(100000);

    MPI_Finalize();
    return 0;
}

// mpic++ lab5/main.cpp -o lab5/output
// mpirun -np 4 ./lab5/output