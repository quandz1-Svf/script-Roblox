-- Скрипт автоматического перемещения между сиденьями TreoTien и TreoTienVIP
-- Приоритет: TreoTienVIP
-- Автор: palofsc
-- Версия: 1.0

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- ===== НАСТРОЙКИ =====
local enabled = false
local delayMs = 500 -- задержка между сиденьями в миллисекундах
local currentIndex = 1
local seatsList = {}
local isSitting = false
local lastSeat = nil

-- ===== ПОИСК СИДЕНИЙ =====
local function findSeats()
    local vipSeats = {}
    local normalSeats = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- Проверяем, является ли объект сиденьем (класс Seat или VehicleSeat)
        local seat = nil
        if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
            seat = obj
        elseif obj:IsA("BasePart") then
            -- Если это часть, ищем внутри неё Seat
            local childSeat = obj:FindFirstChildWhichIsA("Seat") or obj:FindFirstChildWhichIsA("VehicleSeat")
            if childSeat then
                seat = childSeat
            end
        end
        
        if seat then
            local name = seat.Name
            if name == "TreoTienVIP" then
                table.insert(vipSeats, seat)
            elseif name == "TreoTien" then
                table.insert(normalSeats, seat)
            end
        end
    end
    
    -- Объединяем: сначала VIP, потом обычные
    local result = {}
    for _, s in ipairs(vipSeats) do table.insert(result, s) end
    for _, s in ipairs(normalSeats) do table.insert(result, s) end
    return result
end

-- ===== ОБНОВЛЕНИЕ СПИСКА СИДЕНИЙ =====
local function refreshSeats()
    seatsList = findSeats()
    if #seatsList == 0 then
        warn("Сиденья TreoTien/TreoTienVIP не найдены!")
    else
        print("Найдено сидений: " .. #seatsList)
    end
end

-- ===== ФУНКЦИЯ ПЕРЕСАДКИ =====
local function sitOnSeat(seat)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    
    -- Встаём с текущего сиденья
    humanoid.Sit = false
    wait(0.1)
    
    -- Телепортируемся к сиденью и садимся
    if seat then
        -- Используем метод Sit, который телепортирует и сажает
        seat:Sit(humanoid)
        lastSeat = seat
        isSitting = true
    end
end

-- ===== ОСНОВНОЙ ЦИКЛ =====
local function mainLoop()
    while enabled do
        if #seatsList == 0 then
            refreshSeats()
            wait(1)
        else
            local seat = seatsList[currentIndex]
            if seat and seat.Parent then
                sitOnSeat(seat)
                -- Ожидание указанной задержки
                wait(delayMs / 1000)
                -- Переход к следующему сиденью
                currentIndex = currentIndex + 1
                if currentIndex > #seatsList then
                    currentIndex = 1
                end
            else
                -- Если сиденье исчезло, обновляем список
                refreshSeats()
                currentIndex = 1
                wait(0.5)
            end
        end
        wait(0.05)
    end
end

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeatTeleportGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 120)
Frame.Position = UDim2.new(0.5, -110, 0.5, -60)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Авто-сиденья"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.1, 0, 0, 35)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "ВЫКЛ"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = Frame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = ToggleBtn

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 75)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Задержка (мс):"
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = Frame

local DelayInput = Instance.new("TextBox")
DelayInput.Size = UDim2.new(0.3, 0, 0, 24)
DelayInput.Position = UDim2.new(0.6, 0, 0, 73)
DelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.Font = Enum.Font.Gotham
DelayInput.TextSize = 12
DelayInput.Text = tostring(delayMs)
DelayInput.Parent = Frame

local DelayCorner = Instance.new("UICorner")
DelayCorner.CornerRadius = UDim.new(0, 4)
DelayCorner.Parent = DelayInput

-- ===== ОБРАБОТЧИКИ =====
ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "ВКЛ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        refreshSeats()
        currentIndex = 1
        coroutine.wrap(mainLoop)()
    else
        ToggleBtn.Text = "ВЫКЛ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        -- Встаём с сиденья при выключении
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid then humanoid.Sit = false end
        end
    end
end)

DelayInput.FocusLost:Connect(function()
    local num = tonumber(DelayInput.Text)
    if num and num > 0 then
        delayMs = num
    else
        DelayInput.Text = tostring(delayMs)
    end
end)

-- Первоначальный поиск сидений
refreshSeats()