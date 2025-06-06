# Glibus - Advanced Optimization Library for Garry's Mod
## 📦 Установка

1. Скопируйте папку `Glibus` в ваш аддон или gamemode
2. Библиотеки загрузятся автоматически через `autorun`
3. Настройте конфигурацию через `GlibusConfig`

## ⚙️ Конфигурация

### Базовая настройка
```lua
-- Установить лимит памяти
GlibusConfig.Set("memory.limit_kb", 1024)

-- Включить дистанционное отсечение
GlibusConfig.Set("entities.distance_culling", true)

-- Настроить сжатие сети
GlibusConfig.Set("networking.compression_enabled", true)
```

### Пресеты производительности
```lua
-- Максимальная производительность
GlibusConfig.ApplyPreset("performance")

-- Максимальное качество
GlibusConfig.ApplyPreset("quality")

-- Сбалансированный режим
GlibusConfig.ApplyPreset("balanced")
```

## 🔧 API Документация

### Управление памятью
```lua
-- Получить/вернуть объекты из пула
local vec = MemoryManager.getVector(0, 0, 0)
MemoryManager.returnVector(vec)

-- Принудительная очистка
MemoryManager.cleanup()

-- Статистика
local stats = MemoryManager.stats()
```

### Рендеринг
```lua
-- Оптимизированное рисование
render.DrawRect(x, y, w, h, color)
render.DrawCircle(x, y, radius, segments, color)

-- Батчинг операций
render.QueueRect(x, y, w, h, color)
render.FlushBatch()

-- Кэшированные материалы
local mat = render.GetMaterial("path/to/material")
```

### Физика
```lua
-- Оптимизированные трейсы
local trace = physics.TraceLine(start, endpos, filter)

-- Поиск энтити в радиусе
local entities = physics.FindEntitiesInSphere(center, radius)

-- Батчинг физических операций
physics.QueuePhysicsUpdate(ent, pos, ang, vel, angvel)
physics.FlushPhysicsBatch()
```

### Сетевое взаимодействие
```lua
-- Отправка оптимизированных сообщений
Networking.Send("MessageName", data, targets, reliable)

-- Получение сообщений
Networking.Receive("MessageName", function(data, ply)
    -- Обработка данных
end)

-- Батчинг сообщений
local batch = Networking.StartBatch(target)
Networking.AddToBatch(batch, "Message1", data1)
Networking.SendBatch(batch, target)
```

### Управление энтити
```lua
-- Регистрация энтити
EntityManager.Register(ent, EntityManager.CATEGORIES.NORMAL)

-- Проверка видимости
if EntityManager.IsVisible(ent) then
    -- Рендерить энтити
end

-- Получение LOD уровня
local lod = EntityManager.GetLOD(ent)
```

### База данных
```lua
-- Выполнение запросов с кэшированием
local result = Database.Query("SELECT * FROM table WHERE id = ?", {id})

-- Батчинг операций
Database.AddToBatch("INSERT INTO table VALUES (?, ?)", {val1, val2})
Database.FlushBatch()

-- Транзакции
local results = Database.Transaction({
    {query = "INSERT INTO table1 VALUES (?)", params = {value1}},
    {query = "UPDATE table2 SET field = ?", params = {value2}}
})
```

## 📈 Мониторинг производительности

### Консольные команды
```
glibus_performance_report     - Показать отчет о производительности
glibus_performance_export     - Экспортировать данные производительности
glibus_config_get <path>      - Получить значение конфигурации
glibus_config_set <path> <val> - Установить значение конфигурации
glibus_config_preset <name>   - Применить пресет конфигурации
```

### Профилирование кода
```lua
-- Начать профилирование
PerformanceMonitor.StartProfile("MyFunction")

-- Ваш код здесь

-- Завершить профилирование
local result = PerformanceMonitor.EndProfile("MyFunction")
print("Время выполнения:", result.duration)
```

### Получение статистики
```lua
-- Статистика производительности
local stats = PerformanceMonitor.GetStats()
print("Текущий FPS:", stats.fps.current)
print("Использование памяти:", stats.memory.current)

-- Последние алерты
local alerts = PerformanceMonitor.GetAlerts(10)
```

## 🎯 Рекомендации по оптимизации

### Для разработчиков
1. **Используйте пулы объектов** для часто создаваемых Vector/Angle
2. **Кэшируйте материалы** вместо создания новых
3. **Батчите операции** рендеринга и физики
4. **Ограничивайте дистанцию** обновления энтити
5. **Используйте LOD** для дальних объектов

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 🆘 Поддержка

Если у вас возникли проблемы:
1. Проверьте консоль на ошибки
2. Используйте `glibus_performance_report`
3. Экспортируйте данные производительности
4. Создайте issue с подробным описанием