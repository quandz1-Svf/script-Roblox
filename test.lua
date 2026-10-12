-- Скрипт для поиска уязвимости начисления денег в игре Roblox
-- Анализирует SpinRequest и другие Remote-объекты
-- Автор: palofsc
-- Версия: 2.0

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Ожидание Remote2
local Remote2 = ReplicatedStorage:WaitForChild("Remote2", 10)
if not Remote2 then
    warn("Remote2 не найден.")
    return
end
local RandomRemote = Remote2:WaitForChild("RandomRemote", 10)
if not RandomRemote then
    warn("RandomRemote не найден.")
    return
end
local SpinRequest = RandomRemote:WaitForChild("SpinRequest", 10)
if not SpinRequest then
    warn("SpinRequest не найден.")
    return
end

-- Получение текущего баланса Cash
local function getCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cash = leaderstats:FindFirstChild("Cash")
        if cash then
            return cash.Value
        end
    end
    return nil
end

-- Сохранение исходного баланса
local startCash = getCash()
print("Начальный баланс Cash: " .. tostring(startCash))

-- Функция вызова SpinRequest с аргументами
local function fireSpin(...)
    local args = {...}
    if SpinRequest:IsA("RemoteEvent") then
        SpinRequest:FireServer(unpack(args))
    elseif SpinRequest:IsA("RemoteFunction") then
        SpinRequest:InvokeServer(unpack(args))
    end
end

-- Перебор вариантов аргументов для SpinRequest
local spinArgs = {
    {-15},                          -- отрицательная ставка
    {-15000000},                    -- отрицательная большая сумма
    {15, true},                     -- ставка + флаг
    {-15, true},                    -- отрицательная ставка + флаг
    {Bet = -15},                    -- таблица с отрицательной ставкой
    {Amount = -15},                 -- таблица с отрицательной суммой
    {Value = -15},                  -- таблица со значением
    {"Spin", -15},                  -- строка + отрицательная ставка
    {"spin", -15},                  -- строка + отрицательная ставка
    {"Cash", -15},                  -- Cash + отрицательная сумма
    {"add", "Cash", 15000000},      -- add Cash 15M
    {"give", "Cash", 15000000},     -- give Cash 15M
    {"reward", "Cash", 15000000},   -- reward Cash 15M
}

-- Функция сканирования всех Remote-объектов
local function scanRemotes()
    local remotes = {}
    local function scan(container, path)
        for _, obj in ipairs(container:GetChildren()) do
            local objPath = path .. "." .. obj.Name
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(remotes, {Object = obj, Path = objPath, Name = obj.Name, ClassName = obj.ClassName})
            end
            if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("ScreenGui") then
                scan(obj, objPath)
            end
        end
    end
    scan(ReplicatedStorage, "ReplicatedStorage")
    scan(workspace, "Workspace")
    scan(Players, "Players")
    return remotes
end

-- Попытка вызова других Remote-объектов с денежными аргументами
local function tryOtherRemotes()
    local remotes = scanRemotes()
    for _, remote in ipairs(remotes) do
        local lowerName = remote.Name:lower()
        if lowerName:find("cash") or lowerName:find("money") or lowerName:find("reward") or lowerName:find("claim") or lowerName:find("daily") or lowerName:find("gift") or lowerName:find("bonus") then
            print("Попытка вызова: " .. remote.Path)
            local obj = remote.Object
            local success, err = pcall(function()
                if obj:IsA("RemoteEvent") then
                    obj:FireServer(15000000)
                    obj:FireServer("Cash", 15000000)
                    obj:FireServer(LocalPlayer, 15000000)
                    obj:FireServer("add", "Cash", 15000000)
                elseif obj:IsA("RemoteFunction") then
                    obj:InvokeServer(15000000)
                    obj:InvokeServer("Cash", 15000000)
                    obj:InvokeServer(LocalPlayer, 15000000)
                    obj:InvokeServer("add", "Cash", 15000000)
                end
            end)
            if not success then
                print("Ошибка: " .. tostring(err))
            end
        end
    end
end

-- Основной цикл
while true do
    -- Попытка эксплуатировать SpinRequest отрицательными ставками
    for _, args in ipairs(spinArgs) do
        fireSpin(unpack(args))
        wait(0.1)
        local currentCash = getCash()
        if currentCash and startCash and currentCash > startCash then
            print("УСПЕХ! Баланс увеличен с " .. startCash .. " до " .. currentCash)
            return
        end
    end
    
    -- Попытка других Remote-объектов
    tryOtherRemotes()
    wait(1)
    
    -- Проверка баланса
    local currentCash = getCash()
    if currentCash and startCash and currentCash > startCash then
        print("УСПЕХ! Баланс увеличен с " .. startCash .. " до " .. currentCash)
        return
    end
end