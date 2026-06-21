import numpy as np
import matplotlib.pyplot as plt
import random
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn.datasets import fetch_openml
import joblib


def load_mnist():
    """
    Загружает датасет MNIST с рукописными цифрами
    """
    mnist = fetch_openml('mnist_784', version=1, as_frame=False)
    X = mnist.data.astype('float32')
    y = mnist.target.astype('int')
    class_names = [str(i) for i in range(10)]
    print(f"MNIST загружен: {X.shape[0]} изображений")
    return X, y, class_names


def generate_shape_image(shape, size=28):
    """
    Генерирует одно изображение геометрической фигуры
    """
    img = np.zeros((size, size), dtype=np.float32)
    center = size // 2

    if shape == "circle":
        radius = random.randint(9, 12)
        y, x = np.ogrid[:size, :size]
        mask = (x - center)**2 + (y - center)**2 <= radius**2
        img[mask] = 1.0

    elif shape == "square":
        side = random.randint(14, 18)
        start = center - side // 2
        img[start:start + side, start:start + side] = 1.0

    elif shape == "triangle":
        height = random.randint(16, 20)
        base = random.randint(16, 20)
        start_y = center - height // 2
        for i in range(height):
            width = int(base * (i / height))
            start_x = center - width // 2
            img[start_y + i, start_x:start_x + width] = 1.0

    return img.flatten()


def generate_shapes_dataset(n_samples=5000):
    """
    Создает синтетический датасет из фигур
    """
    shapes = ["circle", "square", "triangle"]
    X = []
    y = []

    for _ in range(n_samples):
        shape = random.choice(shapes)
        X.append(generate_shape_image(shape))
        y.append(shape)
    
    X = np.array(X)
    y = np.array(y)
    class_names = ["circle", "square", "triangle"]
    
    # Преобразование названий в числа
    label_to_idx = {name: i for i, name in enumerate(class_names)}
    y_numeric = np.array([label_to_idx[s] for s in y])
    
    return X, y_numeric, class_names


def plot_examples(model, X_test, y_test, class_names, n=10, title="Примеры распознавания"):
    """
    Отображает примеры изображений с предсказаниями модели
    """
    plt.figure(figsize=(16, 8))
    indices = np.random.choice(len(X_test), n, replace=False)
    
    for i, idx in enumerate(indices):
        img = X_test[idx].reshape(28, 28)
        true_label = class_names[y_test[idx]]
        pred_label = class_names[model.predict([X_test[idx]])[0]]
        
        color = 'green' if true_label == pred_label else 'red'
        
        plt.subplot(2, 5, i + 1)
        plt.imshow(img, cmap='gray')
        plt.title(f'Реально: {true_label}\nПредсказано: {pred_label}', color=color)
        plt.axis('off')
    
    plt.suptitle(title)
    plt.tight_layout()
    plt.show()


def main():
    print("1 - Рукописные цифры (MNIST)")
    print("2 - Геометрические фигуры (круг, квадрат, треугольник)")
    
    choice = int(input("Выберите (1 или 2): "))

    if choice == 1:
        X, y, class_names = load_mnist()
        examples_title = "Примеры распознавания рукописных цифр"
        model_filename = "random_forest_mnist.pkl"
    elif choice == 2:
        X, y, class_names = generate_shapes_dataset(5000)
        examples_title = "Примеры распознавания геометрических фигур"
        model_filename = "random_forest_shapes.pkl"

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y
    )

    model = RandomForestClassifier(n_estimators=200, n_jobs=-1, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    print(f"Точность модели: {accuracy:.4f} ({accuracy*100:.2f}%)")

    plot_examples(model, X_test, y_test, class_names, n=10, title=examples_title)

    joblib.dump(model, model_filename)
    print(f"Модель сохранена в файл: {model_filename}")


if __name__ == "__main__":
    main()