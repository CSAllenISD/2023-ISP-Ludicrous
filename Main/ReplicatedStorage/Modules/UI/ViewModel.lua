local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Spring = require(RepStor.Modules.Utility.Spring)

local ViewModel = {}
ViewModel.__index = ViewModel

export type ViewModel = {
	Model: Model,
	AnimationController: AnimationController,
	SoundDirectory: Folder,
	
	Enabled: boolean,
	TickLoop: RBXScriptConnection,
	
	Offset: CFrameValue,
	SpringSpeedFactor: number,
	
	Tick: (self, dt: number) -> (),
	Shove: (self, x: number, y: number) -> (),
	Fling: (self, x: number, y: number) -> (),
	PlayAnimation: (self, Animation: Animation, fadeTime: number?, weight: number?, speed: number?) -> (),
	PlaySound: (self, name: string) -> (),
	StopSound: (self, name: string) -> (),
	Enable: (self) -> (),
	Disable: (self) -> (),
	Remove: (self) -> ()
}

function ViewModel.new(model: Model)
	if not RunSer:IsClient() then error("ViewModel should be handled in Client") end
	if typeof(model) ~= "Instance" or not model:IsA("Model") then error("ViewModelModel is not a Model") end
	
	local newViewModel = {}
	setmetatable(newViewModel, ViewModel)
	
	local Camera = workspace.Camera
	
	newViewModel.Model = model
	newViewModel.Model.Parent = Camera
	newViewModel.AnimationController = model:FindFirstChildOfClass("AnimationController")
	newViewModel.SoundDirectory = model.PrimaryPart.Sounds
	if typeof(newViewModel.SoundDirectory) ~= "Instance" or not newViewModel.SoundDirectory:IsA("Folder") then error("SoundDirectory is not a Folder") end
	
	newViewModel.Offset = Instance.new("CFrameValue")
	
	newViewModel.Enabled = true
	newViewModel.TickLoop = RunSer.RenderStepped:Connect(function(dt: number)
		if not newViewModel.Enabled then return end
		newViewModel:Tick(dt)
	end)

	return newViewModel
end

function ViewModel:Tick(dt: number)
	local Model: Model = self.Model
	self.Model.PrimaryPart:PivotTo(workspace.Camera.CFrame * self.Offset.Value)
end

function ViewModel:PlayAnimation(animation: Animation, fadeTime: number?, weight:number?, speed: number?)
	if typeof(animation) ~= "Instance" or not animation:IsA("Animation") then warn("ViewModelAnimation is not an AnimationTrack") return end
	if fadeTime and typeof(fadeTime) ~= "number" then warn("AnimationFadeTime is not a number") return end
	if weight and typeof(weight) ~= "number" then warn("AnimationWeight is not a number") return end
	if speed and typeof(speed) ~= "number" then warn("AnimationSpeed is not a number") return end

	local AnimationTrack: AnimationTrack = self.AnimationController:LoadAnimation(animation)
	AnimationTrack:Play(fadeTime, weight, speed)
end

function ViewModel:PlaySound(name: string)
	if typeof(name) ~= "string" then warn("SoundName is not a string") return end
	local Sound: Sound = self.SoundDirectory:FindFirstChild(name)
	Sound:Play()
end

function ViewModel:StopSound(name: string)
	if typeof(name) ~= "string" then warn("SoundName is not a string") return end
	local Sound: Sound = self.SoundDirectory:FindFirstChild(name)
	Sound:Stop()
end

function ViewModel:Enable()
	self.Enabled = true
	self.Model.PrimaryPart:PivotTo(workspace.Camera.CFrame)
end

function ViewModel:Disable()
	self.Enabled = false
	self.Model:PivotTo(CFrame.new(math.huge,math.huge,math.huge))
end

function ViewModel:Remove()
	self.OrientationSpringX:Remove()
	self.OrientationSpringX = nil
	self.OrientationSpringY:Remove()
	self.OrientationSpringY = nil
	
	self.Offset:Destroy()
	self.Offset = nil
	
	self.Model:Destroy()
	self.Model = nil
	self.AnimationController = nil
	self.SoundDirectory = nil
	self.Enabled = nil
	self.TickLoop:Disconnect()
	self.TickLoop = nil
	
	setmetatable(self, nil)
end

return ViewModel
