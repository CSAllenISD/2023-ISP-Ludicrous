local RepStor = game:GetService("ReplicatedStorage")
local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")


local BossBar = require(ServerStor.Modules.BossBar)

local UpdateTimeEvent = RepStor.Events.PlayerEvents.UpdateTime

local badgeService = game:GetService("BadgeService")

local loop = 1
while true do
	for time = 30, 0, -.1 do
		task.wait(.1)
		UpdateTimeEvent:FireAllClients(time)
	end

	for _ = 1, loop do
		local Dummy = require(ServerStor.Modules.Enemies.Hell)
		local newDummy = Dummy.new(script.Parent.CFrame + Vector3.new(0,15,0))
		BossBar.new(newDummy)
	end

	repeat
		wait()
	until not next(workspace.Entities.EnemyEntities:GetChildren())

	for time = 10, 0, -.1 do
		task.wait(.1)
		UpdateTimeEvent:FireAllClients(time)
	end

	task.wait(.1)

	for _ = 1, loop do
		local Dummy = require(ServerStor.Modules.Enemies.BroodMother)
		local newDummy = Dummy.new(script.Parent.CFrame + Vector3.new(0,15,0))
		BossBar.new(newDummy)
	end
	repeat
		wait()
	until not next(workspace.Entities.EnemyEntities:GetChildren())

	for time = 10, 0, -.1 do
		task.wait(.1)
		UpdateTimeEvent:FireAllClients(time)
	end

	for _ = 1, loop do
		local Dummy = require(ServerStor.Modules.Enemies.Capybara)
		local newDummy = Dummy.new(script.Parent.CFrame + Vector3.new(0,15,0))
		BossBar.new(newDummy)
	end

	repeat
		wait()
	until not next(workspace.Entities.EnemyEntities:GetChildren())

	for time = 10, 0, -.1 do
		task.wait(.1)
		UpdateTimeEvent:FireAllClients(time)
	end

	for _ = 1, loop do
		local Dummy = require(ServerStor.Modules.Enemies.God)
		local newDummy = Dummy.new(script.Parent.CFrame + Vector3.new(0,15,0))
		BossBar.new(newDummy)
	end
	
	repeat
		wait()
	until not next(workspace.Entities.EnemyEntities:GetChildren())
	
	pcall(function()
		if loop == 1 then
			for _, player: Player in game:GetService("Players"):GetPlayers() do
				badgeService:AwardBadge(player.UserId, 2145216261)
			end
		elseif loop == 3 then
			for _, player: Player in game:GetService("Players"):GetPlayers() do
				badgeService:AwardBadge(player.UserId, 2145216297)
			end
		elseif loop == 10 then
			for _, player: Player in game:GetService("Players"):GetPlayers() do
				badgeService:AwardBadge(player.UserId, 2145216330)
			end
		end
		
	end)
end

