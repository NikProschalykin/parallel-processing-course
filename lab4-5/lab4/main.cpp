#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>
#include <omp.h>

using namespace std;

// ---------------------- 1. Численное интегрирование для вычисления π ----------------------
double integrate_pi_serial(int num_intervals) {
    double sum = 0.0;
    double width = 1.0 / num_intervals;

    for (int i = 0; i < num_intervals; i++) {
        double x = (i + 0.5) * width;
        sum += 4.0 / (1.0 + x * x);
    }
    
    return sum * width;
}

double integrate_pi_parallel(int num_intervals) {
    double sum = 0.0;
    double width = 1.0 / num_intervals;

    #pragma omp parallel
    {
        double local_sum = 0.0;
        #pragma omp for
        for (int i = 0; i < num_intervals; i++) {
            double x = (i + 0.5) * width;
            local_sum += 4.0 / (1.0 + x * x);
        }
        #pragma omp atomic
        sum += local_sum;
    }
    
    return sum * width;
}

// ---------------------- 2. Сортировка выбором (Selection Sort) ----------------------
void selection_sort_serial(vector<int>& arr) {
    int n = arr.size();
    for (int i = 0; i < n - 1; i++) {
        int min_idx = i;
        for (int j = i + 1; j < n; j++) {
            if (arr[j] < arr[min_idx])
                min_idx = j;
        }
        swap(arr[i], arr[min_idx]);
    }
}

void selection_sort_parallel(vector<int>& arr, int num_threads) {
    int n = arr.size();
    
    #pragma omp parallel for num_threads(num_threads)
    for (int i = 0; i < n - 1; i++) {
        int min_idx = i;
        for (int j = i + 1; j < n; j++) {
            if (arr[j] < arr[min_idx])
                min_idx = j;
        }
        swap(arr[i], arr[min_idx]);
    }
}

// ---------------------- 3. Умножение матриц ----------------------
class Matrix {
public:
    vector<vector<int> > mat;
    int rows, cols;

    Matrix(int r, int c) : rows(r), cols(c) {
        mat.resize(r, vector<int>(c, 0));
    }

    void fill_random() {
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++)
                mat[i][j] = rand() % 10;
    }

    static Matrix multiply_serial(const Matrix& A, const Matrix& B) {
        Matrix C(A.rows, B.cols);
        for (int i = 0; i < A.rows; i++)
            for (int j = 0; j < B.cols; j++)
                for (int k = 0; k < A.cols; k++)
                    C.mat[i][j] += A.mat[i][k] * B.mat[k][j];
        return C;
    }

    static Matrix multiply_parallel(const Matrix& A, const Matrix& B, int num_threads) {
        Matrix C(A.rows, B.cols);
        
        #pragma omp parallel for num_threads(num_threads)
        for (int i = 0; i < A.rows; i++)
            for (int j = 0; j < B.cols; j++)
                for (int k = 0; k < A.cols; k++)
                    C.mat[i][j] += A.mat[i][k] * B.mat[k][j];
        
        return C;
    }
};

// ---------------------- Функция main ----------------------
int main() {
    srand(time(0));

    // 1. Вычисление числа π
    int num_intervals = 1000000;
    double start_time, end_time;

    start_time = omp_get_wtime();
    double pi_serial = integrate_pi_serial(num_intervals);
    end_time = omp_get_wtime();
    cout << "Serial Pi: " << pi_serial << " Time: " << (end_time - start_time) << " s\n";

    start_time = omp_get_wtime();
    double pi_parallel = integrate_pi_parallel(num_intervals);
    end_time = omp_get_wtime();
    cout << "Parallel Pi: " << pi_parallel << " Time: " << (end_time - start_time) << " s\n\n";

    // 2. Сортировка выбором
    vector<int> arr(5000);
    for (int& x : arr) x = rand() % 10000;

    vector<int> arr_copy = arr;

    start_time = omp_get_wtime();
    selection_sort_serial(arr);
    end_time = omp_get_wtime();
    cout << "Serial Selection Sort Time: " << (end_time - start_time) << " s\n";

    start_time = omp_get_wtime();
    selection_sort_parallel(arr_copy, 4);
    end_time = omp_get_wtime();
    cout << "Parallel Selection Sort Time (4 threads): " << (end_time - start_time) << " s\n\n";

    // 3. Умножение матриц
    int size = 200;
    Matrix A(size, size);
    Matrix B(size, size);
    A.fill_random();
    B.fill_random();

    start_time = omp_get_wtime();
    Matrix C_serial = Matrix::multiply_serial(A, B);
    end_time = omp_get_wtime();
    cout << "Serial Matrix Multiplication Time: " << (end_time - start_time) << " s\n";

    start_time = omp_get_wtime();
    Matrix C_parallel = Matrix::multiply_parallel(A, B, 4);
    end_time = omp_get_wtime();
    cout << "Parallel Matrix Multiplication Time (4 threads): " << (end_time - start_time) << " s\n";

    return 0;
}

// g++ -Xpreprocessor -fopenmp -I/opt/homebrew/opt/libomp/include -L/opt/homebrew/opt/libomp/lib -lomp lab4/main.cpp -o lab4/output
// ./lab4/output 
