#include <iostream>
#include <cmath>
#include <chrono>
#include <simd/simd.h> // Apple SIMD API

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

double f(double x) {
    return 4.0 / (1.0 + x * x);
}

//метод прямоугольников
double rectangle_integral_simd(int n) {
    const double h = 1.0 / n;
    simd_double4 sum = {0.0, 0.0, 0.0, 0.0};

    for (int i = 0; i < n; i += 4) {
        simd_double4 idx = {i + 0.5, i + 1.5, i + 2.5, i + 3.5};
        simd_double4 x = idx * h;
        simd_double4 y = 4.0 / (1.0 + x * x);
        sum += y;
    }

    return (sum[0] + sum[1] + sum[2] + sum[3]) * h;
}

//метод трапеций
double trapezoidal_integral_simd(int n) {
    const double h = 1.0 / n;
    simd_double4 sum = {0.0, 0.0, 0.0, 0.0};

    for (int i = 1; i < n - 3; i += 4) {
        simd_double4 idx = {static_cast<double>(i), static_cast<double>(i + 1), static_cast<double>(i + 2), static_cast<double>(i + 3)};
        simd_double4 x = idx * h;
        simd_double4 y = 4.0 / (1.0 + x * x);
        sum += y;
    }

    double scalar_sum = 0.0;
    for (int i = ((n - 1) / 4) * 4 + 1; i < n; ++i) {
        scalar_sum += f(i * h);
    }

    return (0.5 * (f(0.0) + f(1.0)) + sum[0] + sum[1] + sum[2] + sum[3] + scalar_sum) * h;
}

//метода Симпсона
double simpson_integral_simd(int n) {
    if (n % 2 != 0) n++;
    const double h = 1.0 / n;
    simd_double4 sum_even = {0.0, 0.0, 0.0, 0.0};
    simd_double4 sum_odd = {0.0, 0.0, 0.0, 0.0};

    for (int i = 1; i < n; i += 4) {
        simd_double4 idx = {static_cast<double>(i), static_cast<double>(i + 1), static_cast<double>(i + 2), static_cast<double>(i + 3)};
        simd_double4 x = idx * h;
        simd_double4 y = 4.0 / (1.0 + x * x);

        simd_double4 coeff = {
            (i % 2 == 0) ? 2.0 : 4.0,
            ((i + 1) % 2 == 0) ? 2.0 : 4.0,
            ((i + 2) % 2 == 0) ? 2.0 : 4.0,
            ((i + 3) % 2 == 0) ? 2.0 : 4.0
        };

        simd_double4 weighted = y * coeff;

        for (int j = 0; j < 4; ++j) {
            if ((i + j) % 2 == 0) {
                sum_even[j] += weighted[j];
            } else {
                sum_odd[j] += weighted[j];
            }
        }
    }

    double total = f(0.0) + f(1.0);
    total += sum_even[0] + sum_even[1] + sum_even[2] + sum_even[3];
    total += sum_odd[0] + sum_odd[1] + sum_odd[2] + sum_odd[3];

    return total * h / 3.0;
}

//без SIMD
double rectangle_integral(int n) {
    const double h = 1.0 / n;
    double sum = 0.0;
    for (int i = 0; i < n; i++) {
        double x = (i + 0.5) * h;
        sum += f(x);
    }
    return sum * h;
}

//без SIMD
double trapezoidal_integral(int n) {
    const double h = 1.0 / n;
    double sum = 0.5 * (f(0.0) + f(1.0));
    for (int i = 1; i < n; i++) {
        double x = i * h;
        sum += f(x);
    }
    return sum * h;
}

//без SIMD
double simpson_integral(int n) {
    if (n % 2 != 0) n++;
    const double h = 1.0 / n;
    double sum = f(0.0) + f(1.0);
    
    for (int i = 1; i < n; i++) {
        double x = i * h;
        sum += (i % 2 == 0) ? 2.0 * f(x) : 4.0 * f(x);
    }
    return sum * h / 3.0;
}

template<typename Func>
void test(const std::string& name, Func func, int n) {
    auto start = std::chrono::high_resolution_clock::now();
    double pi = func(n);
    auto end = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double> elapsed = end - start;
    std::cout << name << "\n";
    std::cout << "π ≈ " << pi << " (Ошибка: " << fabs(M_PI - pi) << ")\n";
    std::cout << "Время: " << elapsed.count() << "s\n\n";
}

int main() {
    const int n = 1000000000;

    test("Прямоугольники без SIMD", rectangle_integral, n);
    test("Прямоугольники с SIMD", rectangle_integral_simd, n);
    test("Трапеции без SIMD", trapezoidal_integral, n);
    test("Трапеции с SIMD", trapezoidal_integral_simd, n);
    test("Симпсон без SIMD", simpson_integral, n);
    test("Симпсон с SIMD", simpson_integral_simd, n);

    return 0;
}
