-- Roblox Script: ESP + Aimbot + FOV + Lag Fix + WindUI (GitHub: Footagesus/WindUI)
-- Made by palofsc (palo)
-- Используется WindUI вместо Rayfield. Загрузка библиотеки и создание интерфейса.

-- 1) ЗАГРУЗКА WINDUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua"))()

-- 2) СОЗДАНИЕ ОКНА
local Window = WindUI:CreateWindow({
    Name = "Palo Suite [WindUI]",
    Size = UDim2.new(0, 500, 0, 400),
    Theme = "Dark"
})

local MainTab = Window:CreateTab("Основное")
local VisualTab = Window:CreateTab("Визуал")
local AimbotTab = Window:CreateTab("Aimbot")

-- 3) ПЕРЕМЕННЫЕ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local AimbotEnabled = false
local FOVRadius = 150
local TeamCheck = false
local ShowFOV = true
local AimbotSmoothness = 0.3
local AimbotPart = "Head"
local LagFixEnabled = false

-- 4) ESP (BOX + NAME + DISTANCE)
local ESPObjects = {}
local function CreateESP(plr)
   if plr == LocalPlayer then return end
   local char = plr.Character
   if not char or not char:FindFirstChild("HumanoidRootPart") then return end
   local box = Drawing.new("Square")
   box.Thickness = 1; box.Filled = false; box.Color = Color3.new(1,0,0); box.Transparency = 1
   local name = Drawing.new("Text")
   name.Size = 14; name.Center = true; name.Color = Color3.new(1,1,1); name.Outline = true; name.OutlineColor = Color3.new(0,0,0)
   local dist = Drawing.new("Text")
   dist.Size = 12; dist.Center = true; dist.Color = Color3.new(0,1,0); dist.Outline = true; dist.OutlineColor = Color3.new(0,0,0)
   ESPObjects[plr] = {box = box, name = name, dist = dist}
end

local function UpdateESP()
   for plr, obj in pairs(ESPObjects) do
      if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or not ESPEnabled then
         obj.box.Visible = false; obj.name.Visible = false; obj.dist.Visible = false
         continue
      end
      local root = plr.Character.HumanoidRootPart
      local pos, onScreen = Camera:WorldToScreenPoint(root.Position)
      if onScreen then
         local size = 4 / pos.Z * 100
         local x, y = pos.X, pos.Y
         obj.box.Size = Vector2.new(size, size * 1.5)
         obj.box.Position = Vector2.new(x - size/2, y - size*0.75)
         obj.box.Visible = true
         obj.name.Text = plr.Name
         obj.name.Position = Vector2.new(x, y - size*0.75 - 15)
         obj.name.Visible = true
         local distance = math.floor((LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude or 0)
         obj.dist.Text = distance .. " м"
         obj.dist.Position = Vector2.new(x, y + size*0.75 + 15)
         obj.dist.Visible = true
         if TeamCheck and plr.Team == LocalPlayer.Team then
            obj.box.Color = Color3.new(0,1,0)
         else
            obj.box.Color = Color3.new(1,0,0)
         end
      else
         obj.box.Visible = false; obj.name.Visible = false; obj.dist.Visible = false
      end
   end
end

-- 5) FOV ОКРУЖНОСТЬ
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false; FOVCircle.Radius = FOVRadius; FOVCircle.Thickness = 1
FOVCircle.Color = Color3.new(1,1,1); FOVCircle.Filled = false; FOVCircle.NumSides = 64
FOVCircle.Position = Camera.ViewportSize / 2

-- 6) AIMBOT
local function GetClosestTarget()
   local closest = nil; local minDist = FOVRadius
   local mousePos = UserInputService:GetMouseLocation()
   for _, plr in pairs(Players:GetPlayers()) do
      if plr == LocalPlayer then continue end
      if TeamCheck and plr.Team == LocalPlayer.Team then continue end
      local char = plr.Character
      if not char then continue end
      local part = char:FindFirstChild(AimbotPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
      if not part then continue end
      local pos, onScreen = Camera:WorldToScreenPoint(part.Position)
      if not onScreen then continue end
      local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
      if dist < minDist then
         minDist = dist; closest = {plr = plr, part = part, screenPos = Vector2.new(pos.X, pos.Y)}
      end
   end
   return closest
end

local function AimbotLoop()
   if not AimbotEnabled then return end
   local target = GetClosestTarget()
   if target then
      local targetPos = target.part.Position
      local lookVector = (targetPos - Camera.CFrame.Position).Unit
      local newCFrame = CFrame.lookAt(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
      Camera.CFrame = Camera.CFrame:Lerp(newCFrame, AimbotSmoothness)
   end
end

-- 7) LAG FIX
local function LagFix()
   if LagFixEnabled then
      settings().Rendering.QualityLevel = 1
      game:GetService("Lighting").Technology = Enum.Technology.Legacy
      game:GetService("Lighting").GlobalShadows = false
      workspace.DescendantAdded:Connect(function(obj)
         if obj:IsA("ParticleEmitter") then obj.Enabled = false end
         if obj:IsA("Trail") then obj.Enabled = false end
         if obj:IsA("Beam") then obj.Enabled = false end
      end)
   else
      settings().Rendering.QualityLevel = 4
      game:GetService("Lighting").Technology = Enum.Technology.ShadowMap
      game:GetService("Lighting").GlobalShadows = true
   end
end

-- 8) GUI ЭЛЕМЕНТЫ (WindUI синтаксис)
MainTab:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Callback = function(v) ESPEnabled = v
      if v then for _, plr in pairs(Players:GetPlayers()) do CreateESP(plr) end
      else for _, obj in pairs(ESPObjects) do obj.box.Visible = false; obj.name.Visible = false; obj.dist.Visible = false end
      end
   end
})

MainTab:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false,
   Callback = function(v) AimbotEnabled = v end
})

MainTab:CreateToggle({
   Name = "Lag Fix",
   CurrentValue = false,
   Callback = function(v) LagFixEnabled = v; LagFix() end
})

MainTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Callback = function(v) TeamCheck = v end
})

VisualTab:CreateSlider({
   Name = "FOV Radius",
   Min = 50,
   Max = 400,
   Default = FOVRadius,
   Callback = function(v) FOVRadius = v; FOVCircle.Radius = v end
})

VisualTab:CreateToggle({
   Name = "Show FOV",
   CurrentValue = true,
   Callback = function(v) ShowFOV = v; FOVCircle.Visible = v end
})

AimbotTab:CreateSlider({
   Name = "Smoothness",
   Min = 0,
   Max = 1,
   Default = AimbotSmoothness,
   Callback = function(v) AimbotSmoothness = v end
})

AimbotTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "HumanoidRootPart", "Torso"},
   Default = "Head",
   Callback = function(v) AimbotPart = v end
})

-- 9) ОБНОВЛЕНИЯ
Players.PlayerAdded:Connect(function(plr)
   plr.CharacterAdded:Connect(function() if ESPEnabled then CreateESP(plr) end end)
   if ESPEnabled then CreateESP(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
   if ESPObjects[plr] then
      for _, obj in pairs(ESPObjects[plr]) do obj:Remove() end
      ESPObjects[plr] = nil
   end
end)

RunService.RenderStepped:Connect(function()
   if ESPEnabled then UpdateESP() end
   if AimbotEnabled then AimbotLoop() end
   if ShowFOV then
      FOVCircle.Visible = true
      FOVCircle.Position = UserInputService:GetMouseLocation()
   else
      FOVCircle.Visible = false
   end
end)

for _, plr in pairs(Players:GetPlayers()) do
   if plr ~= LocalPlayer then CreateESP(plr) end
end

print("Palo Suite [WindUI] загружен. WindUI требует корректного синтаксиса (см. документацию).")