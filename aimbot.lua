local aimbotEnabled = false
local chamsEnabled = false
local aimbotFOV = 150
local panelVisible = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CoreGui = game:GetService("CoreGui")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetGui = CoreGui or PlayerGui

--------------------------------------------------------------------
-- UI Creation (Rainbow Themed)
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", TargetGui)
local MainPanel = Instance.new("Frame", ScreenGui)
local MainCorner = Instance.new("UICorner", MainPanel)
local MainStroke = Instance.new("UIStroke", MainPanel)

local ToggleBtn = Instance.new("TextButton", MainPanel)
local ChamsBtn = Instance.new("TextButton", MainPanel)
local FOVInput = Instance.new("TextBox", MainPanel)
local CloseBtn = Instance.new("TextButton", MainPanel)
local Title = Instance.new("TextLabel", MainPanel)
local SubTitle = Instance.new("TextLabel", MainPanel)

-- Style Panel (Đã thu gọn chiều cao xuống 185 cho vừa vặn)
MainPanel.Size = UDim2.new(0, 200, 0, 185)
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
Title.ZIndex = 1

SubTitle.Size = UDim2.new(1, 0, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 25)
SubTitle.Text = "[ Open/Close with Z ]"
SubTitle.Font = Enum.Font.GothamSemibold
SubTitle.TextSize = 10
SubTitle.BackgroundTransparency = 1
SubTitle.ZIndex = 1

local function StyleRainbowButton(btn, pos, text)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.Text = text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.ZIndex = 2
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return stroke
end

local ToggleStroke = StyleRainbowButton(ToggleBtn, 55, "Aimbot: OFF")
local ChamsStroke = StyleRainbowButton(ChamsBtn, 95, "Pink Chams: OFF")
-- Đẩy ô FOV lên vị trí 135 thế chỗ nút Bind cũ cho gọn UI
local FOVStroke = StyleRainbowButton(FOVInput, 135, tostring(aimbotFOV))

-- Placeholder Text gợi ý cho ô FOV
FOVInput.PlaceholderText = "Nhập FOV..."
FOVInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)

CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.ZIndex = 10
local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(1, 0)

-- Drawings
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2     
FOVCircle.Visible = false
FOVCircle.Filled = false

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1
SnapLine.Visible = false

-- Hàm kiểm tra tường (Wall Check)
local function isVisible(targetPart)
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    if not raycastResult or raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

--------------------------------------------------------------------
-- RAINBOW LOGIC
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local rainbow = Color3.fromHSV(tick() * 0.5 % 1, 1, 1)

    -- Sync UI Colors
    if MainPanel.Visible then
        MainStroke.Color = rainbow
        Title.TextColor3 = rainbow
        SubTitle.TextColor3 = rainbow
        ToggleStroke.Color = rainbow
        ToggleBtn.TextColor3 = rainbow
        ChamsStroke.Color = rainbow
        ChamsBtn.TextColor3 = rainbow
        FOVStroke.Color = rainbow
        FOVInput.TextColor3 = rainbow
    end

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
                -- Ẩn Chams đi nếu địch đã chết
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    h.Enabled = true
                else
                    h.Enabled = false
                end
            end
        end
    end

    -- Auto Aimbot Update
    if aimbotEnabled then
        local target = nil
        local dist = aimbotFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _, p in ipairs(Players:GetPlayers()) do
            -- THÊM KIỂM TRA TRẠNG THÁI SỐNG (Humanoid.Health > 0)
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then 
                    local head = p.Character.Head
                    local pos, screen = Camera:WorldToViewportPoint(head.Position)
                    if screen then
                        if isVisible(head) then 
-- Hàm kiểm tra xem người chơi đó có phải kẻ địch không (Smart Team Check)
local function isEnemy(player)
    -- Nếu chơi chế độ FFA hoặc game không chia phe, ai cũng là địch
    if player.Neutral then 
        return true 
    end
    
    -- Cách 1: Kiểm tra thực thể Team mặc định của Roblox
    if player.Team and LocalPlayer.Team then
        if player.Team ~= LocalPlayer.Team then
            return true
        else
            return false
        end
    end
    
    -- Cách 2: Kiểm tra thông qua màu sắc đại diện của phe (Đề phòng game lỗi gán phe)
    if player.TeamColor and LocalPlayer.TeamColor then
        if player.TeamColor ~= LocalPlayer.TeamColor then
            return true
        else
            return false
        end
    end

    return true -- Mặc định nếu không quét được phe thì coi là địch để tránh lỗi đơ script
end

                            local mDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if mDist < dist then 
                                dist = mDist 
                                target = head 
                            end
                        end
                    end
                end
            end
        end

        if target then
            local pos = Camera:WorldToViewportPoint(target.Position)
            SnapLine.From = center
            SnapLine.To = Vector2.new(pos.X, pos.Y)
            SnapLine.Visible = true
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        else 
            SnapLine.Visible = false 
        end
    else 
        SnapLine.Visible = false 
    end
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

CloseBtn.MouseButton1Click:Connect(function() 
    ScreenGui:Destroy() 
end)

FOVInput.FocusLost:Connect(function() 
    aimbotFOV = tonumber(FOVInput.Text) or 150 
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp then
        if input.KeyCode == Enum.KeyCode.Z then 
            panelVisible = not panelVisible 
            MainPanel.Visible = panelVisible 
        end
    end
end)

--------------------------------------------------------------------
-- IMPROVED COUNTER BLOX VISUALS (Màu hồng & Galaxy)
--------------------------------------------------------------------
local Lighting = game:GetService("Lighting")

local function setupLighting()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Clouds") or v:IsA("BloomEffect") then
            v:Destroy()
        end
    end

    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 1.2
    bloom.Size = 24
    bloom.Threshold = 0.8

    local colorCorr = Instance.new("ColorCorrectionEffect", Lighting)
    colorCorr.Saturation = 0.2
    colorCorr.Contrast = 0.1

    local Sky = Instance.new("Sky", Lighting)
    Sky.SkyboxUp = "rbxassetid://159454288"
    Sky.SkyboxDn = "rbxassetid://159454296"
    Sky.SkyboxFt = "rbxassetid://159454293"
    Sky.SkyboxBk = "rbxassetid://159454299"
    Sky.SkyboxLf = "rbxassetid://159454286"
    Sky.SkyboxRt = "rbxassetid://159454300"
    Sky.SunTextureId = ""

    Lighting.Ambient = Color3.fromRGB(120, 70, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 50, 150)
    Lighting.Brightness = 2.5
    Lighting.ClockTime = 20
    Lighting.ExposureCompensation = 0.5
end

local function makePinkHands()
    local viewModel = Camera:FindFirstChild("ViewModel") 
        or Camera:FindFirstChild("Arms") 
        or Camera:FindFirstChildWhichIsA("Model")

    if not viewModel then return end

    for _, part in pairs(viewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            local lname = part.Name:lower()
            if lname:find("hand") or lname:find("arm") or lname:find("glass") or lname:find("sleeve") then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(255, 105, 180)
                part.Transparency = 0.3
                part.Reflectance = 0
                local tex = part:FindFirstChildWhichIsA("Texture")
                if tex then tex:Destroy() end
            end
        end
    end
end

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

local function fullHUDUpdate()
    pcall(function()
        for _, gui in pairs(PlayerGui:GetChildren()) do
            updateHUD(gui)
        end
    end)
end

setupLighting()
RunService.RenderStepped:Connect(makePinkHands)

LocalPlayer.CharacterAdded:Connect(fullHUDUpdate)
PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.1)
    updateHUD(child)
end)

fullHUDUpdate()
print("Đã thêm check máu kẻ địch thành công!")
