# GLua FastPath

Набор низкоуровневых оптимизаций для **Garry's Mod / LuaJIT**.

GLua FastPath не является универсальным «FPS booster». Проект заменяет стандартную систему `hook` собственной реализацией и добавляет несколько функций для `math` и `Vector`.

Основная цель - уменьшить накладные расходы в горячих Lua-путях, не заменяя быстрые нативные методы движка более медленным Lua-кодом.

> [!WARNING]
> Библиотека находится в экспериментальном состоянии. Замена глобального модуля `hook` влияет на весь сервер и клиентские аддоны. Перед использованием на сервере проверьте совместимость со своим набором аддонов.

## Возможности

### Оптимизированная система hooks

- плоские массивы callbacks в горячем пути;
- copy-on-write перестроение списков при добавлении и удалении hooks;
- обновление функции существующего hook за `O(1)`, если приоритет не изменился;
- приоритеты выполнения;
- pre/post hooks;
- автоматическое удаление hook, привязанного к невалидной Entity;
- кэширование текущего gamemode;
- совместимый интерфейс `hook.Add`, `hook.Remove`, `hook.Run`, `hook.Call` и `hook.GetTable`;
- частичная совместимость с ULib;
- предупреждение о конфликте с DLib.

### Математические функции

- `math.NormalizeAngleRad`;
- `math.Max2`, `math.Min2`;
- `math.Max3`, `math.Min3`;
- `math.MaxT`, `math.MinT`;
- `math.sincos`;
- приближённые `math.qsin` и `math.qcos`;
- детерминированный shared random generator.

### Расширения Vector

- `Vector:Clamp` и `Vector:GetClamped`;
- `Vector:Min`, `Vector:Max`;
- `Vector:GetMin`, `Vector:GetMax`;
- `Vector:ClampLength` и `Vector:GetClampedLength`;
- `Vector:LerpTo`.

Нативные методы вроде `Length`, `Distance`, `Dot`, `Cross`, `Normalize` и `DistToSqr` намеренно не переопределяются: реализации движка на C++ быстрее Lua-кода.

## Установка

Скопируйте каталог `glibus` в папку аддонов Garry's Mod:

```text
garrysmod/
└── addons/
    └── fastpath/
        └── lua/
            ├── autorun/
            │   └── libs_init.lua
            └── libs/
                ├── hook.lua
                ├── math.lua
                └── vector.lua
```

После запуска `libs_init.lua` загрузчик автоматически подключит библиотеки в server/client realms и выведет результат загрузки в консоль:

```text
[lib] loaded 3/3 in 0.0 ms
```

Отдельная конфигурация не требуется.

## Hook API
### Базовое использование

```lua
hook.Add("Think", "GlibusExample", function()
    local frameTime = FrameTime()
end)

hook.Remove("Think", "GlibusExample")
```

### Приоритеты
Числовые приоритеты ограничиваются диапазоном от `-2` до `2`:

```lua
hook.Add("PlayerSpawn", "BeforeMostHooks", function(ply)
end, HOOK_HIGH)

hook.Add("PlayerSpawn", "AfterMostHooks", function(ply)
end, HOOK_LOW)
```

| Константа | Значение | Поведение |
|---|---:|---|
| `HOOK_MONITOR_HIGH` | `-2` | Выполняется рано, return игнорируется |
| `HOOK_HIGH` | `-1` | Высокий приоритет |
| `HOOK_NORMAL` | `0` | Обычный приоритет |
| `HOOK_LOW` | `1` | Низкий приоритет |
| `HOOK_MONITOR_LOW` | `2` | Выполняется поздно, return игнорируется |

Дополнительные режимы:

| Константа | Поведение |
|---|---|
| `PRE_HOOK` | Выполняется до обычных hooks, return игнорируется |
| `PRE_HOOK_RETURN` | Выполняется до обычных hooks и может вернуть результат |
| `NORMAL_HOOK` | Обычный hook |
| `POST_HOOK_RETURN` | Получает результат dispatch и может заменить его |
| `POST_HOOK` | Выполняется после dispatch, return игнорируется |

### Post hook
Первым аргументом post hook получает таблицу результата:

```lua
hook.Add("PlayerCanHearPlayersVoice", "InspectVoiceResult", function(result, listener, talker)
    local source = result[1]
    local canHear = result[2]
    local is3D = result[3]
end, POST_HOOK)
```

Для `POST_HOOK_RETURN` callback может вернуть новое значение события.

Функция выводит зарегистрированные callbacks, приоритеты и внутренние позиции.

## Math API
```lua
local normalized = math.NormalizeAngleRad(math.pi * 3)
local minimum = math.Min3(10, 5, 20)
local sine, cosine = math.sincos(1.25)
```

### Быстрые приближения

```lua
local approximateSine = math.qsin(angle)
local approximateCosine = math.qcos(angle)
```

`qsin`, `qcos` и `sincos` обменивают точность на скорость. Не используйте их там, где ошибка вычисления влияет на физику, сетевую синхронизацию или security checks.

### Детерминированный random

```lua
math.SharedRandomSeed(1337)

local integer = math.SharedRandom(1, 100)
local fastInteger = math.SharedRandomFast(1, 100)
local fraction = math.SharedRandomFloat()
```

Генератор имеет общее состояние внутри realm. Повторная установка одинакового seed воспроизводит последовательность только при одинаковом порядке вызовов.

## Vector API
Методы без префикса `Get` изменяют исходный Vector. Методы с `Get` создают новый Vector.

```lua
local position = Vector(150, -20, 500)
position:Clamp(Vector(0, 0, 0), Vector(100, 100, 100))

local direction = Vector(100, 50, 25)
direction:ClampLength(32)

local interpolated = Vector(0, 0, 0)
interpolated:LerpTo(Vector(100, 100, 100), 0.5)
```

## Совместимость
- Garry's Mod LuaJIT;
- server и client realms;
- ULib: FastPath пытается предотвратить загрузку hook-библиотеки ULib;
- DLib: обнаруживается как потенциальный конфликт, но автоматически не отключается.


## Структура проекта
```text
glibus/
├── lua/
│   ├── autorun/
│   │   └── libs_init.lua
│   └── libs/
│       ├── hook.lua
│       ├── math.lua
│       └── vector.lua
└── README.md
```

## Credits
Основные части проекта основаны на работе других разработчиков:

- **Hook system:** [Srlion](https://github.com/Srlion) — исходная архитектура и семантика priority hooks. Текущая версия переработана под flat arrays, segmented dispatch и copy-on-write обновление списков.
- **Math library:** [trojanhoes](https://github.com/trojanhoes) — основа математических helpers и быстрых приближений.

Все последующие изменения, интеграция и оптимизации должны сохранять эти attribution notices.
