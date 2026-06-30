-- Script taken from https://xenoscripts.com website --

local aimbotEnabled = false
local chamsEnabled = false
local isHoldingKey = false
local aimbotFOV = 150
local aimbotKey = Enum.KeyCode.E
local panelVisible = true
local isBinding = false

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------
-- UI Creation (Rainbow Themed)
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local MainPanel = Instance.new("Frame", ScreenGui)
local MainCorner = Instance.new("UICorner", MainPanel)
local MainStroke = Instance.new("UIStroke", MainPanel)

local ToggleBtn = Instance.new("TextButton", MainPanel)
local ChamsBtn = Instance.new("TextButton", MainPanel)
local BindBtn = Instance.new("TextButton", MainPanel)
local FOVInput = Instance.new("TextBox", MainPanel)
local CloseBtn = Instance.new("TextButton", MainPanel)
local Title = Instance.new("TextLabel", MainPanel)
local SubTitle = Instance.new("TextLabel", MainPanel) -- The "Open/Close with Z" text

-- Style Panel
MainPanel.Size = UDim2.new(0, 200, 0, 240) -- Adjusted height for the new text
MainPanel.Position = UDim2.new(0.5, -100, 0.4, 0)
MainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainPanel.BorderSizePixel = 0
MainPanel.Active = true
MainPanel.Draggable = true 

MainCorner.CornerRadius = UDim.new(0, 8)
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

Title.Size = UDim2.new(1, 0, 0, 25)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.Text = "RAINBOW V2"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.BackgroundTransparency = 1

SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 25)
SubTitle.Text = "[ Open/Close with Z ]"
SubTitle.Font = Enum.Font.GothamSemibold
SubTitle.TextSize = 10
SubTitle.BackgroundTransparency = 1

local function StyleRainbowButton(btn, pos, text)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local ToggleStroke = StyleRainbowButton(ToggleBtn, 55, "Aimbot: OFF")
local ChamsStroke = StyleRainbowButton(ChamsBtn, 95, "Pink Chams: OFF")
local BindStroke = StyleRainbowButton(BindBtn, 135, "Bind: " .. aimbotKey.Name)
local FOVStroke = StyleRainbowButton(FOVInput, 175, tostring(aimbotFOV))

CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

-- Drawings
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false      
FOVCircle.NumSides = 64        
FOVCircle.Transparency = 1     
FOVCircle.Visible = false


local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1
SnapLine.Visible = false

--------------------------------------------------------------------
-- RAINBOW LOGIC
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local rainbow = Color3.fromHSV(tick() * 0.5 % 1, 1, 1)
    
    -- Sync all UI elements to Rainbow
    MainStroke.Color = rainbow
    Title.TextColor3 = rainbow
    SubTitle.TextColor3 = rainbow -- Rainbow Subtitle
    ToggleStroke.Color = rainbow
    ToggleBtn.TextColor3 = rainbow
    ChamsStroke.Color = rainbow
    ChamsBtn.TextColor3 = rainbow
    BindStroke.Color = rainbow
    BindBtn.TextColor3 = rainbow
    FOVStroke.Color = rainbow
    FOVInput.TextColor3 = rainbow
    
    -- Drawing Rainbows
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Color = rainbow
    SnapLine.Color = rainbow

    -- Chams Update
    if chamsEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("ShinyPink") or Instance.new("Highlight", p.Character)
                h.Name = "ShinyPink"
                h.FillColor = Color3.fromRGB(255, 105, 180)
                h.OutlineColor = Color3.new(1, 1, 1)
                h.Enabled = true
            end
        end
    end

    -- Aimbot Update
    if aimbotEnabled and isHoldingKey then
        local target = nil
        local dist = aimbotFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                local pos, screen = Camera:WorldToViewportPoint(head.Position)
                if screen then
                    local mDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mDist < dist then dist = mDist target = head end
                end
            end
        end
        
        if target then
            local pos = Camera:WorldToViewportPoint(target.Position)
            SnapLine.From = center
            SnapLine.To = Vector2.new(pos.X, pos.Y)
            SnapLine.Visible = true
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        else SnapLine.Visible = false end
    else SnapLine.Visible = false end
end)

--------------------------------------------------------------------
-- INTERACTIONS
--------------------------------------------------------------------
ToggleBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    ToggleBtn.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
    FOVCircle.Visible = aimbotEnabled
end)

ChamsBtn.MouseButton1Click:Connect(function()
    chamsEnabled = not chamsEnabled
    ChamsBtn.Text = chamsEnabled and "Pink Chams: ON" or "Pink Chams: OFF"
end)

BindBtn.MouseButton1Click:Connect(function() isBinding = true BindBtn.Text = "..." end)
CloseBtn.MouseButton1Click:Connect(function() MainPanel.Visible = false end)
FOVInput.FocusLost:Connect(function() aimbotFOV = tonumber(FOVInput.Text) or 150 end)

UserInputService.InputBegan:Connect(function(input, gp)
    if isBinding then aimbotKey = input.KeyCode BindBtn.Text = "Bind: "..aimbotKey.Name isBinding = false return end
    if not gp then
        if input.KeyCode == aimbotKey then isHoldingKey = true 
        elseif input.KeyCode == Enum.KeyCode.Z then 
            panelVisible = not panelVisible 
            MainPanel.Visible = panelVisible 
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == aimbotKey then isHoldingKey = false SnapLine.Visible = false end
end)
--[[
	IMPROVED COUNTER BLOX VISUALS
	- Hologram Pink Hands (Neon + Bloom)
	- Enhanced Galaxy Skybox
	- Optimized Pink HUD
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- === 1. Enhanced Lighting & Glow ===
local function setupLighting()
    -- Clear existing effects to prevent stacking
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Clouds") or v:IsA("BloomEffect") then
            v:Destroy()
        end
    end

    -- Bloom makes Neon pink hands actually GLOW
    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 1.2
    bloom.Size = 24
    bloom.Threshold = 0.8

    local colorCorr = Instance.new("ColorCorrectionEffect", Lighting)
    colorCorr.Saturation = 0.2
    colorCorr.Contrast = 0.1

    -- Purple Galaxy Sky
    local Sky = Instance.new("Sky", Lighting)
    Sky.SkyboxUp = "rbxassetid://159454288"
    Sky.SkyboxDn = "rbxassetid://159454296"
    Sky.SkyboxFt = "rbxassetid://159454293"
    Sky.SkyboxBk = "rbxassetid://159454299"
    Sky.SkyboxLf = "rbxassetid://159454286"
    Sky.SkyboxRt = "rbxassetid://159454300"
    Sky.SunTextureId = "" -- Removes sun for better galaxy look

    Lighting.Ambient = Color3.fromRGB(120, 70, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 50, 150)
    Lighting.Brightness = 2.5
    Lighting.ClockTime = 20
    Lighting.ExposureCompensation = 0.5
end

-- === 2. Optimized Pink Hologram Hands ===
local function makePinkHands()
    -- Search for viewmodel (different games name it differently)
    local viewModel = Camera:FindFirstChild("ViewModel") 
        or Camera:FindFirstChild("Arms") 
        or Camera:FindFirstChildWhichIsA("Model")
    
    if not viewModel then return end

    for _, part in pairs(viewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local lname = part.Name:lower()
            -- Apply to hands, arms, and sleeves
            if lname:find("hand") or lname:find("arm") or lname:find("glass") or lname:find("sleeve") then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(255, 105, 180)
                part.Transparency = 0.3 -- Better hologram look
                part.Reflectance = 0
                -- Remove textures (like gloves) to show the glow
                if part:FindFirstChildWhichIsA("Texture") then
                    part:FindFirstChildWhichIsA("Texture"):Destroy()
                end
            end
        end
    end
end

-- === 3. Optimized Pink HUD ===
local function updateHUD(gui)
    local pinkColor = Color3.fromRGB(255, 105, 180)
    for _, obj in pairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            obj.TextColor3 = pinkColor
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            obj.ImageColor3 = pinkColor
        end
    end
end

-- Update HUD when player spawns/resets
local function fullHUDUpdate()
    task.wait(1) -- Wait for HUD to load
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in pairs(playerGui:GetChildren()) do
        updateHUD(gui)
    end
end

-- === Execution ===
setupLighting()
RunService.RenderStepped:Connect(makePinkHands)

LocalPlayer.CharacterAdded:Connect(fullHUDUpdate)
LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.1)
    updateHUD(child)
end)

-- Initial HUD check
fullHUDUpdate()

print("Improved Visuals Loaded!")