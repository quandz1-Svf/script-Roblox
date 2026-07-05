local aimbotEnabled = false
local chamsEnabled = false
local teamCheckEnabled = false 
local aimbotFOV = 150
local panelVisible = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local CoreGui = game:GetService("CoreGui")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetGui = (pcall(function() return CoreGui.Name end) and CoreGui) or PlayerGui

--------------------------------------------------------------------
-- UI Creation (Rainbow Themed)
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RainbowV2Gui"
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = TargetGui

local MainPanel = Instance.new("Frame", ScreenGui)
local MainCorner = Instance.new("UICorner", MainPanel)
local MainStroke = Instance.new("UIStroke", MainPanel)

local ToggleBtn = Instance.new("TextButton", MainPanel)
local ChamsBtn = Instance.new("TextButton", MainPanel)
local TeamBtn = Instance.new("TextButton", MainPanel) 
local FOVInput = Instance.new("TextBox", MainPanel)
local CloseBtn = Instance.new("TextButton", MainPanel)
local Title = Instance.new("TextLabel", MainPanel)
local SubTitle = Instance.new("TextLabel", MainPanel)

-- Style Panel
MainPanel.Size = UDim2.new(0, 200, 0, 215)
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
local ChamsStroke = StyleRainbowButton(ChamsBtn, 95, "Outline Chams: OFF")
local TeamStroke = StyleRainbowButton(TeamBtn, 135, "Team Check: OFF") 
local FOVStroke = StyleRainbowButton(FOVInput, 175, tostring(aimbotFOV))

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

--------------------------------------------------------------------
-- ĐA TẦNG TEAM CHECK THÔNG MINH
--------------------------------------------------------------------
local function checkTargetTeam(player)
    if not teamCheckEnabled then return true end 
    if player == LocalPlayer then return false end

    if player.Team and LocalPlayer.Team then
        return player.Team ~= LocalPlayer.Team
    end

    if player.TeamColor and LocalPlayer.TeamColor then
        return player.TeamColor ~= LocalPlayer.TeamColor
    end

    local pAttr = player:GetAttribute("Team") or player:GetAttribute("Faction") or player:GetAttribute("Side")
    local localAttr = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Faction") or LocalPlayer:GetAttribute("Side")
    if pAttr and localAttr then
        return pAttr ~= localAttr
    end

    local pLeader = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Team")
    local localLeader = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Team")
    if pLeader and localLeader then
        return pLeader.Value ~= localLeader.Value
    end

    return true 
end

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
-- QUẢN LÝ CHAMS (Đã sửa lỗi không nhận diện khi qua Round mới)
--------------------------------------------------------------------
local function applyHighlight(player)
    local char = player.Character
    local hlName = "Chams_" .. player.Name
    local hl = ScreenGui:FindFirstChild(hlName)

    -- Nếu player không có nhân vật (đang tải round mới), dọn dẹp Chams cũ ngay
    if not char then 
        if hl then hl:Destroy() end
        return 
    end

    -- SỬA LỖI ROUND MỚI: Nếu tìm thấy Highlight cũ nhưng cơ thể nhân vật đã thay đổi
    -- Lập tức hủy bỏ đối tượng cũ bị kẹt cache để ép code tạo lại cái mới ở block dưới
    if hl and hl.Adornee ~= char then
        hl:Destroy()
        hl = nil
    end

    local isAlive = false
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        isAlive = hum.Health > 0
    else
        isAlive = char:IsDescendantOf(workspace) and char:FindFirstChildWhichIsA("BasePart") ~= nil
    end

    if chamsEnabled and checkTargetTeam(player) and isAlive then
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = hlName
            hl.FillTransparency = 1 
            hl.OutlineColor = Color3.fromRGB(255, 0, 100) 
            hl.OutlineTransparency = 0 
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
            hl.Parent = ScreenGui 
        end
        hl.Adornee = char 
        hl.Enabled = true
    else
        if hl then hl:Destroy() end
    end
end

local function removeHighlight(player)
    local hlName = "Chams_" .. player.Name
    local hl = ScreenGui:FindFirstChild(hlName)
    if hl then hl:Destroy() end
end

-- Tự động dọn dẹp bộ nhớ khi có người rời phòng đấu
Players.PlayerRemoving:Connect(removeHighlight)

--------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local rainbow = Color3.fromHSV(tick() * 0.5 % 1, 1, 1)

    if MainPanel.Visible then
        MainStroke.Color = rainbow
        Title.TextColor3 = rainbow
        SubTitle.TextColor3 = rainbow
        ToggleStroke.Color = rainbow
        ToggleBtn.TextColor3 = rainbow
        ChamsStroke.Color = rainbow
        ChamsBtn.TextColor3 = rainbow
        TeamStroke.Color = rainbow
        TeamBtn.TextColor3 = rainbow
        FOVStroke.Color = rainbow
        FOVInput.TextColor3 = rainbow
    end

    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Color = rainbow
    SnapLine.Color = rainbow

    -- Chams Loop Refresh liên tục mỗi Frame
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            applyHighlight(p)
        end
    end

    -- Logic Auto Aimbot
    if aimbotEnabled then
        local target = nil
        local dist = aimbotFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character or not checkTargetTeam(p) then
                continue
            end

            local char = p.Character
            local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            local isAlive = hum and hum.Health > 0 or (not hum and char:IsDescendantOf(workspace))

            if targetPart and isAlive then
                local pos, screen = Camera:WorldToViewportPoint(targetPart.Position)
                if screen then
                    if isVisible(targetPart) then 
                        local mDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if mDist < dist then 
                            dist = mDist 
                            target = targetPart 
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
    ChamsBtn.Text = chamsEnabled and "Outline Chams: ON" or "Outline Chams: OFF"
    if not chamsEnabled then
        for _, p in ipairs(Players:GetPlayers()) do removeHighlight(p) end
    end
end)

TeamBtn.MouseButton1Click:Connect(function()
    teamCheckEnabled = not teamCheckEnabled
    TeamBtn.Text = teamCheckEnabled and "Team Check: ON" or "Team Check: OFF"
end)

CloseBtn.MouseButton1Click:Connect(function() 
    for _, p in ipairs(Players:GetPlayers()) do removeHighlight(p) end
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

print("Đã vá lỗi tự động reset Chams khi qua round mới thành công!")
