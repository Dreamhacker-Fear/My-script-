--// Fling Gui V35.0
--// by prespeshnikShashlika
--// Patched: mobile drag, scroll, centered, avatar fix

workspace.FallenPartsDestroyHeight = 0/0
game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local flingActive = false
local hiddenfling = false
local AntiFlingEnabled = false
local AntiKillPartsEnabled = false
local connection = nil
local processedPlayers = {}
local currentInput = ""
local SteppedConnection = nil
local isNoclipEnabled = false
local flingMode = 1
local autoEquipEnabled = false
local autoEquipToolName = nil
local autoEquipConnection = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlingGUI"
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 320)
frame.Position = UDim2.new(0.5, -100, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BackgroundTransparency = 0.3
frame.Parent = screenGui
frame.Active = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = frame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollContainer"
scrollFrame.Size = UDim2.new(1, 0, 1, -35)
scrollFrame.Position = UDim2.new(0, 0, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.Parent = frame

local scrollContainer = Instance.new("Frame")
scrollContainer.Name = "Container"
scrollContainer.Size = UDim2.new(1, 0, 0, 0)
scrollContainer.AutomaticSize = Enum.AutomaticSize.Y
scrollContainer.BackgroundTransparency = 1
scrollContainer.Parent = scrollFrame

local scrollLayout = Instance.new("UIListLayout", scrollContainer)
scrollLayout.FillDirection = Enum.FillDirection.Vertical
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Padding = UDim.new(0, 5)

local toggleMinimizeBtn = Instance.new("TextButton")
toggleMinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
toggleMinimizeBtn.Position = UDim2.new(1, -25, 0, 5)
toggleMinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleMinimizeBtn.Text = "-"
toggleMinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
toggleMinimizeBtn.TextSize = 14
toggleMinimizeBtn.ZIndex = 2
toggleMinimizeBtn.Parent = frame

local togglePhaseBtn = Instance.new("TextButton")
togglePhaseBtn.Size = UDim2.new(0, 20, 0, 20)
togglePhaseBtn.Position = UDim2.new(0, 5, 0, 5)
togglePhaseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
togglePhaseBtn.Text = "1"
togglePhaseBtn.TextColor3 = Color3.new(1, 1, 1)
togglePhaseBtn.TextSize = 14
togglePhaseBtn.ZIndex = 2
togglePhaseBtn.Parent = frame

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 4)
minimizeCorner.Parent = toggleMinimizeBtn
minimizeCorner:Clone().Parent = togglePhaseBtn

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Fling GUI"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local textGradient = Instance.new("UIGradient", title)
textGradient.Rotation = 90

local function lerpColor(color1, color2, alpha)
    return Color3.new(
        color1.R + (color2.R - color1.R) * alpha,
        color1.G + (color2.G - color1.G) * alpha,
        color1.B + (color2.B - color1.B) * alpha
    )
end

task.spawn(function()
    local steps = 60
    local stepTime = 2 / steps
    local c1 = Color3.fromRGB(255, 255, 255)
    local c2 = Color3.fromRGB(0, 0, 0)
    while true do
        for i = 0, steps do
            local a = i / steps
            textGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, lerpColor(c1, c2, a)),
                ColorSequenceKeypoint.new(1, lerpColor(c2, c1, a))
            })
            task.wait(stepTime)
        end
        for i = 0, steps do
            local a = i / steps
            textGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, lerpColor(c2, c1, a)),
                ColorSequenceKeypoint.new(1, lerpColor(c1, c2, a))
            })
            task.wait(stepTime)
        end
    end
end)

local borderFrame = Instance.new("Frame")
borderFrame.Size = frame.Size
borderFrame.Position = frame.Position
borderFrame.BackgroundTransparency = 1
borderFrame.AnchorPoint = frame.AnchorPoint
borderFrame.ZIndex = frame.ZIndex - 1
borderFrame.Parent = screenGui

local borderCorner = frame.UICorner:Clone()
borderCorner.Parent = borderFrame

local borderStroke = Instance.new("UIStroke")
borderStroke.Thickness = 3
borderStroke.LineJoinMode = Enum.LineJoinMode.Round
borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
borderStroke.Parent = borderFrame

-- Drag system
local _dragging = false
local _dragStart = nil
local _startPos = nil

local function _startDrag(input)
    _dragging = true
    _dragStart = input.Position
    _startPos = frame.Position
end

local function _updateDrag(input)
    if not _dragging then return end
    local delta = input.Position - _dragStart
    local screenSize = workspace.CurrentCamera.ViewportSize
    local frameSize = frame.AbsoluteSize
    local newX = _startPos.X.Offset + delta.X
    local newY = _startPos.Y.Offset + delta.Y
    newX = math.clamp(newX, 0, math.max(0, screenSize.X - frameSize.X))
    newY = math.clamp(newY, 0, math.max(0, screenSize.Y - frameSize.Y))
    frame.Position = UDim2.fromOffset(newX, newY)
end

local function _stopDrag()
    _dragging = false
end

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        _startDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch then
        _updateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        _stopDrag()
    end
end)

frame:GetPropertyChangedSignal("Position"):Connect(function()
    borderFrame.Position = frame.Position
end)

frame:GetPropertyChangedSignal("Size"):Connect(function()
    borderFrame.Size = frame.Size
end)

local invisibleExpandBtn = Instance.new("TextButton")
invisibleExpandBtn.Size = UDim2.new(1, 0, 1, 0)
invisibleExpandBtn.Position = UDim2.new(0, 0, 0, 0)
invisibleExpandBtn.BackgroundTransparency = 1
invisibleExpandBtn.Text = ""
invisibleExpandBtn.TextTransparency = 1
invisibleExpandBtn.Visible = false
invisibleExpandBtn.Parent = frame

invisibleExpandBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        _startDrag(input)
    end
end)

-- Buttons
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -10, 0, 30)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
inputBox.Text = ""
inputBox.PlaceholderText = "nickname, all, nonfriends"
inputBox.TextColor3 = Color3.new(1, 1, 1)
inputBox.ClearTextOnFocus = false
inputBox.Parent = scrollContainer
inputBox.TextSize = 14
inputBox.Font = Enum.Font.Code
inputBox.LayoutOrder = 1
Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 6)

local toggleBtnContainer = Instance.new("Frame")
toggleBtnContainer.Size = UDim2.new(1, -10, 0, 30)
toggleBtnContainer.BackgroundTransparency = 1
toggleBtnContainer.Parent = scrollContainer
toggleBtnContainer.LayoutOrder = 2

local toggleBtnMode = Instance.new("TextButton")
toggleBtnMode.Size = UDim2.new(0.25, 0, 1, 0)
toggleBtnMode.Position = UDim2.new(0, 0, 0, 0)
toggleBtnMode.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtnMode.Text = "1"
toggleBtnMode.TextColor3 = Color3.new(1, 1, 1)
toggleBtnMode.Parent = toggleBtnContainer

local toggleBtnMain = Instance.new("TextButton")
toggleBtnMain.Size = UDim2.new(0.75, 0, 1, 0)
toggleBtnMain.Position = UDim2.new(0.25, 0, 0, 0)
toggleBtnMain.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleBtnMain.Text = "Fling Players: OFF"
toggleBtnMain.TextColor3 = Color3.new(1, 1, 1)
toggleBtnMain.Parent = toggleBtnContainer
toggleBtnMain.Font = Enum.Font.Sarpanch
toggleBtnMain.TextSize = 16

local touchFlingBtn = Instance.new("TextButton")
touchFlingBtn.Size = UDim2.new(1, -10, 0, 30)
touchFlingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
touchFlingBtn.Text = "Touch Fling: OFF"
touchFlingBtn.TextColor3 = Color3.new(1, 1, 1)
touchFlingBtn.Parent = scrollContainer
touchFlingBtn.Font = Enum.Font.Sarpanch
touchFlingBtn.TextSize = 16
touchFlingBtn.LayoutOrder = 3

local antiFlingBtn = Instance.new("TextButton")
antiFlingBtn.Size = UDim2.new(1, -10, 0, 30)
antiFlingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
antiFlingBtn.Text = "Anti Fling: OFF"
antiFlingBtn.TextColor3 = Color3.new(1, 1, 1)
antiFlingBtn.Parent = scrollContainer
antiFlingBtn.Font = Enum.Font.Sarpanch
antiFlingBtn.TextSize = 16
antiFlingBtn.LayoutOrder = 4

local antiKillBtn = Instance.new("TextButton")
antiKillBtn.Size = UDim2.new(1, -10, 0, 30)
antiKillBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
antiKillBtn.Text = "Anti Kill Parts: OFF"
antiKillBtn.TextColor3 = Color3.new(1, 1, 1)
antiKillBtn.Parent = scrollContainer
antiKillBtn.Font = Enum.Font.Sarpanch
antiKillBtn.TextSize = 16
antiKillBtn.LayoutOrder = 5

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(1, -10, 0, 30)
loadBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
loadBtn.Text = "Noclip: OFF"
loadBtn.TextColor3 = Color3.new(1, 1, 1)
loadBtn.Parent = scrollContainer
loadBtn.Font = Enum.Font.Sarpanch
loadBtn.TextSize = 16
loadBtn.LayoutOrder = 6

local phase2Button1 = Instance.new("TextButton")
phase2Button1.Size = UDim2.new(1, -10, 0, 30)
phase2Button1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button1.Text = "Strength: OFF"
phase2Button1.TextColor3 = Color3.new(1, 1, 1)
phase2Button1.Visible = false
phase2Button1.Parent = scrollContainer
phase2Button1.Font = Enum.Font.Sarpanch
phase2Button1.TextSize = 16
phase2Button1.LayoutOrder = 10

local phase2Button2 = Instance.new("TextButton")
phase2Button2.Size = UDim2.new(1, -10, 0, 30)
phase2Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button2.Text = "Spawnpoint: OFF"
phase2Button2.TextColor3 = Color3.new(1, 1, 1)
phase2Button2.Visible = false
phase2Button2.Parent = scrollContainer
phase2Button2.Font = Enum.Font.Sarpanch
phase2Button2.TextSize = 16
phase2Button2.LayoutOrder = 11

local phase2Button3 = Instance.new("TextButton")
phase2Button3.Size = UDim2.new(1, -10, 0, 30)
phase2Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button3.Text = "Anti Slap: OFF"
phase2Button3.TextColor3 = Color3.new(1, 1, 1)
phase2Button3.Visible = false
phase2Button3.Parent = scrollContainer
phase2Button3.Font = Enum.Font.Sarpanch
phase2Button3.TextSize = 16
phase2Button3.LayoutOrder = 12

local phase2Button4 = Instance.new("TextButton")
phase2Button4.Size = UDim2.new(1, -10, 0, 30)
phase2Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button4.Text = "Xeno AntiFling: OFF"
phase2Button4.TextColor3 = Color3.new(1, 1, 1)
phase2Button4.Visible = false
phase2Button4.Parent = scrollContainer
phase2Button4.Font = Enum.Font.Sarpanch
phase2Button4.TextSize = 16
phase2Button4.LayoutOrder = 13

local phase2Button5 = Instance.new("TextButton")
phase2Button5.Size = UDim2.new(1, -10, 0, 30)
phase2Button5.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button5.Text = "Infinite Position: OFF"
phase2Button5.TextColor3 = Color3.new(1, 1, 1)
phase2Button5.Visible = false
phase2Button5.Parent = scrollContainer
phase2Button5.Font = Enum.Font.Sarpanch
phase2Button5.TextSize = 16
phase2Button5.LayoutOrder = 14

local phase2Button6 = Instance.new("TextButton")
phase2Button6.Size = UDim2.new(1, -10, 0, 30)
phase2Button6.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase2Button6.Text = "NDS Anti Fall Damage: OFF"
phase2Button6.TextColor3 = Color3.new(1, 1, 1)
phase2Button6.Visible = false
phase2Button6.Parent = scrollContainer
phase2Button6.Font = Enum.Font.Sarpanch
phase2Button6.TextSize = 16
phase2Button6.LayoutOrder = 15

local phase3Button1 = Instance.new("TextButton")
phase3Button1.Size = UDim2.new(1, -10, 0, 30)
phase3Button1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button1.Text = "Anti Sit: OFF"
phase3Button1.TextColor3 = Color3.new(1, 1, 1)
phase3Button1.Visible = false
phase3Button1.Parent = scrollContainer
phase3Button1.Font = Enum.Font.Sarpanch
phase3Button1.TextSize = 16
phase3Button1.LayoutOrder = 20

local phase3Button2 = Instance.new("TextButton")
phase3Button2.Size = UDim2.new(1, -10, 0, 30)
phase3Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button2.Text = "Anti Conveyor: OFF"
phase3Button2.TextColor3 = Color3.new(1, 1, 1)
phase3Button2.Visible = false
phase3Button2.Parent = scrollContainer
phase3Button2.Font = Enum.Font.Sarpanch
phase3Button2.TextSize = 16
phase3Button2.LayoutOrder = 21

local phase3Button3 = Instance.new("TextButton")
phase3Button3.Size = UDim2.new(1, -10, 0, 30)
phase3Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button3.Text = "FreeCam: OFF"
phase3Button3.TextColor3 = Color3.new(1, 1, 1)
phase3Button3.Visible = false
phase3Button3.Parent = scrollContainer
phase3Button3.Font = Enum.Font.Sarpanch
phase3Button3.TextSize = 16
phase3Button3.LayoutOrder = 22

local phase3Button4 = Instance.new("TextButton")
phase3Button4.Size = UDim2.new(1, -10, 0, 30)
phase3Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button4.Text = "Invis: OFF"
phase3Button4.TextColor3 = Color3.new(1, 1, 1)
phase3Button4.Visible = false
phase3Button4.Parent = scrollContainer
phase3Button4.Font = Enum.Font.Sarpanch
phase3Button4.TextSize = 16
phase3Button4.LayoutOrder = 23

local phase3Button5 = Instance.new("TextButton")
phase3Button5.Size = UDim2.new(1, -10, 0, 30)
phase3Button5.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button5.Text = "Anti Ragdoll: OFF"
phase3Button5.TextColor3 = Color3.new(1, 1, 1)
phase3Button5.Visible = false
phase3Button5.Parent = scrollContainer
phase3Button5.Font = Enum.Font.Sarpanch
phase3Button5.TextSize = 16
phase3Button5.LayoutOrder = 24

local phase3Button6 = Instance.new("TextButton")
phase3Button6.Size = UDim2.new(1, -10, 0, 30)
phase3Button6.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase3Button6.Text = "Punch Fling"
phase3Button6.TextColor3 = Color3.new(1, 1, 1)
phase3Button6.Visible = false
phase3Button6.Parent = scrollContainer
phase3Button6.Font = Enum.Font.Sarpanch
phase3Button6.TextSize = 16
phase3Button6.LayoutOrder = 25

local phase4Button1 = Instance.new("TextButton")
phase4Button1.Size = UDim2.new(1, -10, 0, 30)
phase4Button1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase4Button1.Text = "Lightness: OFF"
phase4Button1.TextColor3 = Color3.new(1, 1, 1)
phase4Button1.Visible = false
phase4Button1.Parent = scrollContainer
phase4Button1.Font = Enum.Font.Sarpanch
phase4Button1.TextSize = 16
phase4Button1.LayoutOrder = 30

local phase4Button2 = Instance.new("TextButton")
phase4Button2.Size = UDim2.new(1, -10, 0, 30)
phase4Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase4Button2.Text = "Big Gravity: OFF"
phase4Button2.TextColor3 = Color3.new(1, 1, 1)
phase4Button2.Visible = false
phase4Button2.Parent = scrollContainer
phase4Button2.Font = Enum.Font.Sarpanch
phase4Button2.TextSize = 16
phase4Button2.LayoutOrder = 31

local phase4Button3 = Instance.new("TextButton")
phase4Button3.Size = UDim2.new(1, -10, 0, 30)
phase4Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase4Button3.Text = "Anti Tornado (test): OFF"
phase4Button3.TextColor3 = Color3.new(1, 1, 1)
phase4Button3.Visible = false
phase4Button3.Parent = scrollContainer
phase4Button3.Font = Enum.Font.Sarpanch
phase4Button3.TextSize = 16
phase4Button3.LayoutOrder = 32

local phase4Button4 = Instance.new("TextButton")
phase4Button4.Size = UDim2.new(1, -10, 0, 30)
phase4Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
phase4Button4.Text = "Auto Equip: OFF"
phase4Button4.TextColor3 = Color3.new(1, 1, 1)
phase4Button4.Visible = false
phase4Button4.Parent = scrollContainer
phase4Button4.Font = Enum.Font.Sarpanch
phase4Button4.TextSize = 16
phase4Button4.LayoutOrder = 33

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Waiting..."
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Parent = scrollContainer
statusLabel.LayoutOrder = 40

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -10, 0, 20)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 0 studs/s"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 14
speedLabel.Parent = scrollContainer
speedLabel.LayoutOrder = 41

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtnMain
for _, btn in ipairs({toggleBtnMode, touchFlingBtn, antiFlingBtn, antiKillBtn, loadBtn,
    phase2Button1, phase2Button2, phase2Button3, phase2Button4, phase2Button5, phase2Button6,
    phase3Button1, phase3Button2, phase3Button3, phase3Button4, phase3Button5, phase3Button6,
    phase4Button1, phase4Button2, phase4Button3, phase4Button4}) do
    btnCorner:Clone().Parent = btn
end

local isMinimized = false
local originalSize = frame.Size
local originalTitle = title.Text
local isPhase2 = false
local isPhase3 = false
local isPhase4 = false

local function togglePhase()
    if not isPhase2 and not isPhase3 and not isPhase4 then
        isPhase2 = true
        togglePhaseBtn.Text = "2"
        inputBox.Visible = false
        toggleBtnContainer.Visible = false
        touchFlingBtn.Visible = false
        antiFlingBtn.Visible = false
        antiKillBtn.Visible = false
        loadBtn.Visible = false
        phase2Button1.Visible = true
        phase2Button2.Visible = true
        phase2Button3.Visible = true
        phase2Button4.Visible = true
        phase2Button5.Visible = true
        phase2Button6.Visible = true
    elseif isPhase2 then
        isPhase2 = false
        isPhase3 = true
        togglePhaseBtn.Text = "3"
        phase2Button1.Visible = false
        phase2Button2.Visible = false
        phase2Button3.Visible = false
        phase2Button4.Visible = false
        phase2Button5.Visible = false
        phase2Button6.Visible = false
        phase3Button1.Visible = true
        phase3Button2.Visible = true
        phase3Button3.Visible = true
        phase3Button4.Visible = true
        phase3Button5.Visible = true
        phase3Button6.Visible = true
    elseif isPhase3 then
        isPhase3 = false
        isPhase4 = true
        togglePhaseBtn.Text = "4"
        phase3Button1.Visible = false
        phase3Button2.Visible = false
        phase3Button3.Visible = false
        phase3Button4.Visible = false
        phase3Button5.Visible = false
        phase3Button6.Visible = false
        phase4Button1.Visible = true
        phase4Button2.Visible = true
        phase4Button3.Visible = true
        phase4Button4.Visible = true
    else
        isPhase4 = false
        togglePhaseBtn.Text = "1"
        inputBox.Visible = true
        toggleBtnContainer.Visible = true
        touchFlingBtn.Visible = true
        antiFlingBtn.Visible = true
        antiKillBtn.Visible = true
        loadBtn.Visible = true
        phase4Button1.Visible = false
        phase4Button2.Visible = false
        phase4Button3.Visible = false
        phase4Button4.Visible = false
    end
end

togglePhaseBtn.MouseButton1Click:Connect(togglePhase)

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        title.Text = "FG"
        title.Size = UDim2.new(1, 0, 1, 0)
        title.Position = UDim2.new(0, 0, 0, 0)
        scrollFrame.Visible = false
        toggleMinimizeBtn.Visible = false
        togglePhaseBtn.Visible = false
        frame.Size = UDim2.new(0, 60, 0, 30)
        invisibleExpandBtn.Visible = true
        invisibleExpandBtn.Active = true
    else
        toggleMinimizeBtn.Visible = true
        togglePhaseBtn.Visible = true
        frame.Size = originalSize
        title.Text = originalTitle
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 5)
        scrollFrame.Visible = true
        invisibleExpandBtn.Visible = false
    end
end

toggleMinimizeBtn.MouseButton1Click:Connect(toggleMinimize)

invisibleExpandBtn.MouseButton1Click:Connect(function()
    if isMinimized then toggleMinimize() end
end)

local densityEnabled = false
local densityConnections = {}
local originalDensityProperties = {}

local function manageDensity(character, enable)
    if not character or not character:IsA("Model") then return end
    for _, conn in pairs(densityConnections) do conn:Disconnect() end
    densityConnections = {}
    if enable then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not originalDensityProperties[part] then
                    originalDensityProperties[part] = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5)
                end
                part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.3, 0.5)
                table.insert(densityConnections, part:GetPropertyChangedSignal("CustomPhysicalProperties"):Connect(function()
                    if densityEnabled then
                        local current = part.CustomPhysicalProperties
                        if not current or current.Density ~= 0.001 then
                            part.CustomPhysicalProperties = PhysicalProperties.new(0.001, 0.3, 0.5)
                        end
                    end
                end))
            end
        end
    else
        for part, props in pairs(originalDensityProperties) do
            if part:IsA("BasePart") and part.Parent then
                part.CustomPhysicalProperties = props
            end
        end
        originalDensityProperties = {}
    end
end

phase4Button1.MouseButton1Click:Connect(function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    densityEnabled = not densityEnabled
    if character then manageDensity(character, densityEnabled) end
    phase4Button1.Text = densityEnabled and "Lightness: ON" or "Lightness OFF"
    phase4Button1.BackgroundColor3 = densityEnabled and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(60, 60, 60)
end)

local gravityEnabled = false
local gravityConnection = nil

phase4Button2.MouseButton1Click:Connect(function()
    gravityEnabled = not gravityEnabled
    if gravityEnabled then
        workspace.Gravity = 1000000000000
        if gravityConnection then gravityConnection:Disconnect() end
        gravityConnection = game:GetService("RunService").Heartbeat:Connect(function()
            pcall(function()
                if workspace.Gravity ~= 1000000000000 then
                    workspace.Gravity = 1000000000000
                end
            end)
        end)
        phase4Button2.Text = "Big Gravity: ON"
        phase4Button2.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        if gravityConnection then gravityConnection:Disconnect(); gravityConnection = nil end
        workspace.Gravity = 196.2
        phase4Button2.Text = "Big Gravity: OFF"
        phase4Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

phase3Button6.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://github.com/sovetskii-shashlik/Test/raw/main/PunchFling",true))()
end)

local function startAutoEquip()
    if autoEquipConnection then autoEquipConnection:Disconnect() end
    autoEquipConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not autoEquipEnabled or not autoEquipToolName then return end
        local character = localPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local equippedTool = character:FindFirstChild(autoEquipToolName)
        if equippedTool then return end
        local backpack = localPlayer:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild(autoEquipToolName)
            if tool then humanoid:EquipTool(tool) end
        end
    end)
end

phase4Button4.MouseButton1Click:Connect(function()
    autoEquipEnabled = not autoEquipEnabled
    if autoEquipEnabled then
        local character = localPlayer.Character
        local currentTool = character and character:FindFirstChildWhichIsA("Tool")
        autoEquipToolName = currentTool and currentTool.Name or nil
        if not autoEquipToolName then
            autoEquipEnabled = false
            phase4Button4.Text = "Auto Equip: OFF"
            phase4Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            return
        end
        startAutoEquip()
        phase4Button4.Text = "Auto Equip: ON"
        phase4Button4.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        if autoEquipConnection then autoEquipConnection:Disconnect(); autoEquipConnection = nil end
        autoEquipToolName = nil
        phase4Button4.Text = "Auto Equip: OFF"
        phase4Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

local isStrengthened = false
local connections = {}
local originalProperties = {}

local function manageStrength(character, enable)
    if not character or not character:IsA("Model") then return end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    if enable then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not originalProperties[part] then
                    originalProperties[part] = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5)
                end
                part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                table.insert(connections, part:GetPropertyChangedSignal("CustomPhysicalProperties"):Connect(function()
                    if isStrengthened then
                        local current = part.CustomPhysicalProperties
                        if not current or current.Density < 100 then
                            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                        end
                    end
                end))
            end
        end
    else
        for part, props in pairs(originalProperties) do
            if part:IsA("BasePart") and part.Parent then
                part.CustomPhysicalProperties = props
            end
        end
        originalProperties = {}
    end
end

phase2Button1.MouseButton1Click:Connect(function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    isStrengthened = not isStrengthened
    if character then manageStrength(character, isStrengthened) end
    phase2Button1.Text = isStrengthened and "Strength: ON" or "Strength: OFF"
    phase2Button1.BackgroundColor3 = isStrengthened and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(60, 60, 60)
end)

local spawnpointActive = false
local savedPosition = nil
local spawnCharacterConn = nil

phase2Button2.MouseButton1Click:Connect(function()
    spawnpointActive = not spawnpointActive
    if spawnpointActive then
        phase2Button2.Text = "Spawnpoint: ON"
        phase2Button2.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        local character = localPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            savedPosition = character.HumanoidRootPart.CFrame
        end
        if spawnCharacterConn then spawnCharacterConn:Disconnect() end
        spawnCharacterConn = localPlayer.CharacterAdded:Connect(function(char)
            if not spawnpointActive then return end
            local rp = char:WaitForChild("HumanoidRootPart", 1)
            if rp and savedPosition then rp.CFrame = savedPosition end
        end)
    else
        phase2Button2.Text = "Spawnpoint: OFF"
        phase2Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        savedPosition = nil
        if spawnCharacterConn then spawnCharacterConn:Disconnect(); spawnCharacterConn = nil end
    end
end)

local as = false

local function dobv(v, char)
    if not as then return end
    if v:IsA("BodyAngularVelocity") then
        v:Destroy()
    elseif v:IsA("BodyGyro") and v.MaxTorque ~= Vector3.new(8999999488, 8999999488, 8999999488) then
        v:Destroy()
    elseif v:IsA("BodyVelocity") and v.MaxForce ~= Vector3.new(8999999488, 8999999488, 8999999488) then
        v:Destroy()
    elseif v:IsA("BasePart") then
        v.ChildAdded:Connect(function(v2) dobv(v2, char) end)
    end
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Sit = false
        char.Humanoid.PlatformStand = false
    end
end

local function dc(c)
    for i,v in pairs(c:GetChildren()) do
        dobv(v, c)
        for i,v in pairs(v:GetChildren()) do dobv(v, c) end
    end
    c.ChildAdded:Connect(function(v) dobv(v, c) end)
end

phase2Button3.MouseButton1Click:Connect(function()
    as = not as
    if as then
        phase2Button3.Text = "Anti Slap: ON"
        phase2Button3.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        if localPlayer.Character then dc(localPlayer.Character) end
    else
        phase2Button3.Text = "Anti Slap: OFF"
        phase2Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

localPlayer.CharacterAdded:Connect(dc)

local XenoAntiFlingEnabled = false
local XenoAntiFlingConnection = nil

phase2Button4.MouseButton1Click:Connect(function()
    XenoAntiFlingEnabled = not XenoAntiFlingEnabled
    if XenoAntiFlingEnabled then
        phase2Button4.Text = "Xeno AntiFling: ON"
        phase2Button4.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        XenoAntiFlingConnection = game:GetService("RunService").Stepped:Connect(function()
            pcall(function()
                for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= localPlayer and p.Character then
                        for _, v in pairs(p.Character:GetChildren()) do
                            pcall(function()
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Velocity = Vector3.new(0,0,0)
                                    v.RotVelocity = Vector3.new(0,0,0)
                                    v.Massless = true
                                end
                            end)
                        end
                    end
                end
            end)
        end)
    else
        phase2Button4.Text = "Xeno AntiFling: OFF"
        phase2Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        if XenoAntiFlingConnection then XenoAntiFlingConnection:Disconnect(); XenoAntiFlingConnection = nil end
    end
end)

local infinitePositionEnabled = false
local savedInfinitePosition = nil
local infinitePositionConnection = nil
local respawnConnectionIP = nil

local function handleRespawn()
    if not infinitePositionEnabled or not savedInfinitePosition then return end
    local rp = localPlayer.Character:WaitForChild("HumanoidRootPart", 1)
    if rp then
        task.wait(0.0001)
        rp.CFrame = savedInfinitePosition
        rp.Velocity = Vector3.new()
        rp.RotVelocity = Vector3.new()
    end
end

phase2Button5.MouseButton1Click:Connect(function()
    infinitePositionEnabled = not infinitePositionEnabled
    if infinitePositionEnabled then
        local character = localPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            savedInfinitePosition = character.HumanoidRootPart.CFrame
        end
        if respawnConnectionIP then respawnConnectionIP:Disconnect() end
        respawnConnectionIP = localPlayer.CharacterAdded:Connect(handleRespawn)
        if infinitePositionConnection then infinitePositionConnection:Disconnect() end
        infinitePositionConnection = RunService.Heartbeat:Connect(function()
            if not infinitePositionEnabled then return end
            if flingActive then return end
            local char = localPlayer.Character
            if not char then return end
            local rp = char:FindFirstChild("HumanoidRootPart")
            if not rp then return end
            if (rp.Position - savedInfinitePosition.Position).Magnitude > 0.1 then
                rp.CFrame = savedInfinitePosition
                rp.Velocity = Vector3.new()
                rp.RotVelocity = Vector3.new()
            end
        end)
        phase2Button5.Text = "Infinite Position: ON"
        phase2Button5.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        savedInfinitePosition = nil
        if infinitePositionConnection then infinitePositionConnection:Disconnect(); infinitePositionConnection = nil end
        if respawnConnectionIP then respawnConnectionIP:Disconnect(); respawnConnectionIP = nil end
        phase2Button5.Text = "Infinite Position: OFF"
        phase2Button5.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

local afdEnabled = false
local afdConnections = {}

phase2Button6.MouseButton1Click:Connect(function()
    afdEnabled = not afdEnabled
    if afdEnabled then
        phase2Button6.Text = "NDS Anti Fall Damage: ON"
        phase2Button6.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        local function setupAFD(character)
            if not character then return end
            local rp = character:WaitForChild("HumanoidRootPart", 1)
            if not rp then return end
            local conn = RunService.Heartbeat:Connect(function()
                if not rp.Parent then conn:Disconnect() return end
                local v = rp.AssemblyLinearVelocity
                rp.AssemblyLinearVelocity = Vector3.zero
                RunService.RenderStepped:Wait()
                rp.AssemblyLinearVelocity = v
            end)
            table.insert(afdConnections, conn)
        end
        if localPlayer.Character then setupAFD(localPlayer.Character) end
        table.insert(afdConnections, localPlayer.CharacterAdded:Connect(setupAFD))
    else
        phase2Button6.Text = "NDS Anti Fall Damage: OFF"
        phase2Button6.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        for _, conn in ipairs(afdConnections) do conn:Disconnect() end
        afdConnections = {}
    end
end)

local noSitEnabled = false

phase3Button1.MouseButton1Click:Connect(function()
    noSitEnabled = not noSitEnabled
    local character = localPlayer.Character
    if character then
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            if noSitEnabled then
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                if hum.Sit then hum.Sit = false end
                hum.Sit = true
            else
                hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                hum.Sit = false
            end
        end
    end
    phase3Button1.Text = noSitEnabled and "Anti Sit: ON" or "Anti Sit: OFF"
    phase3Button1.BackgroundColor3 = noSitEnabled and Color3.fromRGB(80, 20, 20) or Color3.fromRGB(60, 60, 60)
end)

local antiConveyorEnabled = false
local antiConveyorConnection = nil

phase3Button2.MouseButton1Click:Connect(function()
    antiConveyorEnabled = not antiConveyorEnabled
    if antiConveyorEnabled then
        antiConveyorConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                local character = localPlayer.Character
                if not character then return end
                local rp = character:FindFirstChild("HumanoidRootPart")
                if not rp then return end
                for _, part in pairs(workspace:GetPartBoundsInRadius(rp.Position, 10)) do
                    if part:IsA("BasePart") and part ~= rp and not part:IsDescendantOf(character) then
                        part.AssemblyLinearVelocity = Vector3.zero
                        part.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
        end)
        phase3Button2.Text = "Anti Conveyor: ON"
        phase3Button2.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        if antiConveyorConnection then antiConveyorConnection:Disconnect(); antiConveyorConnection = nil end
        phase3Button2.Text = "Anti Conveyor: OFF"
        phase3Button2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

local freeCamEnabled = false
local movePart = nil
local currentPos = Vector3.new()
local joystickGui = nil
local outer, inner
local jsizeOuter, jsizeInner = 110, 50
local jradius = jsizeOuter / 2
local jcenter
local jdragging = false
local jTouch
local TweenService = game:GetService("TweenService")
local origMinZoom = 10
local origMaxZoom = 128

_G.JoystickData = {DraggingLevel = 0, Direction = Vector3.new(0,0,0)}

local function createJoystick()
    if joystickGui then joystickGui:Destroy() end
    joystickGui = Instance.new("ScreenGui")
    joystickGui.Parent = game.CoreGui
    joystickGui.Name = "JoystickFreeCam"
    outer = Instance.new("ImageLabel")
    outer.Size = UDim2.fromOffset(jsizeOuter, jsizeOuter)
    outer.Position = UDim2.new(0.1, 0, 0.75, 0)
    outer.AnchorPoint = Vector2.new(0.5, 0.5)
    outer.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outer.BackgroundTransparency = 0.3
    outer.BorderSizePixel = 0
    outer.Parent = joystickGui
    outer.Active = true
    Instance.new("UICorner", outer).CornerRadius = UDim.new(1, 0)
    inner = Instance.new("ImageLabel")
    inner.Size = UDim2.fromOffset(jsizeInner, jsizeInner)
    inner.Position = UDim2.new(0.5, -jsizeInner/2, 0.5, -jsizeInner/2)
    inner.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    inner.BorderSizePixel = 0
    inner.Parent = outer
    inner.Active = true
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)
    local function updateCenter()
        jcenter = Vector2.new(outer.AbsolutePosition.X + jradius, outer.AbsolutePosition.Y + jradius)
    end
    local function moveInner(pv2)
        local dir = pv2 - jcenter
        local dist = math.min(dir.Magnitude, jradius)
        local off = dir.Magnitude > 0 and dir.Unit * dist or Vector2.new(0,0)
        inner.Position = UDim2.new(0.5, off.X - jsizeInner/2, 0.5, off.Y - jsizeInner/2)
        _G.JoystickData.DraggingLevel = math.floor((dist / jradius) * 100)
        _G.JoystickData.Direction = Vector3.new(off.X / jradius, 0, off.Y / jradius)
    end
    outer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and not jdragging then
            updateCenter()
            jdragging = true
            jTouch = input
            moveInner(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    UserInputService.TouchMoved:Connect(function(input)
        if jdragging and jTouch and input == jTouch then
            moveInner(Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    UserInputService.TouchEnded:Connect(function(input)
        if jdragging and jTouch and input == jTouch then
            jdragging = false
            jTouch = nil
            inner.Position = UDim2.new(0.5, -jsizeInner/2, 0.5, -jsizeInner/2)
            _G.JoystickData.DraggingLevel = 0
            _G.JoystickData.Direction = Vector3.new(0,0,0)
        end
    end)
end

phase3Button3.MouseButton1Click:Connect(function()
    if freeCamEnabled then
        local camera = workspace.CurrentCamera
        camera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") or nil
        camera.CameraType = Enum.CameraType.Custom
        localPlayer.CameraMinZoomDistance = origMinZoom
        localPlayer.CameraMaxZoomDistance = origMaxZoom
        if movePart then movePart:Destroy(); movePart = nil end
        if joystickGui then joystickGui:Destroy(); joystickGui = nil end
        phase3Button3.Text = "FreeCam: OFF"
        phase3Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        freeCamEnabled = false
    else
        createJoystick()
        local camera = workspace.CurrentCamera
        origMinZoom = localPlayer.CameraMinZoomDistance
        origMaxZoom = localPlayer.CameraMaxZoomDistance
        movePart = Instance.new("Part")
        movePart.Size = Vector3.new(0, 0, 0)
        movePart.Anchored = true
        movePart.Transparency = 1
        movePart.CanCollide = false
        movePart.Parent = workspace
        movePart.CFrame = camera.CFrame
        currentPos = movePart.Position
        camera.CameraSubject = movePart
        camera.CameraType = Enum.CameraType.Custom
        localPlayer.CameraMinZoomDistance = 0
        localPlayer.CameraMaxZoomDistance = 0
        phase3Button3.Text = "FreeCam: ON"
        phase3Button3.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        freeCamEnabled = true
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not freeCamEnabled or not movePart then return end
    local dir = _G.JoystickData.Direction
    local lvl = _G.JoystickData.DraggingLevel
    if lvl > 1 then
        local camCF = workspace.CurrentCamera.CFrame
        local moveDir = (camCF.LookVector * -dir.Z) + (camCF.RightVector * dir.X)
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
            currentPos = currentPos + moveDir * (lvl * 0.02) * dt * 60
        end
    end
    local camLook = workspace.CurrentCamera.CFrame.LookVector
    local yaw = math.atan2(camLook.X, camLook.Z)
    movePart.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, yaw, 0)
end)

local invisibilityEnabled = false
local invisibleParts = {}
local invisibilityConnection = nil
local invisibilityCooldown = false

phase3Button4.MouseButton1Click:Connect(function()
    if invisibilityCooldown then return end
    invisibilityCooldown = true
    invisibilityEnabled = not invisibilityEnabled
    if invisibilityEnabled then
        phase3Button4.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        phase3Button4.Text = "Invis: ON"
        local pc = localPlayer.Character
        invisibleParts = {}
        for _, d in pairs(pc:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency == 0 then
                table.insert(invisibleParts, d)
                d.Transparency = 0.5
            end
        end
        if invisibilityConnection then invisibilityConnection:Disconnect() end
        invisibilityConnection = RunService.Heartbeat:Connect(function()
            if not invisibilityEnabled then return end
            local c = localPlayer.Character
            if not c then return end
            local h = c:FindFirstChild("Humanoid")
            local rp = c:FindFirstChild("HumanoidRootPart")
            if not h or not rp then return end
            local oc = rp.CFrame
            local oo = h.CameraOffset
            local tc = oc * CFrame.new(0, -200000, 0)
            rp.CFrame = tc
            h.CameraOffset = tc:ToObjectSpace(CFrame.new(oc.Position)).Position
            RunService.RenderStepped:Wait()
            rp.CFrame = oc
            h.CameraOffset = oo
        end)
    else
        phase3Button4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        phase3Button4.Text = "Invis: OFF"
        if invisibilityConnection then invisibilityConnection:Disconnect(); invisibilityConnection = nil end
        for _, p in ipairs(invisibleParts) do
            if p and p.Parent and p.Transparency == 0.5 then p.Transparency = 0 end
        end
        invisibleParts = {}
    end
    wait(0.1)
    invisibilityCooldown = false
end)

local antiRagdollEnabled = false
local antiRagdollDisconnectFunc = nil

local function createAntiRagdoll(character)
    local conns = {}
    local h = character:WaitForChild("Humanoid")
    h.PlatformStand = false
    table.insert(conns, h.StateChanged:Connect(function(_, ns)
        if ns == Enum.HumanoidStateType.Physics or ns == Enum.HumanoidStateType.FallingDown or ns == Enum.HumanoidStateType.Ragdoll then
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end))
    table.insert(conns, h:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if h.PlatformStand then h.PlatformStand = false end
    end))
    return function()
        for _, c in ipairs(conns) do c:Disconnect() end
    end
end

phase3Button5.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        if antiRagdollDisconnectFunc then antiRagdollDisconnectFunc() end
        if localPlayer.Character then
            local h = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
            antiRagdollDisconnectFunc = createAntiRagdoll(localPlayer.Character)
        end
        phase3Button5.Text = "Anti Ragdoll: ON"
        phase3Button5.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        if antiRagdollDisconnectFunc then antiRagdollDisconnectFunc(); antiRagdollDisconnectFunc = nil end
        phase3Button5.Text = "Anti Ragdoll: OFF"
        phase3Button5.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

phase3Button6.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://github.com/sovetskii-shashlik/Test/raw/main/PunchFling", true))()
end)

loadBtn.MouseButton1Click:Connect(function()
    isNoclipEnabled = not isNoclipEnabled
    if isNoclipEnabled then
        loadBtn.Text = "Noclip: ON"
        loadBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        if not SteppedConnection then
            SteppedConnection = RunService.Stepped:Connect(function()
                local c = localPlayer.Character
                if c then
                    for _, v in pairs(c:GetChildren()) do
                        if v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
            end)
        end
    else
        loadBtn.Text = "Noclip: OFF"
        loadBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        if SteppedConnection then
            SteppedConnection:Disconnect()
            SteppedConnection = nil
            local c = localPlayer.Character
            if c then
                for _, v in pairs(c:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = true end
                end
            end
        end
    end
end)

local antiKillPartsLoop = nil

antiKillBtn.MouseButton1Click:Connect(function()
    AntiKillPartsEnabled = not AntiKillPartsEnabled
    if AntiKillPartsEnabled then
        antiKillBtn.Text = "Anti Kill Parts: ON"
        antiKillBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        if antiKillPartsLoop then antiKillPartsLoop:Disconnect() end
        antiKillPartsLoop = RunService.Heartbeat:Connect(function()
            if not AntiKillPartsEnabled then return end
            local c = localPlayer.Character
            if not c then return end
            local rp = c:FindFirstChild("HumanoidRootPart")
            if not rp then return end
            for _, part in ipairs(workspace:GetPartBoundsInRadius(rp.Position, 10)) do
                part.CanTouch = false
            end
        end)
    else
        antiKillBtn.Text = "Anti Kill Parts: OFF"
        antiKillBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        if antiKillPartsLoop then antiKillPartsLoop:Disconnect(); antiKillPartsLoop = nil end
    end
end)

local function setCanCollide(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = bval end
    end
end

antiFlingBtn.MouseButton1Click:Connect(function()
    AntiFlingEnabled = not AntiFlingEnabled
    if AntiFlingEnabled then
        antiFlingBtn.Text = "Anti Fling: ON"
        antiFlingBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= localPlayer and v.Character then setCanCollide(v.Character, false) end
        end
    else
        antiFlingBtn.Text = "Anti Fling: OFF"
        antiFlingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= localPlayer and v.Character then setCanCollide(v.Character, true) end
        end
    end
end)

local function fling()
    local lp = Players.LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1
    while hiddenfling do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 1e35 + Vector3.new(0, 1e35, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

touchFlingBtn.MouseButton1Click:Connect(function()
    hiddenfling = not hiddenfling
    if hiddenfling then
        touchFlingBtn.Text = "Touch Fling: ON"
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        coroutine.wrap(fling)()
    else
        touchFlingBtn.Text = "Touch Fling: OFF"
        touchFlingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

local function sortPlayersAlphabetically(players)
    table.sort(players, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return players
end

local function SkidFling(TargetPlayer, duration)
    local startTime = tick()
    local Character = localPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid, TRootPart, THead, Accessory, Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then THumanoid = TCharacter:FindFirstChildOfClass("Humanoid") end
    if THumanoid and THumanoid.RootPart then TRootPart = THumanoid.RootPart end
    if TCharacter:FindFirstChild("Head") then THead = TCharacter.Head end
    if TCharacter:FindFirstChildOfClass("Accessory") then Accessory = TCharacter:FindFirstChildOfClass("Accessory") end
    if Accessory and Accessory:FindFirstChild("Handle") then Handle = Accessory.Handle end
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end
        if THead then workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid then workspace.CurrentCamera.CameraSubject = THumanoid end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0,0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90),0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0,0,0)) task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90),0,0)) task.wait()
                    end
                else break end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or THumanoid.Sit or tick() > Time + TimeToWait
        end
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
        elseif TRootPart then SFBasePart(TRootPart)
        elseif THead then SFBasePart(THead)
        elseif Accessory and Handle then SFBasePart(Handle) end
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new() end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

local function shhhlol(TargetPlayer)
    local Character = localPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        local function mmmm(comkid, Pos, Ang)
            RootPart.CFrame = CFrame.new(comkid.Position) * Pos * Ang
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        local function wtf(comkid)
            local TimeToWait = 0.134
            local Time = tick()
            local Att1 = Instance.new("Attachment", RootPart)
            local Att2 = Instance.new("Attachment", comkid)
            repeat
                if RootPart and THumanoid then
                    if comkid.Velocity.Magnitude < 30 then
                        mmmm(comkid, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 5, CFrame.Angles(math.rad(0), 0, 0)) task.wait()
                        mmmm(comkid, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(0), 0, 0)) task.wait()
                        mmmm(comkid, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(0), 0, 0)) task.wait()
                    else
                        mmmm(comkid, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(0), 0, 0)) task.wait()
                    end
                else break end
            until comkid.Velocity.Magnitude > 1000 or comkid.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or Humanoid.Health <= 0 or tick() > Time + TimeToWait or not flingActive
            Att1:Destroy()
            Att2:Destroy()
        end
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(-9e99, 9e99, -9e99)
        BV.MaxForce = Vector3.new(-9e9, 9e9, -9e9)
        local BodyGyro = Instance.new("BodyGyro")
        BodyGyro.CFrame = CFrame.new(RootPart.Position)
        BodyGyro.D = 9e8
        BodyGyro.MaxTorque = Vector3.new(-9e9, 9e9, -9e9)
        BodyGyro.P = -9e9
        local BodyPosition = Instance.new("BodyPosition")
        BodyPosition.Position = RootPart.Position
        BodyPosition.D = 9e8
        BodyPosition.MaxForce = Vector3.new(-9e9, 9e9, -9e9)
        BodyPosition.P = -9e9
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then wtf(THead) else wtf(TRootPart) end
        elseif TRootPart then wtf(TRootPart)
        elseif THead then wtf(THead) end
        BV:Destroy()
        BodyGyro:Destroy()
        BodyPosition:Destroy()
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetDescendants()) do
                    if x:IsA("BasePart") then x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new() end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

local function yeet(targetPlayer)
    local lp = game:GetService("Players").LocalPlayer
    local character = lp.Character
    local targetCharacter = targetPlayer.Character
    if not character or not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return false end
    if character.HumanoidRootPart.Velocity.Magnitude < 50 then getgenv().OldPos = character.HumanoidRootPart.CFrame end
    local existingForce = character.HumanoidRootPart:FindFirstChild("YeetForce")
    if existingForce then existingForce:Destroy() end
    local Thrust = Instance.new('BodyThrust', character.HumanoidRootPart)
    Thrust.Force = Vector3.new(9999, 9999, 9999)
    Thrust.Name = "YeetForce"
    local previousDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0
    local startTime = tick()
    local duration = (currentInput == "all" or currentInput == "nonfriends") and 5 or math.huge
    local yeetConnection
    yeetConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") or not flingActive or tick() > startTime + duration or (humanoid and humanoid.Health <= 0) then
            yeetConnection:Disconnect()
            Thrust:Destroy()
            workspace.FallenPartsDestroyHeight = previousDestroyHeight
            if character and character.HumanoidRootPart and getgenv().OldPos then
                character.HumanoidRootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                character.Humanoid:ChangeState("GettingUp")
                for _, x in pairs(character:GetDescendants()) do
                    if x:IsA("BasePart") then x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new() end
                end
            end
            return
        end
        local targetHRP = targetCharacter.HumanoidRootPart
        local targetVelocity = targetHRP.Velocity
        local speed = targetVelocity.Magnitude
        local direction = targetVelocity.Unit
        local ping = localPlayer:GetNetworkPing()
        local offsetPosition
        if speed > 0.1 then
            offsetPosition = targetHRP.Position + (direction * speed * ping)
        else
            offsetPosition = targetHRP.Position + Vector3.new(0, 0, 0)
        end
        character.HumanoidRootPart.CFrame = CFrame.new(offsetPosition)
        Thrust.Location = targetHRP.Position
    end)
    return true
end

local function getPlayers(input)
    local players = {}
    input = string.lower(input or "")
    if input == "all" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then table.insert(players, player) end
        end
        players = sortPlayersAlphabetically(players)
    elseif input == "nonfriends" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local success, isFriend = pcall(function() return player:IsFriendsWith(localPlayer.UserId) end)
                if not (success and isFriend) then table.insert(players, player) end
            end
        end
        players = sortPlayersAlphabetically(players)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then table.insert(searchTerms, term) end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local playerName = string.lower(player.Name)
                local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
                for _, term in ipairs(searchTerms) do
                    if string.find(playerName, term) or string.find(displayName, term) then
                        table.insert(players, player)
                        break
                    end
                end
            end
        end
    end
    return players
end

local function updateStatus()
    local activeCount = 0
    for player, _ in pairs(processedPlayers) do
        if player and player.Character and player.Character.Parent ~= nil then
            activeCount = activeCount + 1
        end
    end
    statusLabel.Text = "Status: Flinging "..activeCount.." players"
end

local function addPlayerToProcessed(player)
    if not player or player == localPlayer then return end
    local matchesFilter = false
    local input = string.lower(currentInput)
    if input == "all" then
        matchesFilter = true
    elseif input == "nonfriends" then
        local success, isFriend = pcall(function() return player:IsFriendsWith(localPlayer.UserId) end)
        matchesFilter = not (success and isFriend)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then table.insert(searchTerms, term) end
        end
        local playerName = string.lower(player.Name)
        local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
        for _, term in ipairs(searchTerms) do
            if string.find(playerName, term) or string.find(displayName, term) then
                matchesFilter = true
                break
            end
        end
    end
    if matchesFilter then
        processedPlayers[player] = true
        updateStatus()
    end
end

local function flingPlayers()
    local players = {}
    for player, _ in pairs(processedPlayers) do
        if player and player.Character and player.Character.Parent ~= nil then
            table.insert(players, player)
        end
    end
    if currentInput == "all" or currentInput == "nonfriends" then
        players = sortPlayersAlphabetically(players)
    end
    for _, player in ipairs(players) do
        if not flingActive then break end
        if player and player.Character and player.Character.Parent ~= nil then
            statusLabel.Text = "Status: Flinging "..player.Name
            local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
            if flingMode == 1 then
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
                if currentInput == "all" or currentInput == "nonfriends" then
                    task.wait(1.5)
                end
            end
        end
    end
    if flingActive then
        updateStatus()
        task.wait()
        flingPlayers()
    end
end

local function toggleFlingMode()
    flingMode = flingMode == 1 and 2 or flingMode == 2 and 3 or 1
    toggleBtnMode.Text = tostring(flingMode)
end

local function toggleFling()
    flingActive = not flingActive
    if flingActive then
        currentInput = string.lower(inputBox.Text)
        local players = getPlayers(currentInput)
        if #players == 0 then
            statusLabel.Text = "Status: No players found!"
            flingActive = false
            return
        end
        processedPlayers = {}
        for _, player in ipairs(players) do
            addPlayerToProcessed(player)
        end
        toggleBtnMain.Text = "Fling Players: ON"
        toggleBtnMain.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        coroutine.wrap(flingPlayers)()
    else
        toggleBtnMain.Text = "Fling Players: OFF"
        toggleBtnMain.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        statusLabel.Text = "Status: Stopped"
        processedPlayers = {}
    end
end

toggleBtnMode.MouseButton1Click:Connect(toggleFlingMode)
toggleBtnMain.MouseButton1Click:Connect(toggleFling)

Players.PlayerAdded:Connect(function(player)
    if flingActive then
        addPlayerToProcessed(player)
        if player.Character then
            if flingMode == 1 then
                local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
            end
        else
            player.CharacterAdded:Connect(function()
                if flingActive then
                    addPlayerToProcessed(player)
                    if flingMode == 1 then
                        local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                        SkidFling(player, duration)
                    elseif flingMode == 2 then
                        shhhlol(player)
                    elseif flingMode == 3 then
                        yeet(player)
                    end
                end
            end)
        end
    end
end)

localPlayer.CharacterAdded:Connect(function()
    if flingActive then
        task.wait(1)
        coroutine.wrap(flingPlayers)()
    end
end)

local function updateSpeed()
    while true do
        task.wait()
        local character = localPlayer.Character
        if character then
            local rp = character:FindFirstChild("HumanoidRootPart")
            if rp then
                local speed = math.floor(rp.Velocity.Magnitude)
                speedLabel.Text = "Speed: "..tostring(speed).." studs/s"
                if speed > 1e38 then
                    speedLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                elseif speed > 100000 then
                    speedLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    speedLabel.TextColor3 = Color3.new(1, 1, 1)
                end
            else
                speedLabel.Text = "Speed: N/A"
            end
        else
            speedLabel.Text = "Speed: N/A"
        end
    end
end

coroutine.wrap(updateSpeed)()

local userId = 8407673016
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Fling GUI",
    Text = "version V35.0",
    Icon = content,
    Duration = 7
})

-- Anti Kick
if hookmetamethod then
    pcall(function()
        local LocalPlayer = game:GetService("Players").LocalPlayer
        local oldhmmi
        local oldhmmnc
        oldhmmi = hookmetamethod(game, "__index", function(self, method)
            if self == LocalPlayer and method:lower() == "kick" then
                return error("Expected ':' not '.' calling member function Kick", 2)
            end
            return oldhmmi(self, method)
        end)
        oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
            if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
                return nil
            end
            return oldhmmnc(self, ...)
        end)
    end)
end

-- Anti Tornado
local antiTornadoEnabled = false
local antiTornadoConnection = nil

phase4Button3.MouseButton1Click:Connect(function()
    antiTornadoEnabled = not antiTornadoEnabled
    if antiTornadoEnabled then
        antiTornadoConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                local character = localPlayer.Character
                if not character then return end
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") or child:IsA("BodyAngularVelocity") or child:IsA("VectorForce") or child:IsA("LineForce") or child:IsA("Torque") or child:IsA("RocketPropulsion") or child:IsA("AlignPosition") or child:IsA("AlignOrientation") then
                        child:Destroy()
                    end
                end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local parts = workspace:GetPartBoundsInRadius(rootPart.Position, 30)
                    for _, part in ipairs(parts) do
                        if part:IsA("BasePart") and not part:IsDescendantOf(character) then
                            for _, child in ipairs(part:GetChildren()) do
                                if child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyPosition") or child:IsA("BodyAngularVelocity") or child:IsA("VectorForce") or child:IsA("LineForce") or child:IsA("Torque") or child:IsA("RocketPropulsion") or child:IsA("AlignPosition") or child:IsA("AlignOrientation") then
                                    child:Destroy()
                                end
                            end
                        end
                    end
                end
            end)
        end)
        phase4Button3.Text = "Anti Tornado (test): ON"
        phase4Button3.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    else
        if antiTornadoConnection then antiTornadoConnection:Disconnect(); antiTornadoConnection = nil end
        phase4Button3.Text = "Anti Tornado (test): OFF"
        phase4Button3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

local camera = workspace.CurrentCamera
local function removeBlur()
    local blur = camera:FindFirstChild("Blur")
    if blur and blur:IsA("BlurEffect") then blur:Destroy() end
end
removeBlur()
camera.DescendantAdded:Connect(function(d)
    if d.Name == "Blur" and d:IsA("BlurEffect") then
        task.wait()
        d:Destroy()
    end
end)

toggleMinimize()
toggleMinimize()

print("[Fling GUI] Loaded successfully")
