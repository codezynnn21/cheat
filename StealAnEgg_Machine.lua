-- Steal An Egg | Auto Steal + Auto Level + No Dead | Multi-executor | GUI
-- Author: zynn
-- Insert = toggle menu | RightShift = start/stop

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local running = false
local baseCFrame = nil
local tweenSpeed = 90
local noclip = true
local autoLevel = true

local function safeFirePrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return false end
	local oldHold = prompt.HoldDuration
	prompt.HoldDuration = 0
	if fireproximityprompt then
		fireproximityprompt(prompt)
	else
		pcall(function()
			prompt:InputHoldBegin()
			task.wait(0.05)
			prompt:InputHoldEnd()
		end)
	end
	prompt.HoldDuration = oldHold
	return true
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "zynn_StealGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 260)
Frame.Position = UDim2.new(0.02, 0, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "zynn · steal + level"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 20)
Status.Position = UDim2.new(0, 8, 0, 36)
Status.BackgroundTransparency = 1
Status.Text = "idle — set base"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -16, 0, 32)
ToggleBtn.Position = UDim2.new(0, 8, 0, 60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = "START"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = Frame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local BaseBtn = Instance.new("TextButton")
BaseBtn.Size = UDim2.new(1, -16, 0, 28)
BaseBtn.Position = UDim2.new(0, 8, 0, 98)
BaseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BaseBtn.Text = "SET BASE"
BaseBtn.TextColor3 = Color3.new(1, 1, 1)
BaseBtn.Font = Enum.Font.Gotham
BaseBtn.TextSize = 12
BaseBtn.Parent = Frame
Instance.new("UICorner", BaseBtn).CornerRadius = UDim.new(0, 6)

local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Size = UDim2.new(1, -16, 0, 26)
NoclipBtn.Position = UDim2.new(0, 8, 0, 132)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
NoclipBtn.Text = "NOCLIP: ON"
NoclipBtn.TextColor3 = Color3.new(1, 1, 1)
NoclipBtn.Font = Enum.Font.Gotham
NoclipBtn.TextSize = 12
NoclipBtn.Parent = Frame
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 6)

local LevelBtn = Instance.new("TextButton")
LevelBtn.Size = UDim2.new(1, -16, 0, 26)
LevelBtn.Position = UDim2.new(0, 8, 0, 164)
LevelBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
LevelBtn.Text = "AUTO LEVEL: ON"
LevelBtn.TextColor3 = Color3.new(1, 1, 1)
LevelBtn.Font = Enum.Font.Gotham
LevelBtn.TextSize = 12
LevelBtn.Parent = Frame
Instance.new("UICorner", LevelBtn).CornerRadius = UDim.new(0, 6)

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(1, -16, 0, 24)
SpeedBox.Position = UDim2.new(0, 8, 0, 196)
SpeedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SpeedBox.Text = "90"
SpeedBox.TextColor3 = Color3.new(1, 1, 1)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 12
SpeedBox.PlaceholderText = "speed"
SpeedBox.Parent = Frame
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 4)

local function getRoot()
	local char = lp.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local char = lp.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isEggPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return false end
	local txt = ((prompt.ActionText or "") .. (prompt.ObjectText or "") .. (prompt.Parent and prompt.Parent.Name or "")):lower()
	return txt:find("egg") or txt:find("machine") or txt:find("fuse") or txt:find("incubator") or txt:find("rift") or txt:find("steal")
end

local function isLevelPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return false end
	local txt = ((prompt.ActionText or "") .. (prompt.ObjectText or "") .. (prompt.Parent and prompt.Parent.Name or "")):lower()
	return txt:find("rebirth") or txt:find("level") or txt:find("upgrade") or txt:find("prestige") or txt:find("rank")
end

local function findClosest(promptCheck)
	local root = getRoot()
	if not root then return nil end
	local closest, dist = nil, math.huge
	for _, v in ipairs(workspace:GetDescendants()) do
		if promptCheck(v) and v.Enabled then
			local pos
			local p = v.Parent
			if p:IsA("BasePart") then pos = p.Position
			elseif p:IsA("Model") then pos = p:GetPivot().Position end
			if pos then
				local d = (pos - root.Position).Magnitude
				if d < dist and d > 3 then
					dist = d
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
	local t = math.clamp(dist / tweenSpeed, 0.2, 4)
	local tween = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))})
	tween:Play()
	tween.Completed:Wait()
	if hum then hum.WalkSpeed = 16 end
end

local function goBase()
	if baseCFrame then
		tweenTo(baseCFrame.Position)
	end
end

-- no dead
task.spawn(function()
	while true do
		local hum = getHum()
		if hum then
			hum.Health = hum.MaxHealth
			if noclip then
				for _, part in ipairs(lp.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
		task.wait(0.15)
	end
end)

local function mainLoop()
	while running do
		local root = getRoot()
		if not root then
			Status.Text = "respawning..."
			task.wait(1)
			continue
		end

		-- auto level first
		if autoLevel then
			local lvl = findClosest(isLevelPrompt)
			if lvl then
				Status.Text = "leveling..."
				local pos
				local p = lvl.Parent
				if p:IsA("BasePart") then pos = p.Position elseif p:IsA("Model") then pos = p:GetPivot().Position end
				if pos then
					tweenTo(pos)
					task.wait(0.2)
					safeFirePrompt(lvl)
					task.wait(0.4)
				end
			end
		end

		-- steal egg
		local egg = findClosest(isEggPrompt)
		if egg then
			Status.Text = "stealing egg..."
			local pos
			local p = egg.Parent
			if p:IsA("BasePart") then pos = p.Position elseif p:IsA("Model") then pos = p:GetPivot().Position end
			if pos then
				tweenTo(pos)
				task.wait(0.15)
				safeFirePrompt(egg)
				task.wait(0.5)
				goBase()
				task.wait(0.6)
			end
		else
			Status.Text = "scanning..."
			task.wait(1.2)
		end
		task.wait(0.3)
	end
	Status.Text = "stopped"
end

ToggleBtn.MouseButton1Click:Connect(function()
	running = not running
	ToggleBtn.Text = running and "STOP" or "START"
	ToggleBtn.BackgroundColor3 = running and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 50, 50)
	if running then task.spawn(mainLoop) end
end)

BaseBtn.MouseButton1Click:Connect(function()
	local root = getRoot()
	if root then
		baseCFrame = root.CFrame
		Status.Text = "base set"
	end
end)

NoclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	NoclipBtn.Text = noclip and "NOCLIP: ON" or "NOCLIP: OFF"
	NoclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(40, 60, 40) or Color3.fromRGB(50, 40, 40)
end)

LevelBtn.MouseButton1Click:Connect(function()
	autoLevel = not autoLevel
	LevelBtn.Text = autoLevel and "AUTO LEVEL: ON" or "AUTO LEVEL: OFF"
	LevelBtn.BackgroundColor3 = autoLevel and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(40, 40, 40)
end)

SpeedBox.FocusLost:Connect(function()
	local n = tonumber(SpeedBox.Text)
	if n and n > 10 and n < 500 then
		tweenSpeed = n
	else
		SpeedBox.Text = tostring(tweenSpeed)
	end
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
		task.wait(40)
		local hum = getHum()
		if hum then hum.Jump = true end
	end
end)

print("zynn steal + level + no dead loaded")
