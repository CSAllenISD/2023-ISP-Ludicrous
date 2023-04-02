local HttpSer = game:GetService("HttpService")

export type Tool = {
	OnEquip: BindableEvent,
	OnUnEquip: BindableEvent,
	OnRemove: BindableEvent,
	
	UUID: string,
	Owner: Player,
	
	Equipped: boolean,
	Enabled: boolean,
	
	Equip: (self) -> (),
	UnEquip: (self) -> (),
	Remove: (self) -> ()
}

local Tool = {}
Tool.__index = Tool

Tool.Tools = {}

function Tool:GetToolFromUUID(UUID: string)
	if typeof(UUID) ~= "string" then warn("ToolUUID is not a string") return end
	
	local tool: Tool = self.Tools[UUID]
	if not tool then warn("Unable to fetch Tool with UUID", UUID) return end
	return tool
end

function Tool.new(owner: Player)
	if typeof(owner) ~= "Instance" or not owner:IsA("Player") then error("ToolOwner is not a Player") end
	
	local newTool = {}
	setmetatable(newTool, Tool)
	newTool.UUID = HttpSer:GenerateGUID(false) .."-".. HttpSer:GenerateGUID(false) .."-".. HttpSer:GenerateGUID(false)
	Tool.Tools[newTool.UUID] = newTool
	newTool.Owner = owner
	
	newTool.OnEquip = Instance.new("BindableEvent")
	newTool.OnUnEquip = Instance.new("BindableEvent")
	newTool.OnRemove = Instance.new("BindableEvent")
	
	newTool.Equipped = false
	newTool.Enabled = true
	return newTool
end

function Tool:Equip()
	if self.Enabled then
		self.Equipped = true
		self.OnEquip:Fire()
	end
end

function Tool:UnEquip()
	if self.Enabled then
		self.Equipped = false
		self.OnUnEquip:Fire()
	end
end

function Tool:Remove()
	self.OnRemove:Fire()
	self.OnRemove:Destroy()
	self.OnRemove = nil
	
	Tool.Tools[self.UUID] = nil
	
	self.UUID = nil
	self.Owner = nil
	
	self.OnEquip:Destroy()
	self.OnEquip = nil
	self.OnUnEquip:Destroy()
	self.OnUnEquip = nil

	self.Equipped = true
	self.Enable = nil
	setmetatable(self, nil)
end

return Tool
