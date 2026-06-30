--[[
  Скрипт: Aimbot, ESP, Lag Fix (Мобильная оптимизация)
  GUI интегрирован с kyrilib.dev
  Автор: palofsc
  Версия: 1.0
--]]

-- ===== НАСТРОЙКИ =====
local FOV_RADIUS = 90          -- Радиус FOV для Aimbot (регулируется)
local ESP_ENABLED = true       -- Включить/выключить ESP
local AIMBOT_ENABLED = true    -- Включить/выключить Aimbot
local LAG_FIX_ENABLED = true   -- Включить/выключить Lag Fix
local TEAM_CHECK = true        -- Проверка по командам
local SMOOTHING = 3            -- Сглаживание прицела

-- ===== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ =====
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- ===== ФУНКЦИЯ ESP =====
local function ESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") then
                -- Проверка на существование BillboardGui
                local bill = char:FindFirstChild("ESPLabel")
                if not bill then
                    bill = Instance.new("BillboardGui")
                    bill.Name = "ESPLabel"
                    bill.Adornee = char.Head
                    bill.Size = UDim2.new(0, 100, 0, 50)
                    bill.StudsOffset = Vector3.new(0, 2.5, 0)
                    bill.AlwaysOnTop = true
                    
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 0, 0)
                    label.TextStrokeTransparency = 0
                    label.Text = player.Name
                    label.Parent = bill
                    
                    bill.Parent = char
                end
            end
        end
    end
end

-- ===== ФУНКЦИЯ AIMBOT =====
local function GetClosestPlayerInFOV(fovRadius)
    local closestPlayer = nil
    local shortestDistance = fovRadius or FOV_RADIUS
    
    -- Получаем позицию экрана локального игрока
    local myPos = Camera:WorldToViewportPoint(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position or Vector3.new(0,0,0))
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("Head") and char.Humanoid.Health > 0 then
                -- Проверка по командам (опционально)
                if TEAM_CHECK and player.Team == LocalPlayer.Team then
                    continue
                end
                
                local headPos = Camera:WorldToViewportPoint(char.Head.Position)
                local distance = (Vector2.new(headPos.X, headPos.Y) - Vector2.new(myPos.X, myPos.Y)).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

local function Aimbot()
    if not AIMBOT_ENABLED then return end
    
    local target = GetClosestPlayerInFOV(FOV_RADIUS)
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local headPos = target.Character.Head.Position
        local camPos = Camera.CFrame.Position
        local lookAt = CFrame.new(camPos, headPos)
        
        -- Применение сглаживания
        if SMOOTHING > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(lookAt, 1 / SMOOTHING)
        else
            Camera.CFrame = lookAt
        end
    end
end

-- ===== ФУНКЦИЯ LAG FIX =====
local function LagFix()
    if not LAG_FIX_ENABLED then return end
    
    -- Очистка ненужных объектов
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj:Destroy()
        end
    end
    
    -- Отключение графических эффектов
    settings().Rendering.QualityLevel = 1
    settings().Rendering.EnableFRM = false
    settings().Rendering.ClampFRate = true
    
    -- Очистка мусора
    game:GetService("Debris"):ClearAll()
end

-- ===== ЗАГРУЗКА GUI =====
local function LoadGUI()
    local success, result = pcall(function()
        -- Попытка загрузить GUI с указанного сайта
        local guiModule = loadstring(game:HttpGet("https://kyrilib.dev/gui.lua"))()
        return guiModule
    end)
    
    if not success then
        -- Если не удалось загрузить с сайта, создаем локальный GUI
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "KyrilibGUI"
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 200, 0, 150)
        Frame.Position = UDim2.new(0.5, -100, 0.5, -75)
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0
        Frame.Parent = ScreenGui
        
        -- Заголовок
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 25)
        Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Text = "kyrilib.dev GUI"
        Title.Parent = Frame
        
        -- Кнопка Aimbot
        local AimbotBtn = Instance.new("TextButton")
        AimbotBtn.Size = UDim2.new(1, -20, 0, 25)
        AimbotBtn.Position = UDim2.new(0, 10, 0, 35)
        AimbotBtn.Text = "Aimbot: ON"
        AimbotBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        AimbotBtn.Parent = Frame
        AimbotBtn.MouseButton1Click:Connect(function()
            AIMBOT_ENABLED = not AIMBOT_ENABLED
            AimbotBtn.Text = "Aimbot: " .. (AIMBOT_ENABLED and "ON" or "OFF")
            AimbotBtn.BackgroundColor3 = AIMBOT_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
        
        -- Кнопка ESP
        local ESPBtn = Instance.new("TextButton")
        ESPBtn.Size = UDim2.new(1, -20, 0, 25)
        ESPBtn.Position = UDim2.new(0, 10, 0, 65)
        ESPBtn.Text = "ESP: ON"
        ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        ESPBtn.Parent = Frame
        ESPBtn.MouseButton1Click:Connect(function()
            ESP_ENABLED = not ESP_ENABLED
            ESPBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
            ESPBtn.BackgroundColor3 = ESP_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
        
        -- Кнопка Lag Fix
        local LagFixBtn = Instance.new("TextButton")
        LagFixBtn.Size = UDim2.new(1, -20, 0, 25)
        LagFixBtn.Position = UDim2.new(0, 10, 0, 95)
        LagFixBtn.Text = "Lag Fix: ON"
        LagFixBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        LagFixBtn.Parent = Frame
        LagFixBtn.MouseButton1Click:Connect(function()
            LAG_FIX_ENABLED = not LAG_FIX_ENABLED
            LagFixBtn.Text = "Lag Fix: " .. (LAG_FIX_ENABLED and "ON" or "OFF")
            LagFixBtn.BackgroundColor3 = LAG_FIX_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
        
        -- Слайдер FOV
        local FOVSlider = Instance.new("TextBox")
        FOVSlider.Size = UDim2.new(0, 60, 0, 20)
        FOVSlider.Position = UDim2.new(1, -70, 0, 125)
        FOVSlider.Text = tostring(FOV_RADIUS)
        FOVSlider.Parent = Frame
        FOVSlider.FocusLost:Connect(function()
            local num = tonumber(FOVSlider.Text)
            if num then
                FOV_RADIUS = math.clamp(num, 10, 360)
            end
        end)
        
        local FOVLabel = Instance.new("TextLabel")
        FOVLabel.Size = UDim2.new(0, 100, 0, 20)
        FOVLabel.Position = UDim2.new(0, 10, 0, 125)
        FOVLabel.Text = "FOV Radius:"
        FOVLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        FOVLabel.BackgroundTransparency = 1
        FOVLabel.Parent = Frame
    end
end

-- ===== ГЛАВНЫЙ ЦИКЛ =====
LoadGUI()

RunService.RenderStepped:Connect(function()
    if ESP_ENABLED then
        ESP()
    end
    if AIMBOT_ENABLED then
        Aimbot()
    end
end)

-- Запуск Lag Fix при старте
if LAG_FIX_ENABLED then
    LagFix()
end

-- Периодическая очистка
coroutine.wrap(function()
    while true do
        wait(10)
        if LAG_FIX_ENABLED then
            LagFix()
        end
    end
end)()

print("Script loaded successfully - kyrilib.dev integration complete")