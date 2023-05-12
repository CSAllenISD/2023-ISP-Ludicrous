local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.BigBoi

local Gun = require(script.Parent)

local BigBoi = {}
BigBoi.__index = BigBoi
setmetatable(BigBoi, Gun)

function BigBoi.new(owner: Player, ignore: {Instance})
	local newBigBoi: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newBigBoi.Firerate = 70
	newBigBoi.Firemode = "Auto" -- "Semi", "Auto"

	newBigBoi.Ammo = 10
	newBigBoi.MagSize = 10
	newBigBoi.Reserve = math.huge

	newBigBoi.ReloadTime = 3

	newBigBoi.VerticalRecoil = Vector2.new(150,200)
	newBigBoi.HorizontalRecoil = Vector2.new(-70,70)
	
	newBigBoi.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newBigBoi.ProjectileArg = {
		Damage = 25
	}
	
	newBigBoi.OnShot.Event:Connect(function()
		newBigBoi.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		--newBigBoi.ViewModel:PlayAnimation(AnimationRepo.BigBoi_Shoot, nil, nil, 5)
		--newBigBoi.ViewModel:PlaySound("Fire")
	end)
	
	newBigBoi.OnReload.Event:Connect(function()
		--newBigBoi.ViewModel:PlaySound("Reload")
	end)

	return newBigBoi
end

return BigBoi
