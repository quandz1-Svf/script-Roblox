local aimbotEnabled = false
local chamsEnabled = false
local teamCheckEnabled = false 
local aimTargetSetting = "Torso" 
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

-- Kho lưu trữ Chams độc lập trong Workspace
local ChamsStorage = workspace:FindFirstChild("RainbowChams_Storage")
if ChamsStorage then ChamsStorage:Destroy() end
ChamsStorage = Instance.new("Folder")
ChamsStorage.Name = "RainbowChams_Storage"
ChamsStorage.Parent = workspace

--------------------------------------------------------------------
-- UI Creation (Rainbow Themed)
--------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RainbowV6FinalFix"
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = TargetGui

local MainPanel = Instance.new("Frame", ScreenGui)
local MainCorner = Instance.new("UICorner", MainPanel)
local MainStroke = Instance.new("UIStroke", MainPanel)

local ToggleBtn = Instance.new("TextButton", MainPanel)
local ChamsBtn = Instance.new("TextButton", MainPanel)
local TeamBtn = Instance.new("TextButton", MainPanel) 
local AimPartBtn = Instance.new("TextButton", MainPanel) 
local FOVInput = Instance.new("TextBox", MainPanel)
local CloseBtn = Instance.new("TextButton", MainPanel)
local Title = Instance.new("TextLabel", MainPanel)
local SubTitle = Instance.new("TextLabel", MainPanel)

MainPanel.Size = UDim2.new(0, 200, 0, 255)
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
Title.Text = "RAINBOW V6 HYBRID"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
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
local ChamsStroke = StyleRainbowButton(ChamsBtn, 95, "Hybrid Chams: OFF")
local TeamStroke = StyleRainbowButton(TeamBtn, 135, "Team Check: OFF") 
local AimPartStroke = StyleRainbowButton(AimPartBtn, 175, "Aim Part: Torso") 
local FOVStroke = StyleRainbowButton(FOVInput, 215, tostring(aimbotFOV))

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

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2     
FOVCircle.Visible = false
FOVCircle.Filled = false

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1
SnapLine.Visible = false

--------------------------------------------------------------------
-- TEAM CHECK & WALL CHECK
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

    return true 
end

local function isVisible(targetPart)
    if not targetPart or not targetPart.Parent then return false end
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, ChamsStorage}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    if not raycastResult or raycastResult.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

--------------------------------------------------------------------
-- CƠ CHẾ LIVE-REFRESH HYBRID CHAMS (Có lọc máu và dọn sạch khi thoát)
--------------------------------------------------------------------
local function clearAllChams()
    ChamsStorage:ClearAllChildren()
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if chamsEnabled then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= LocalPlayer then
                    local char = v.Character
                    if char and char:IsDescendantOf(workspace) then
                        local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char:FindFirstChild("Torso")
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        local nameTag = "Cham_" .. v.Name
                        local existingCham = ChamsStorage:FindFirstChild(nameTag)
                        
                        -- Chỉ hiện Chams khi Team hợp lệ, có bộ phận gốc và mục tiêu còn sống
                        if checkTargetTeam(v) and rootPart and humanoid and humanoid.Health > 0 then
                            if not existingCham then
                                local box = Instance.new("BoxHandleAdornment")
                                box.Name = nameTag
                                box.Size = Vector3.new(4, 5, 4) 
                                box.Color3 = Color3.fromRGB(255, 0, 100) 
                                box.Transparency = 0.5
                                box.AlwaysOnTop = true 
                                box.ZIndex = 5
                                box.Adornee = rootPart
                                box.Parent = ChamsStorage
                            else
                                if existingCham.Adornee ~= rootPart then
                                    existingCham.Adornee = rootPart
                                end
                            end
                        else
                            -- Xóa Chams ngay lập tức nếu đối thủ chết hoặc đổi đội
                            if existingCham then existingCham:Destroy() end
                        end
                    else
                        -- Xóa Chams khi nhân vật tạm thời không tồn tại (đang chờ hồi sinh)
                        local existingCham = ChamsStorage:FindFirstChild("Cham_" .. v.Name)
                        if existingCham then existingCham:Destroy() end
                    end
                end
            end
        else
            clearAllChams()
        end
    end
end)

-- SỰ KIỆN XỬ LÝ LỖI KẸT HÌNH: Xóa Chams của người chơi ngay khi họ thoát game hẳn
Players.PlayerRemoving:Connect(function(player)
    local leftPlayerCham = ChamsStorage:FindFirstChild("Cham_" .. player.Name)
    if leftPlayerCham then
        leftPlayerCham:Destroy()
    end
end)

--------------------------------------------------------------------
-- MAIN RENDERING LOOP (UI & Adaptive Aimbot có lọc máu)
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
        AimPartStroke.Color = rainbow
        AimPartBtn.TextColor3 = rainbow
        FOVStroke.Color = rainbow
        FOVInput.TextColor3 = rainbow
    end

    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = aimbotFOV
    FOVCircle.Color = rainbow
    SnapLine.Color = rainbow

    if aimbotEnabled then
        local target = nil
        local dist = aimbotFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer or not p.Character or not checkTargetTeam(p) then
                continue
            end

            local char = p.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local isCharacterValid = (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")) and char:IsDescendantOf(workspace)

            if isCharacterValid and humanoid and humanoid.Health > 0 then
                local headPart = char:FindFirstChild("Head")
                local torsoPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                
                local chosenPart = nil

                if aimTargetSetting == "Torso" then
                    if torsoPart and isVisible(torsoPart) then
                        chosenPart = torsoPart
                    elseif headPart and isVisible(headPart) then
                        chosenPart = headPart
                    end
                elseif aimTargetSetting == "Head" then
                    if headPart and isVisible(headPart) then
                        chosenPart = headPart
                    elseif torsoPart and isVisible(torsoPart) then
                        chosenPart = torsoPart
                    end
                end

                if chosenPart then
                    local pos, screen = Camera:WorldToViewportPoint(chosenPart.Position)
                    if screen then
                        local mDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if mDist < dist then 
                            dist = mDist 
                            target = chosenPart 
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
    ChamsBtn.Text = chamsEnabled and "Hybrid Chams: ON" or "Hybrid Chams: OFF"
    if not chamsEnabled then
        clearAllChams()
    end
end)

TeamBtn.MouseButton1Click:Connect(function()
    teamCheckEnabled = not teamCheckEnabled
    TeamBtn.Text = teamCheckEnabled and "Team Check: ON" or "Team Check: OFF"
    clearAllChams()
end)

AimPartBtn.MouseButton1Click:Connect(function()
    if aimTargetSetting == "Torso" then
        aimTargetSetting = "Head"
        AimPartBtn.Text = "Aim Part: Head"
    else
        aimTargetSetting = "Torso"
        AimPartBtn.Text = "Aim Part: Torso"
    end
end)

CloseBtn.MouseButton1Click:Connect(function() 
    clearAllChams()
    if ChamsStorage then ChamsStorage:Destroy() end
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

print("Đã vá lỗi kẹt Chams khi người chơi thoát game thành công!")
