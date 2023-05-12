local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.Bren

local Gun = require(script.Parent)

local Bren = {}
Bren.__index = Bren
setmetatable(Bren, Gun)

function Bren.new(owner: Player, ignore: {Instance})
	local newBren: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newBren.Firerate = 500
	newBren.Firemode = "Auto" -- "Semi", "Auto"

	newBren.Ammo = 30
	newBren.MagSize = 30
	newBren.Reserve = math.huge

	newBren.ReloadTime = 2

	newBren.VerticalRecoil = Vector2.new(-15,15)
	newBren.HorizontalRecoil = Vector2.new(-10,10)
	
	newBren.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newBren.ProjectileArg = {
		Damage = 5
	}
	
	newBren.OnShot.Event:Connect(function()
		newBren.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
	--	newBren.ViewModel:PlayAnimation(AnimationRepo.Bren_Shoot, nil, nil, 5)
	--	newBren.ViewModel:PlaySound("Fire")
	end)
	
	newBren.OnReload.Event:Connect(function()
	--	newBren.ViewModel:PlaySound("Reload")
	end)

	return newBren
end

return Bren
