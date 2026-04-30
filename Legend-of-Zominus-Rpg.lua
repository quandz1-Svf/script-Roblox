local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 140, 0, 50)
frame.Position = UDim2.new(0.5, -70, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Toggle button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 90, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = frame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 1, 0)
closeBtn.Position = UDim2.new(0, 96, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "❌"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeBtn

-- ===== DRAG =====
local dragging = false
local dragStartPos
local frameStartPos

frame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = true
dragStartPos = input.Position
frameStartPos = frame.AbsolutePosition
end
end)

UserInputService.InputChanged:Connect(function(input)
if not dragging then return end
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseMovement then
local delta = input.Position - dragStartPos
frame.Position = UDim2.new(
0, frameStartPos.X + delta.X,
0, frameStartPos.Y + delta.Y
)
end
end)

UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = false
end
end)

toggleBtn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = false
end
end)

closeBtn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch
or input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = false
end
end)

-- ===== CORE LOGIC =====
local isOn = false
local loopThread = nil
local RANGE = 50
local INTERVAL = 0.5

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
local remote = remotesFolder and remotesFolder:WaitForChild("DealDamage", 10)

if not remote then
warn("[AuraUI] Không tìm thấy Remote 'DealDamage'!")
end

local function getNearestMobName()
local mobs = workspace:FindFirstChild("Mobs")
if not mobs then return nil end

local root = character and character:FindFirstChild("HumanoidRootPart")  
if not root then return nil end  

local nearest = nil  
local nearestDist = math.huge  

for _, folder in ipairs(mobs:GetChildren()) do  
    if folder:IsA("Folder") or folder:IsA("Model") then  
        local children = folder:IsA("Folder") and folder:GetChildren() or {folder}  
        for _, model in ipairs(children) do  
            if model:IsA("Model") then  
                local humanoid = model:FindFirstChildWhichIsA("Humanoid")  
                -- FIX: Bỏ qua mob đã chết  
                if humanoid and humanoid.Health > 0 then  
                    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")  
                    if primary then  
                        local dist = (primary.Position - root.Position).Magnitude  
                        if dist < RANGE and dist < nearestDist then  
                            nearestDist = dist  
                            nearest = model  
                        end  
                    end  
                end  
            end  
        end  
    end  
end  

return nearest and nearest.Name or nil

end

local function startLoop()
if loopThread then
task.cancel(loopThread)
loopThread = nil
end

loopThread = task.spawn(function()  
    while isOn do  
        if remote then  
            local mobName = getNearestMobName()  
            if mobName then  
                -- FIX: Wrap tên mob vào table đúng format server expect  
                remote:FireServer({mobName})  
            end  
        end  
        task.wait(INTERVAL)  
    end  
end)

end

local tweenInfo = TweenInfo.new(0.2)

toggleBtn.Activated:Connect(function()
isOn = not isOn
if isOn then
toggleBtn.Text = "ON"
TweenService:Create(toggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(50, 200, 80)}):Play()
startLoop()
else
toggleBtn.Text = "OFF"
TweenService:Create(toggleBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
if loopThread then
task.cancel(loopThread)
loopThread = nil
end
end
end)

closeBtn.Activated:Connect(function()
isOn = false
if loopThread then
task.cancel(loopThread)
loopThread = nil
end
screenGui:Destroy()
end)

player.CharacterAdded:Connect(function(char)
character = char
end)
