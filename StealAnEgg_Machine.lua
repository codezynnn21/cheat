-- Steal An Egg | Auto Steal Egg Machine | Multi-executor | GUI
-- Author: zynn
-- Works on Delta, Solara, Xeno, Fluxus, Wave, Potassium, Volt, etc.
-- Insert = toggle menu | RightShift = start/stop

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local running = false
local baseCFrame = nil
local tweenSpeed = 90

-- executor-safe prompt fire
local function safeFirePrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
	local oldHold = prompt.HoldDuration
	prompt.HoldDuration = 0
	if fireproximityprompt then
		fireproximityprompt(prompt)
	else
		-- fallback for executors that expose it differently
		local ok = pcall(function()
			prompt:InputHoldBegin()
			task.wait(0.05)
			prompt:InputHoldEnd()
		end)
		if not ok then
			-- last resort
			pcall(function()
				game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
				task.wait(0.1)
				game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
			end)
		end
	end
	prompt.HoldDuration = oldHold
	return true
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "zynn_StealGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 240)
Frame.Position = UDim2.new(0.02, 0, 0.22, 0)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Frame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 55, 60)
MainStroke.Thickness = 1.2
MainStroke.Parent = Frame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 22)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12))
})
Gradient.Rotation = 90
Gradient.Parent = Frame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "zynn  ·  machine steal"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -32, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 22)
Status.Position = UDim2.new(0, 10, 0, 44)
Status.BackgroundTransparency = 1
Status.Text = "idle  ·  set base first"
Status.TextColor3 = Color3.fromRGB(140, 140, 150)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 34)
ToggleBtn.Position = UDim2.new(0, 10, 0, 72)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
ToggleBtn.Text = "START"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = Frame
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

local BaseBtn = Instance.new("TextButton")
BaseBtn.Size = UDim2.new(1, -20, 0, 30)
BaseBtn.Position = UDim2.new(0, 10, 0, 114)
BaseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
BaseBtn.Text = "SET BASE"
BaseBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
BaseBtn.Font = Enum.Font.Gotham
BaseBtn.TextSize = 13
BaseBtn.Parent = Frame
local BaseCorner = Instance.new("UICorner")
BaseCorner.CornerRadius = UDim.new(0, 8)
BaseCorner.Parent = BaseBtn

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -20, 0, 16)
SpeedLabel.Position = UDim2.new(0, 10, 0, 152)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "speed  ·  90"
SpeedLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 11
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = Frame

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(1, -20, 0, 26)
SpeedBox.Position = UDim2.new(0, 10, 0, 172)
SpeedBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
SpeedBox.Text = "90"
SpeedBox.TextColor3 = Color3.new(1, 1, 1)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 13
SpeedBox.PlaceholderText = "studs / s"
SpeedBox.Parent = Frame
local SpeedCorner = Instance.new("UICorner")
SpeedCorner.CornerRadius = UDim.new(0, 6)
SpeedCorner.Parent = SpeedBox

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 18)
Info.Position = UDim2.new(0, 10, 0, 206)
Info.BackgroundTransparency = 1
Info.Text = "fuse · incubator · rift · machine"
Info.TextColor3 = Color3.fromRGB(100, 100, 110)
Info.Font = Enum.Font.Gotham
Info.TextSize = 10
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = Frame

local function getRoot()
	local char = lp.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local char = lp.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isMachineEggPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return false end
	local parentName = prompt.Parent and prompt.Parent.Name:lower() or ""
	local name = prompt.Name:lower()
	local action = (prompt.ActionText or ""):lower()
	local object = (prompt.ObjectText or ""):lower()
	local words = {"machine", "fuse", "incubator", "rift", "dispenser", "eggmachine", "sakura", "hungry", "monster"}
	for _, w in ipairs(words) do
		if parentName:find(w) or name:find(w) or action:find(w) or object:find(w) then
			return true
		end
	end
	return action:find("egg") or object:find("egg")
end

local function findMachineEgg()
	local root = getRoot()
	if not root then return nil end
	local closest, closestDist = nil, math.huge
	for _, v in ipairs(workspace:GetDescendants()) do
		if isMachineEggPrompt(v) and v.Enabled then
			local pos
			local p = v.Parent
			if p:IsA("BasePart") then
				pos = p.Position
			elseif p:IsA("Model") then
				pos = p:GetPivot().Position
			end
			if pos then
				local dist = (pos - root.Position).Magnitude
				if dist < closestDist and dist > 4 then
					closestDist = dist
					closest = v
				end
			end
		end
	end
	return closest
end

local function tweenTo(targetPos)
	local root = getRoot()
	if not root or not targetPos then return end
	local hum = getHum()
	if hum then hum.WalkSpeed = tweenSpeed end
	local dist = (root.Position - targetPos).Magnitude
	local t = math.clamp(dist / tweenSpeed, 0.25, 3)
	local tween = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos + Vector3.new(0, 2.5, 0))})
	tween:Play()
	tween.Completed:Wait()
	if hum then hum.WalkSpeed = 16 end
end

local function goBase()
	if not baseCFrame then
		local root = getRoot()
		if root then baseCFrame = root.CFrame end
		return
	end
	tweenTo(baseCFrame.Position)
end

local function machineLoop()
	while running do
		local root = getRoot()
		if not root then
			Status.Text = "waiting for character"
			task.wait(1)
			continue
		end
		local prompt = findMachineEgg()
		if prompt then
			Status.Text = "stealing..."
			local pos
			local p = prompt.Parent
			if p:IsA("BasePart") then pos = p.Position
			elseif p:IsA("Model") then pos = p:GetPivot().Position end
			if pos then
				tweenTo(pos)
				task.wait(0.18)
				safeFirePrompt(prompt)
				task.wait(0.45)
				goBase()
				task.wait(0.65)
			end
		else
			Status.Text = "scanning..."
			task.wait(1.4)
		end
		task.wait(0.35)
	end
	Status.Text = "stopped"
end

ToggleBtn.MouseButton1Click:Connect(function()
	running = not running
	ToggleBtn.Text = running and "STOP" or "START"
	ToggleBtn.BackgroundColor3 = running and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(45, 45, 52)
	if running then task.spawn(machineLoop) end
end)

BaseBtn.MouseButton1Click:Connect(function()
	local root = getRoot()
	if root then
		baseCFrame = root.CFrame
		Status.Text = "base locked"
	end
end)

SpeedBox.FocusLost:Connect(function()
	local n = tonumber(SpeedBox.Text)
	if n and n > 15 and n < 400 then
		tweenSpeed = n
		SpeedLabel.Text = "speed  ·  " .. n
	else
		SpeedBox.Text = tostring(tweenSpeed)
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	Frame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Insert then
		Frame.Visible = not Frame.Visible
	elseif input.KeyCode == Enum.KeyCode.RightShift then
		ToggleBtn.MouseButton1Click:Fire()
	end
end)

task.spawn(function()
	while true do
		task.wait(50)
		local hum = getHum()
		if hum then hum.Jump = true end
	end
end)

print("zynn machine steal loaded (multi-executor)")
