local RepStor = game:GetService("ReplicatedStorage")
local AnimationRepo = RepStor.Assets.Animations.Tools.FlameThrower

local Gun = require(script.Parent)

local FlameThrower = {}
FlameThrower.__index = FlameThrower
setmetatable(FlameThrower, Gun)

function FlameThrower.new(owner: Player, ignore: {Instance})
	local newFlameThrower: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newFlameThrower.Firerate = 1000
	newFlameThrower.Firemode = "Auto" -- "Semi", "Auto"

	newFlameThrower.Ammo = 50
	newFlameThrower.MagSize = 50
	newFlameThrower.Reserve = math.huge
	newFlameThrower.ShotCount = 1	
	newFlameThrower.ReloadTime = 2.5

	newFlameThrower.VerticalSpread = Vector2.new(-5,5)
	newFlameThrower.HorizontalSpread = Vector2.new(-5,5)
	
	newFlameThrower.Projectile = RepStor.Modules.ProjectileModules.Projectiles.HellFlame
	
	newFlameThrower.OnShot.Event:Connect(function()
	--	newFlameThrower.ViewModel:PlayAnimation(AnimationRepo.FlameThrower_Shot, nil, nil, 5)
		--newFlameThrower.ViewModel:PlaySound("Fire")
	end)
	
	newFlameThrower.StartShooting.Event:Connect(function()
		newFlameThrower.ViewModel.Model.PrimaryPart.Start:Play()
	end)
	
	newFlameThrower.EndShooting.Event:Connect(function()
		newFlameThrower.ViewModel.Model.PrimaryPart.Start:Stop()
		newFlameThrower.ViewModel.Model.PrimaryPart.End:Play()
	end)
	
	newFlameThrower.OnReload.Event:Connect(function()
		newFlameThrower.ViewModel.Model.PrimaryPart.Start:Stop()
		newFlameThrower.ViewModel.Model.PrimaryPart.End:Stop()
		--newFlameThrower.ViewModel:PlaySound("Reload")
	end)

	return newFlameThrower
end

return FlameThrower
