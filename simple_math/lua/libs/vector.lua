local vec = FindMetaTable("Vector")

-- Calculation of vector length / Вычисление длины вектора
function vec:Length()
    -- Оптимизация : Избегаем повторных вычислений и сохраняем результат в переменную
    -- Optimization: Avoid repeated calculations and save the result in a variable
    local squaredLength = self.x ^ 2 + self.y ^ 2 + self.z ^ 2
    return math.sqrt(squaredLength)
end

-- Calculating the distance between a vector and a given position / Вычисление расстояния между вектором и заданной позицией
function vec:Distance(pos)
    -- Оптимизация : Избегаем повторных вычислений и сохраняем результат в переменную
    -- Optimization: Avoid repeated calculations and save the result in a variable
    local v = self - pos
    local squaredDistance = v.x ^ 2 + v.y ^ 2 + v.z ^ 2
    return math.sqrt(squaredDistance)
end

-- Vector normalization / Нормализация вектора
function vec.Normalize(v)
    -- Оптимизация : Переиспользуем ранее вычисленную длину вектора
    -- Optimization : Reuse previously calculated vector length
    local length = v:Length()
    return Vector(v.x / length, v.y / length, v.z / length)
end

-- Obtaining a normalized version of the vector / Получение нормализованной версии вектора
function vec:GetNormalized()
    -- Оптимизация : Переиспользуем ранее вычисленную длину вектора
    -- Optimization : Reuse previously calculated vector length
    local length = self:Length()
    return Vector(self.x / length, self.y / length, self.z / length)
end

-- Calculation of the scalar product of two vectors / Вычисление скалярного произведения двух векторов
function vec.Dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end
