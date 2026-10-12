-- Скрипт авто-перемещения между сиденьями (v2.1)
-- Добавлено: принудительное вставание после каждого сиденья
-- Автор: palofsc

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ===== НАСТРОЙКИ =====
local enabled = false
local delayMs = 500
local currentIndex = 1
local mode = "seats" -- "seats" или "coords"
local coordTargets = {}
local selectingMode = false

-- ===== ФУНКЦИЯ ПРИНУДИТЕЛЬНОГО ВСТАВАНИЯ =====
local function forceStandUp()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    if humanoid.Sit then
        humanoid.Sit = false
        humanoid.Jump = true
        local start = tick()
        while humanoid.Sit and tick() - start < 0.5 do
            task.wait(0.05)
        end
    end
end

-- ===== ФУНКЦИЯ: РЕГИСТРОНЕЗАВИСИМЫЙ ПОИСК СИДЕНИЙ =====
local function isSeatName(name)
    local lower = name:lower()
    return lower == "treotien" or lower == "treotienvip"
end

local function findSeats()
    local vipSeats = {}
    local normalSeats = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isSeatName(obj.Name) then
            local seatObj = obj
            if obj:IsA("Model") then
                local s = obj:FindFirstChildWhichIsA("Seat") or obj:FindFirstChildWhichIsA("VehicleSeat")
                if s then seatObj = s end
            end
            local finalSeat = nil
            if seatObj:IsA("Seat") or seatObj:IsA("VehicleSeat") then
                finalSeat = seatObj
            else
                finalSeat = seatObj:FindFirstChildWhichIsA("Seat") or seatObj:FindFirstChildWhichIsA("VehicleSeat")
            end
            if finalSeat then
                if obj.Name:lower() == "treotienvip" then
                    table.insert(vipSeats, finalSeat)
                else
                    table.insert(normalSeats, finalSeat)
                end
            end
        end
    end
    local result = {}
    for _, s in ipairs(vipSeats) do table.insert(result, s) end
    for _, s in ipairs(normalSeats) do table.insert(result, s) end
    return result
end

local seatsList = {}

local function refreshSeats()
    seatsList = findSeats()
    print("[Seats] Найдено: " .. #seatsList)
    for i, s in ipairs(seatsList) do
        print("  " .. i .. ". " .. s.Name .. " | " .. tostring(s.Position))
    end
    return #seatsList
end

-- ===== ПОЛУЧЕНИЕ ПОЗИЦИИ МОДЕЛИ =====
local function getModelPosition(model)
    if not model then return nil end
    if model:IsA("Model") then
        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if primary then return primary.Position end
        local cf, size = model:GetBoundingBox()
        return cf.Position
    elseif model:IsA("BasePart") then
        return model.Position
    end
    return nil
end

-- ===== ПЕРЕСАДКА НА СИДЕНЬЕ =====
local function sitOnSeat(seat)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    humanoid.Sit = false
    task.wait(0.05)
    if seat and seat.Parent then
        seat:Sit(humanoid)
    end
end

-- ===== ТЕЛЕПОРТ К КООРДИНАТАМ =====
local function teleportToPosition(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

-- ===== ОСНОВНОЙ ЦИКЛ =====
local function mainLoop()
    while enabled do
        -- Принудительно встаём перед любым действием
        forceStandUp()
        task.wait(0.1)

        if mode == "seats" then
            if #seatsList == 0 then
                refreshSeats()
                task.wait(0.5)
            else
                local seat = seatsList[currentIndex]
                if seat and seat.Parent then
                    sitOnSeat(seat)
                    -- Ждём, пока персонаж сядет
                    local char = LocalPlayer.Character
                    local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
                    if humanoid then
                        local sitStart = tick()
                        while not humanoid.Sit and tick() - sitStart < 0.5 do
                            task.wait(0.05)
                        end
                    end
                    task.wait(delayMs / 1000)
                    -- Встаём перед переходом к следующему
                    forceStandUp()
                    currentIndex = currentIndex + 1
                    if currentIndex > #seatsList then currentIndex = 1 end
                else
                    refreshSeats()
                    currentIndex = 1
                    task.wait(0.3)
                end
            end
        else -- режим координат
            if #coordTargets == 0 then
                task.wait(0.3)
            elseif #coordTargets == 1 then
                local t = coordTargets[1]
                teleportToPosition(t.position)
                task.wait(delayMs / 1000)
                teleportToPosition(t.position + Vector3.new(0, 0, 5))
                task.wait(delayMs / 1000)
            else
                local t = coordTargets[currentIndex]
                if t then
                    teleportToPosition(t.position)
                    task.wait(delayMs / 1000)
                    currentIndex = currentIndex + 1
                    if currentIndex > #coordTargets then currentIndex = 1 end
                end
            end
        end
        task.wait(0.05)
    end
end

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeatAutoGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 260)
Frame.Position = UDim2.new(0.5, -140, 0.5, -130)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Авто-перемещение v2.1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 35)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "ВЫКЛ"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Frame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local Mode1Btn = Instance.new("TextButton")
Mode1Btn.Size = UDim2.new(0.9, 0, 0, 26)
Mode1Btn.Position = UDim2.new(0.05, 0, 0, 72)
Mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
Mode1Btn.Text = "Режим: Сиденья"
Mode1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Mode1Btn.Font = Enum.Font.Gotham
Mode1Btn.TextSize = 12
Mode1Btn.Parent = Frame
Instance.new("UICorner", Mode1Btn).CornerRadius = UDim.new(0, 4)

local Mode2Btn = Instance.new("TextButton")
Mode2Btn.Size = UDim2.new(0.9, 0, 0, 26)
Mode2Btn.Position = UDim2.new(0.05, 0, 0, 102)
Mode2Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
Mode2Btn.Text = "Режим: Координаты"
Mode2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Mode2Btn.Font = Enum.Font.Gotham
Mode2Btn.TextSize = 12
Mode2Btn.Parent = Frame
Instance.new("UICorner", Mode2Btn).CornerRadius = UDim.new(0, 4)

local AddPosBtn = Instance.new("TextButton")
AddPosBtn.Size = UDim2.new(0.9, 0, 0, 26)
AddPosBtn.Position = UDim2.new(0.05, 0, 0, 132)
AddPosBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
AddPosBtn.Text = "+ Добавить мою позицию"
AddPosBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AddPosBtn.Font = Enum.Font.Gotham
AddPosBtn.TextSize = 12
AddPosBtn.Parent = Frame
Instance.new("UICorner", AddPosBtn).CornerRadius = UDim.new(0, 4)

local PickBtn = Instance.new("TextButton")
PickBtn.Size = UDim2.new(0.9, 0, 0, 26)
PickBtn.Position = UDim2.new(0.05, 0, 0, 162)
PickBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30)
PickBtn.Text = "Выбрать модель (клик)"
PickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PickBtn.Font = Enum.Font.Gotham
PickBtn.TextSize = 12
PickBtn.Parent = Frame
Instance.new("UICorner", PickBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.9, 0, 0, 26)
ClearBtn.Position = UDim2.new(0.05, 0, 0, 192)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
ClearBtn.Text = "Очистить список"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.Gotham
ClearBtn.TextSize = 12
ClearBtn.Parent = Frame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
DelayLabel.Position = UDim2.new(0.05, 0, 0, 225)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Задержка (мс):"
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.TextSize = 12
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = Frame

local DelayInput = Instance.new("TextBox")
DelayInput.Size = UDim2.new(0.3, 0, 0, 22)
DelayInput.Position = UDim2.new(0.6, 0, 0, 224)
DelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.Font = Enum.Font.Gotham
DelayInput.TextSize = 12
DelayInput.Text = tostring(delayMs)
DelayInput.Parent = Frame
Instance.new("UICorner", DelayInput).CornerRadius = UDim.new(0, 4)

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(0.9, 0, 0, 0)
ListLabel.Position = UDim2.new(0.05, 0, 0, 250)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = ""
ListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ListLabel.Font = Enum.Font.Gotham
ListLabel.TextSize = 10
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Parent = Frame

local function updateListDisplay()
    local text = ""
    if mode == "coords" then
        for i, t in ipairs(coordTargets) do
            text = text .. i .. ". " .. t.name .. "\n"
        end
    else
        for i, s in ipairs(seatsList) do
            text = text .. i .. ". " .. s.Name .. "\n"
        end
    end
    ListLabel.Text = text
end

ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleBtn.Text = "ВКЛ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        if mode == "seats" then refreshSeats() end
        currentIndex = 1
        coroutine.wrap(mainLoop)()
    else
        ToggleBtn.Text = "ВЫКЛ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        forceStandUp()
    end
end)

Mode1Btn.MouseButton1Click:Connect(function()
    mode = "seats"
    Mode1Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    Mode2Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    refreshSeats()
    updateListDisplay()
end)

Mode2Btn.MouseButton1Click:Connect(function()
    mode = "coords"
    Mode2Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    Mode1Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    updateListDisplay()
end)

AddPosBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    table.insert(coordTargets, {
        name = "Pos" .. (#coordTargets + 1),
        position = hrp.Position
    })
    mode = "coords"
    Mode2Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    Mode1Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    updateListDisplay()
    print("[+] Добавлена позиция: " .. tostring(hrp.Position))
end)

ClearBtn.MouseButton1Click:Connect(function()
    coordTargets = {}
    updateListDisplay()
    print("[*] Список координат очищен")
end)

local function selectModelByClick()
    selectingMode = true
    PickBtn.Text = "Кликните по модели..."
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UserInputService:GetMouseLocation()
            local ray = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            if result and result.Instance then
                local hit = result.Instance
                local model = hit:FindFirstAncestorOfClass("Model") or hit
                local pos = getModelPosition(model)
                if pos then
                    table.insert(coordTargets, {
                        name = model.Name,
                        position = pos,
                        model = model
                    })
                    mode = "coords"
                    Mode2Btn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
                    Mode1Btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                    updateListDisplay()
                    print("[+] Выбрана модель: " .. model.Name .. " | " .. tostring(pos))
                end
            end
            selectingMode = false
            PickBtn.Text = "Выбрать модель (клик)"
            if connection then connection:Disconnect() end
        end
    end)
end

PickBtn.MouseButton1Click:Connect(selectModelByClick)

task.spawn(function()
    while true do
        task.wait(0.5)
        for _, t in ipairs(coordTargets) do
            if t.model and t.model.Parent then
                local newPos = getModelPosition(t.model)
                if newPos then t.position = newPos end
            end
        end
    end
end)

refreshSeats()
updateListDisplay()
print("[GUI] Загружено. Режим: " .. mode)