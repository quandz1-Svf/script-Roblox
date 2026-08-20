--[[
 01010101 - ANTI-BAN ENHANCED
 Tối ưu chống phát hiện, giảm thiểu rủi ro bị ban.
 Hỗ trợ: ESP, FLY (tích hợp), NOCLIP (CollisionGroup), FIX LAG, INF JUMP, SPEED WALK.
]]

-- ====================== KHỞI TẠO DỊCH VỤ ======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until LocalPlayer and LocalPlayer.Character

-- ====================== KIỂM TRA HỖ TRỢ ======================
local supportsDrawing = false
local _drawTest
pcall(function()
 _drawTest = Drawing.new("Square")
 _drawTest.Visible = false
 supportsDrawing = true
end)
if _drawTest then _drawTest:Remove() end

-- ====================== CẤU HÌNH ======================
local EspEnabled = false
local FlyEnabled = false
local NoclipEnabled = false
local FixLagEnabled = false
local InfiniteJumpEnabled = false
local SpeedWalkEnabled = false

local EspObjects = {}
local espRenderConnection = nil
local noclipConnections = {}
local speedWalkLoop = nil
local flyLoop = nil

-- Thông số speed walk
local DEFAULT_WALKSPEED = 16
local SPEED_WALK_VALUE = 50
local MIN_SPEED_WALK = 15
local MAX_SPEED_WALK = 200
local SPEED_STEP = 5

-- ====================== GIAO DIỆN MÀU SẮC ======================
local C = {
 bg = Color3.fromRGB(8, 12, 8),
 bg2 = Color3.fromRGB(12, 20, 12),
 bg3 = Color3.fromRGB(18, 30, 18),
 green = Color3.fromRGB(0, 255, 100),
 greenD = Color3.fromRGB(0, 180, 60),
 greenD2 = Color3.fromRGB(0, 100, 30),
 greenG = Color3.fromRGB(0, 255, 120),
 text = Color3.fromRGB(180, 255, 180),
 textD = Color3.fromRGB(60, 120, 60),
 red = Color3.fromRGB(255, 40, 40),
}

-- ====================== HÀM HỖ TRỢ ======================
local function tw(obj, props, dur, ease)
 local ti = TweenInfo.new(dur or 0.3, ease or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
 local t = TweenService:Create(obj, ti, props)
 t:Play()
 return t
end

-- ====================== PHÁT HIỆN MOBILE ======================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local dw = isMobile and 220 or 190
local dh = isMobile and 370 or 330

-- ====================== TẠO GUI ======================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "01010101_GUI_" .. tostring(math.random(1000, 9999)) -- Tên ngẫu nhiên
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, dw, 0, dh)
Frame.Position = UDim2.new(0.5, -dw/2, 0.5, -dh/2)
Frame.BackgroundColor3 = C.bg
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 16)

local FrameStroke = Instance.new("UIStroke", Frame)
FrameStroke.Thickness = 1.5
FrameStroke.Color = C.green
FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Top bar
local TopBar = Instance.new("Frame", Frame)
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = C.bg2
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 16)

local Div = Instance.new("Frame", TopBar)
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 1, -1)
Div.BackgroundColor3 = C.greenD2
Div.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -66, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "01010101"
Title.Font = Enum.Font.Code
Title.TextSize = isMobile and 14 or 13
Title.TextColor3 = C.green
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Nút collapse
local CollapseBtn = Instance.new("TextButton", TopBar)
CollapseBtn.Size = UDim2.new(0, 26, 0, 26)
CollapseBtn.Position = UDim2.new(1, -62, 0, 5)
CollapseBtn.Text = "-"
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 18
CollapseBtn.TextColor3 = C.green
CollapseBtn.BackgroundColor3 = C.bg3
CollapseBtn.BackgroundTransparency = 0.3
CollapseBtn.BorderSizePixel = 0
CollapseBtn.AutoButtonColor = false
Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(1, 0)

-- Nút minimize
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -32, 0, 5)
MinBtn.Text = "X"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.TextColor3 = C.green
MinBtn.BackgroundColor3 = C.bg3
MinBtn.BackgroundTransparency = 0.3
MinBtn.BorderSizePixel = 0
MinBtn.AutoButtonColor = false
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

-- Bóng minimised
local Ball = Instance.new("TextButton", ScreenGui)
Ball.Size = UDim2.new(0, 50, 0, 50)
Ball.Position = Frame.Position
Ball.BackgroundColor3 = C.bg2
Ball.BorderSizePixel = 0
Ball.Visible = false
Ball.Text = ""
Ball.AutoButtonColor = false
Ball.ZIndex = 999
Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)

local BallStroke = Instance.new("UIStroke", Ball)
BallStroke.Thickness = 2
BallStroke.Color = C.green
BallStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local BallLabel = Instance.new("TextLabel", Ball)
BallLabel.Size = UDim2.new(1, 0, 1, 0)
BallLabel.BackgroundTransparency = 1
BallLabel.Text = "C"
BallLabel.Font = Enum.Font.GothamBold
BallLabel.TextSize = 24
BallLabel.TextColor3 = C.green
BallLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Nội dung
local Content = Instance.new("Frame", Frame)
Content.Size = UDim2.new(1, -12, 1, -44)
Content.Position = UDim2.new(0, 6, 0, 40)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 8)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Hàm tạo nút
local function makeBtn(text, color, order, fn)
 local b = Instance.new("TextButton")
 b.Size = UDim2.new(1, -4, 0, isMobile and 38 or 32)
 b.BackgroundColor3 = color
 b.BackgroundTransparency = 0.15
 b.BorderSizePixel = 0
 b.AutoButtonColor = false
 b.Text = ""
 b.LayoutOrder = order or 1
 b.Parent = Content
 Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

 local st = Instance.new("UIStroke", b)
 st.Thickness = 1
 st.Color = C.green
 st.Transparency = 0.5
 st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

 local l = Instance.new("TextLabel", b)
 l.Size = UDim2.new(1, 0, 1, 0)
 l.BackgroundTransparency = 1
 l.Text = text
 l.Font = Enum.Font.Code
 l.TextSize = isMobile and 13 or 12
 l.TextColor3 = C.text
 l.TextXAlignment = Enum.TextXAlignment.Center

 b.MouseButton1Click:Connect(function()
 if fn then fn(b, l) end
 end)

 return b, l
end

-- ====================== ESP ======================
if supportsDrawing then
 makeBtn("[ ESP ] OFF", C.red, 1, function(b, l)
 EspEnabled = not EspEnabled
 l.Text = "[ ESP ] " .. (EspEnabled and "ON" or "OFF")
 local cor = EspEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)

 if EspEnabled then
 if not espRenderConnection then
 local frameCounter = 0
 espRenderConnection = RunService.Heartbeat:Connect(function()
 frameCounter = frameCounter + 1
 if frameCounter % 6 ~= 0 then return end -- cập nhật mỗi ~0.1s
 local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 for plr, obj in pairs(EspObjects) do
 local char = plr.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 local espPart = char and char:FindFirstChild("Head")
 if espPart and hum and hum.Health > 0 then
 local pos, onScreen = Camera:WorldToViewportPoint(espPart.Position)
 if onScreen then
 local boxSize = 10
 obj.box.Size = Vector2.new(boxSize, boxSize)
 obj.box.Position = Vector2.new(pos.X - boxSize/2, pos.Y - boxSize/2)
 obj.box.Color = C.green
 obj.box.Visible = true

 obj.line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
 obj.line.To = Vector2.new(pos.X, pos.Y)
 obj.line.Color = C.green
 obj.line.Visible = true

 obj.nameTag.Position = Vector2.new(pos.X, pos.Y - boxSize/2 - 12)
 obj.nameTag.Visible = true

 if myRoot and espPart then
 local dist = (myRoot.Position - espPart.Position).Magnitude
 obj.distanceTag.Text = string.format("%.1f m", dist)
 obj.distanceTag.Position = Vector2.new(pos.X, pos.Y - boxSize/2 - 12 - 16)
 obj.distanceTag.Visible = true
 else
 obj.distanceTag.Visible = false
 end
 else
 obj.box.Visible = false
 obj.line.Visible = false
 obj.nameTag.Visible = false
 obj.distanceTag.Visible = false
 end
 else
 obj.box.Visible = false
 obj.line.Visible = false
 obj.nameTag.Visible = false
 obj.distanceTag.Visible = false
 end
 end
 end)
 end
 else
 if espRenderConnection then
 espRenderConnection:Disconnect()
 espRenderConnection = nil
 end
 for _, obj in pairs(EspObjects) do
 if obj.box then obj.box.Visible = false end
 if obj.line then obj.line.Visible = false end
 if obj.nameTag then obj.nameTag.Visible = false end
 if obj.distanceTag then obj.distanceTag.Visible = false end
 end
 end
 end)
else
 local b, l = makeBtn("[ ESP ] N/A", Color3.fromRGB(80, 80, 80), 1, function() end)
 b.AutoButtonColor = false
 l.TextColor3 = Color3.fromRGB(150,150,150)
end

-- ====================== FLY (TÍCH HỢP) ======================
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyControl = {forward = false, back = false, left = false, right = false, up = false, down = false}

local function setupFlyControls()
 -- Kết nối sự kiện bàn phím
 UserInputService.InputBegan:Connect(function(input, gameProcessed)
 if gameProcessed then return end
 if input.KeyCode == Enum.KeyCode.W then flyControl.forward = true
 elseif input.KeyCode == Enum.KeyCode.S then flyControl.back = true
 elseif input.KeyCode == Enum.KeyCode.A then flyControl.left = true
 elseif input.KeyCode == Enum.KeyCode.D then flyControl.right = true
 elseif input.KeyCode == Enum.KeyCode.Space then flyControl.up = true
 elseif input.KeyCode == Enum.KeyCode.LeftControl then flyControl.down = true
 end
 end)
 UserInputService.InputEnded:Connect(function(input, gameProcessed)
 if input.KeyCode == Enum.KeyCode.W then flyControl.forward = false
 elseif input.KeyCode == Enum.KeyCode.S then flyControl.back = false
 elseif input.KeyCode == Enum.KeyCode.A then flyControl.left = false
 elseif input.KeyCode == Enum.KeyCode.D then flyControl.right = false
 elseif input.KeyCode == Enum.KeyCode.Space then flyControl.up = false
 elseif input.KeyCode == Enum.KeyCode.LeftControl then flyControl.down = false
 end
 end)
end

local function startFly()
 if flyLoop then return end
 local char = LocalPlayer.Character
 local root = char and char:FindFirstChild("HumanoidRootPart")
 if not root then return end

 -- Tạo BodyVelocity và BodyGyro
 flyBodyVelocity = Instance.new("BodyVelocity")
 flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
 flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
 flyBodyVelocity.Parent = root

 flyBodyGyro = Instance.new("BodyGyro")
 flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
 flyBodyGyro.CFrame = root.CFrame
 flyBodyGyro.Parent = root

 -- Vòng lặp fly
 flyLoop = RunService.Heartbeat:Connect(function()
 if not FlyEnabled then return end
 local currentChar = LocalPlayer.Character
 local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
 if not currentRoot or not flyBodyVelocity or not flyBodyGyro then
 stopFly()
 return
 end
 flyBodyVelocity.Parent = currentRoot
 flyBodyGyro.Parent = currentRoot
 flyBodyGyro.CFrame = Camera.CFrame

 local speed = 50
 local moveDirection = Vector3.new(0, 0, 0)
 if flyControl.forward then moveDirection = moveDirection + Camera.CFrame.LookVector * speed end
 if flyControl.back then moveDirection = moveDirection - Camera.CFrame.LookVector * speed end
 if flyControl.left then moveDirection = moveDirection - Camera.CFrame.RightVector * speed end
 if flyControl.right then moveDirection = moveDirection + Camera.CFrame.RightVector * speed end
 if flyControl.up then moveDirection = moveDirection + Vector3.new(0, speed, 0) end
 if flyControl.down then moveDirection = moveDirection + Vector3.new(0, -speed, 0) end
 flyBodyVelocity.Velocity = moveDirection
 end)
end

local function stopFly()
 if flyLoop then
 flyLoop:Disconnect()
 flyLoop = nil
 end
 if flyBodyVelocity then
 flyBodyVelocity:Destroy()
 flyBodyVelocity = nil
 end
 if flyBodyGyro then
 flyBodyGyro:Destroy()
 flyBodyGyro = nil
 end
end

setupFlyControls()

makeBtn("[ FLY ] OFF", C.red, 2, function(b, l)
 FlyEnabled = not FlyEnabled
 if FlyEnabled then
 startFly()
 else
 stopFly()
 end
 l.Text = "[ FLY ] " .. (FlyEnabled and "ON" or "OFF")
 local cor = FlyEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)
end)

-- ====================== NOCLIP (CollisionGroup) ======================
local NO_CLIP_GROUP = "NoClipGroup_" .. tostring(math.random(1000, 9999))
local function createNoClipGroup()
 pcall(function()
 PhysicsService:CreateCollisionGroup(NO_CLIP_GROUP)
 PhysicsService:CollisionGroupSetCollidable(NO_CLIP_GROUP, "Default", false)
 end)
end

local function applyNoclipToCharacter(char)
 -- Đặt collision group cho tất cả parts
 for _, part in ipairs(char:GetDescendants()) do
 if part:IsA("BasePart") then
 pcall(function()
 PhysicsService:SetPartCollisionGroup(part, NO_CLIP_GROUP)
 end)
 end
 end
 -- Ngăn rơi và ragdoll
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
 hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
 end
 -- Kết nối cho các parts mới
 local conn = char.DescendantAdded:Connect(function(desc)
 if desc:IsA("BasePart") then
 pcall(function()
 PhysicsService:SetPartCollisionGroup(desc, NO_CLIP_GROUP)
 end)
 end
 end)
 table.insert(noclipConnections, conn)
end

local function removeNoclipFromCharacter(char)
 for _, part in ipairs(char:GetDescendants()) do
 if part:IsA("BasePart") then
 pcall(function()
 PhysicsService:SetPartCollisionGroup(part, "Default")
 end)
 end
 end
 local hum = char:FindFirstChildOfClass("Humanoid")
 if hum then
 hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
 hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
 end
end

local function enableNoclip()
 if NoclipEnabled then return end
 createNoClipGroup()
 NoclipEnabled = true
 if LocalPlayer.Character then
 applyNoclipToCharacter(LocalPlayer.Character)
 end
 LocalPlayer.CharacterAdded:Connect(function(char)
 if NoclipEnabled then
 char:WaitForChild("HumanoidRootPart")
 applyNoclipToCharacter(char)
 end
 end)
end

local function disableNoclip()
 if not NoclipEnabled then return end
 NoclipEnabled = false
 for _, conn in ipairs(noclipConnections) do
 conn:Disconnect()
 end
 noclipConnections = {}
 if LocalPlayer.Character then
 removeNoclipFromCharacter(LocalPlayer.Character)
 end
end

makeBtn("[ NOCLIP ] OFF", C.red, 3, function(b, l)
 if not NoclipEnabled then
 enableNoclip()
 else
 disableNoclip()
 end
 l.Text = "[ NOCLIP ] " .. (NoclipEnabled and "ON" or "OFF")
 local cor = NoclipEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)
end)

-- ====================== INFINITE JUMP ======================
local infiniteJumpConnection = nil
local function setInfiniteJump(enabled)
 InfiniteJumpEnabled = enabled
 if enabled then
 if infiniteJumpConnection then return end
 infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
 local char = LocalPlayer.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead then
 hum:ChangeState(Enum.HumanoidStateType.Jumping)
 end
 end)
 else
 if infiniteJumpConnection then
 infiniteJumpConnection:Disconnect()
 infiniteJumpConnection = nil
 end
 end
end

makeBtn("[ INF JUMP ] OFF", C.red, 4, function(b, l)
 local newState = not InfiniteJumpEnabled
 setInfiniteJump(newState)
 l.Text = "[ INF JUMP ] " .. (InfiniteJumpEnabled and "ON" or "OFF")
 local cor = InfiniteJumpEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)
end)

-- ====================== FIX LAG ======================
local function FixLag()
 task.spawn(function()
 local count = 0
 for _, v in ipairs(game:GetDescendants()) do
 if v:IsA("Part") or v:IsA("Union") then
 v.Material = Enum.Material.SmoothPlastic
 count += 1
 elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
 v.Enabled = false
 count += 1
 elseif v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
 v.Enabled = false
 count += 1
 elseif v:IsA("Decal") or v:IsA("Texture") then
 v.Texture = ""
 count += 1
 elseif v:IsA("Sky") then
 v:Destroy()
 count += 1
 end
 end
 game:GetService("TestService"):Message("Effects Disabler: Disabled "..count.." assets.")
 end)
end

makeBtn("[ FIX LAG ] OFF", C.red, 5, function(b, l)
 FixLagEnabled = not FixLagEnabled
 if FixLagEnabled then
 FixLag()
 end
 l.Text = "[ FIX LAG ] " .. (FixLagEnabled and "ON" or "OFF")
 local cor = FixLagEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)
end)

-- ====================== SPEED WALK ======================
local function applySpeedWalk()
 local char = LocalPlayer.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 if hum then
 hum.WalkSpeed = SpeedWalkEnabled and SPEED_WALK_VALUE or DEFAULT_WALKSPEED
 end
end

local function startSpeedWalkLoop()
 if speedWalkLoop then return end
 speedWalkLoop = RunService.Heartbeat:Connect(function()
 if SpeedWalkEnabled then
 local char = LocalPlayer.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 if hum and hum.WalkSpeed ~= SPEED_WALK_VALUE then
 hum.WalkSpeed = SPEED_WALK_VALUE -- chống anti-cheat reset
 end
 end
 end)
end

local function stopSpeedWalkLoop()
 if speedWalkLoop then
 speedWalkLoop:Disconnect()
 speedWalkLoop = nil
 end
end

makeBtn("[ SPEED WALK ] OFF", C.red, 6, function(b, l)
 SpeedWalkEnabled = not SpeedWalkEnabled
 if SpeedWalkEnabled then
 startSpeedWalkLoop()
 else
 stopSpeedWalkLoop()
 end
 applySpeedWalk()
 l.Text = "[ SPEED WALK ] " .. (SpeedWalkEnabled and "ON" or "OFF")
 local cor = SpeedWalkEnabled and C.greenD or C.red
 tw(b, {BackgroundColor3 = cor}, 0.3)
end)

-- Khung điều chỉnh tốc độ
local SpeedCtrlFrame = Instance.new("Frame")
SpeedCtrlFrame.Size = UDim2.new(1, -4, 0, 30)
SpeedCtrlFrame.BackgroundColor3 = C.bg2
SpeedCtrlFrame.BackgroundTransparency = 0.3
SpeedCtrlFrame.BorderSizePixel = 0
SpeedCtrlFrame.LayoutOrder = 7
SpeedCtrlFrame.Parent = Content
Instance.new("UICorner", SpeedCtrlFrame).CornerRadius = UDim.new(0, 8)

local MinusBtn = Instance.new("TextButton", SpeedCtrlFrame)
MinusBtn.Size = UDim2.new(0, 28, 1, 0)
MinusBtn.Position = UDim2.new(0, 4, 0, 0)
MinusBtn.BackgroundColor3 = C.bg3
MinusBtn.BorderSizePixel = 0
MinusBtn.Text = "-"
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 16
MinusBtn.TextColor3 = C.green
MinusBtn.AutoButtonColor = false
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

local SpeedLabel = Instance.new("TextLabel", SpeedCtrlFrame)
SpeedLabel.Size = UDim2.new(1, -64, 1, 0)
SpeedLabel.Position = UDim2.new(0, 32, 0, 0)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: " .. SPEED_WALK_VALUE
SpeedLabel.Font = Enum.Font.Code
SpeedLabel.TextSize = 13
SpeedLabel.TextColor3 = C.text
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center

local PlusBtn = Instance.new("TextButton", SpeedCtrlFrame)
PlusBtn.Size = UDim2.new(0, 28, 1, 0)
PlusBtn.Position = UDim2.new(1, -32, 0, 0)
PlusBtn.BackgroundColor3 = C.bg3
PlusBtn.BorderSizePixel = 0
PlusBtn.Text = "+"
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 16
PlusBtn.TextColor3 = C.green
PlusBtn.AutoButtonColor = false
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

local function updateSpeedValue(newValue)
 SPEED_WALK_VALUE = math.clamp(newValue, MIN_SPEED_WALK, MAX_SPEED_WALK)
 SpeedLabel.Text = "Speed: " .. SPEED_WALK_VALUE
 if SpeedWalkEnabled then
 applySpeedWalk()
 end
end

MinusBtn.MouseButton1Click:Connect(function()
 updateSpeedValue(SPEED_WALK_VALUE - SPEED_STEP)
end)

PlusBtn.MouseButton1Click:Connect(function()
 updateSpeedValue(SPEED_WALK_VALUE + SPEED_STEP)
end)

-- ====================== CREDIT ======================
local Credit = Instance.new("TextLabel", Frame)
Credit.Size = UDim2.new(1, 0, 0, 26)
Credit.Position = UDim2.new(0, 0, 1, -26)
Credit.BackgroundColor3 = C.bg2
Credit.BackgroundTransparency = 0.5
Credit.BorderSizePixel = 0
Credit.Text = "01010101"
Credit.Font = Enum.Font.Code
Credit.TextSize = 11
Credit.TextColor3 = C.textD
Credit.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", Credit).CornerRadius = UDim.new(0, 16)

-- ====================== DRAG SYSTEM ======================
local dragging = false
local dragObj = nil
local dragOffset = Vector2.new(0, 0)
local dragStartPos = UDim2.new(0, 0, 0, 0)

TopBar.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 dragging = true
 dragObj = Frame
 dragOffset = input.Position
 dragStartPos = Frame.Position
 end
end)

Ball.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 dragging = true
 dragObj = Ball
 dragOffset = input.Position
 dragStartPos = Ball.Position
 end
end)

UserInputService.InputChanged:Connect(function(input)
 if dragging and dragObj and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
 local delta = input.Position - dragOffset
 dragObj.Position = UDim2.new(
 dragStartPos.X.Scale,
 dragStartPos.X.Offset + delta.X,
 dragStartPos.Y.Scale,
 dragStartPos.Y.Offset + delta.Y
 )
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
 dragging = false
 dragObj = nil
 end
end)

-- ====================== MINIMIZE / RESTORE ======================
local minimized = false

local function minimize()
 minimized = true
 local fp = Frame.Position
 Frame.Visible = false
 Ball.Position = fp
 Ball.Size = UDim2.new(0, 50, 0, 50)
 Ball.Visible = true
end

local function restore()
 minimized = false
 local bp = Ball.Position
 Ball.Visible = false
 Frame.Position = bp
 Frame.Visible = true
end

MinBtn.MouseButton1Click:Connect(function()
 if not minimized then minimize() else restore() end
end)

Ball.MouseButton1Click:Connect(function()
 if minimized then restore() end
end)

-- ====================== COLLAPSE / EXPAND ======================
local collapsed = false
local originalFrameSize = UDim2.new(0, dw, 0, dh)

local function collapseMenu()
 collapsed = true
 tw(Frame, {Size = UDim2.new(0, dw, 0, 36)}, 0.3)
 Content.Visible = false
 Credit.Visible = false
 CollapseBtn.Text = "+"
end

local function expandMenu()
 collapsed = false
 tw(Frame, {Size = originalFrameSize}, 0.3)
 Content.Visible = true
 Credit.Visible = true
 CollapseBtn.Text = "-"
end

CollapseBtn.MouseButton1Click:Connect(function()
 if collapsed then expandMenu() else collapseMenu() end
end)

-- ====================== ESP SETUP ======================
local function createEsp(plr)
 if plr == LocalPlayer then return end
 if not supportsDrawing then return end
 local box = Drawing.new("Square")
 box.Thickness = 1.5
 box.Filled = false
 box.Visible = false

 local line = Drawing.new("Line")
 line.Thickness = 1.5
 line.Visible = false

 local nameTag = Drawing.new("Text")
 nameTag.Text = plr.Name
 nameTag.Size = 14
 nameTag.Center = true
 nameTag.Outline = true
 nameTag.OutlineColor = Color3.new(0,0,0)
 nameTag.Color = Color3.fromRGB(255, 255, 255)
 nameTag.Visible = false

 local distanceTag = Drawing.new("Text")
 distanceTag.Text = ""
 distanceTag.Size = 13
 distanceTag.Center = true
 distanceTag.Outline = true
 distanceTag.OutlineColor = Color3.new(0,0,0)
 distanceTag.Color = Color3.fromRGB(255, 255, 100)
 distanceTag.Visible = false

 EspObjects[plr] = {
 box = box,
 line = line,
 nameTag = nameTag,
 distanceTag = distanceTag
 }
end

Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(function(plr)
 if EspObjects[plr] then
 if EspObjects[plr].box then EspObjects[plr].box:Remove() end
 if EspObjects[plr].line then EspObjects[plr].line:Remove() end
 if EspObjects[plr].nameTag then EspObjects[plr].nameTag:Remove() end
 if EspObjects[plr].distanceTag then EspObjects[plr].distanceTag:Remove() end
 EspObjects[plr] = nil
 end
end)

for _, p in pairs(Players:GetPlayers()) do
 createEsp(p)
end

-- Ban đầu tắt các chức năng
disableNoclip()