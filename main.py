import pyautogui
import time
import random
import sys

# Получаем размеры экрана
screen_width, screen_height = pyautogui.size()

while True:
    # Генерируем случайные координаты
    x = random.randint(0, screen_width - 1)
    y = random.randint(0, screen_height - 1)
    
    # Перемещаем курсор к случайной позиции
    pyautogui.moveTo(x, y, duration=0.1)
    
    # Небольшая пауза
    time.sleep(0.1)
    
    # Проверяем текущую позицию
    current_x, current_y = pyautogui.position()
    
    # Если позиция не совпадает, значит пользователь двинул курсор
    if current_x != x or current_y != y:
        sys.exit()
