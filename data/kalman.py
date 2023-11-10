import re
import matplotlib.pyplot as plt

BOUNDARIES = [
    2658344,
    2793588,
    4109408,
    4143953,
    4215710,
    4215805,
    4239169,
    4239264,
    4241721,
    4242648,
    4242739
]

LENGTH = 36


def get_data(file: str) -> list[int]:
    with open(file, mode='r', encoding='utf-8') as f:
        result = re.findall(r'aep_cycles\(-100\)=(\d+)', f.read())
    return [int(_) for _ in result]


class KalmanFilter1D:
    def __init__(self, initial_state, initial_covariance, process_variance, measurement_variance):
        # Initial estimates
        self.estimated_state = initial_state
        self.estimated_covariance = initial_covariance

        # Variance
        self.process_variance = process_variance
        self.measurement_variance = measurement_variance

    def predict(self, control_input=0, control_matrix=0):
        # In the 1D case, A = 1, B = control_matrix, u = control_input
        # Predicted state estimate: x̂(k|k-1) = A*x̂(k-1|k-1) + B*u(k)
        self.estimated_state = self.estimated_state + control_matrix * control_input

        # Predicted estimate covariance: P(k|k-1) = A*P(k-1|k-1)*A' + Q
        self.estimated_covariance = self.estimated_covariance + self.process_variance
        return self.estimated_state

    def update(self, measurement):
        # Kalman gain: K = P(k|k-1) / (P(k|k-1) + R)
        kalman_gain = self.estimated_covariance / (self.estimated_covariance + self.measurement_variance)

        # Updated state estimate: x̂(k|k) = x̂(k|k-1) + K*(z(k) - x̂(k|k-1))
        self.estimated_state = self.estimated_state + kalman_gain * (measurement - self.estimated_state)

        # Updated estimate covariance: P(k|k) = (1-K)*P(k|k-1)
        self.estimated_covariance = (1 - kalman_gain) * self.estimated_covariance
        return self.estimated_state


if __name__ == "__main__":
    result = get_data('test/output_mnist_lenet_m5d22y2023_h22m13s11.txt')


    for b in BOUNDARIES:
        kf = KalmanFilter1D(initial_state=result[b], initial_covariance=1, process_variance=0.01, measurement_variance=0.5)
        predicted = []
        estimated = []
        for m in result[b:b+LENGTH]:
            predicted.append(kf.predict())
            estimated.append(kf.update(m))

        print(f"{b}: {sum(result[b:b+LENGTH])/LENGTH:.1f} {sum(predicted)/LENGTH:.1f} {sum(estimated)/LENGTH:.1f}")

        plt.figure(figsize=(24, 4))
        plt.plot(list(range(LENGTH)), result[b:b+LENGTH])
        plt.plot(list(range(LENGTH)), predicted)
        plt.plot(list(range(LENGTH)), estimated)
        plt.savefig(f'{b}.png')
