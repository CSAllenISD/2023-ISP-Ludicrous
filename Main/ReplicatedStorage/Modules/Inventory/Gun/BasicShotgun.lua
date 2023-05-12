local RepStor = game:GetService("ReplicatedStorage")
local AnimationRepo = RepStor.Assets.Animations.Tools.BasicShotgun

local Gun = require(script.Parent)

local BasicShotgun = {}
BasicShotgun.__index = BasicShotgun
setmetatable(BasicShotgun, Gun)

function BasicShotgun.new(owner: Player, ignore: {Instance})
	local newBasicShotgun: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newBasicShotgun.Firerate = 150
	newBasicShotgun.Firemode = "Semi" -- "Semi", "Auto"

	newBasicShotgun.Ammo = 4
	newBasicShotgun.MagSize = 4
	newBasicShotgun.ShotCount = 12
	newBasicShotgun.Reserve = math.huge

	newBasicShotgun.ReloadTime = 1.771 * (1 / .65)

	newBasicShotgun.VerticalSpread = Vector2.new(-4.5,4.5)
	newBasicShotgun.HorizontalSpread = Vector2.new(-4.5,4.5)
	
	newBasicShotgun.VerticalRecoil = Vector2.new(130,155)
	newBasicShotgun.HorizontalRecoil = Vector2.new(-100,100)
	
	newBasicShotgun.Projectile = RepStor.Modules.ProjectileModules.Projectiles.ShotgunPellet  

	newBasicShotgun.OnShot.Event:Connect(function()
		newBasicShotgun.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		newBasicShotgun.ViewModel:PlayAnimation(AnimationRepo.BasicShotgun_Shoot, nil, nil, 2)
		newBasicShotgun.ViewModel:PlaySound("Shot")
		task.wait(.3)
		newBasicShotgun.ViewModel:PlaySound("Pump")
	end)
	
	newBasicShotgun.OnReload.Event:Connect(function()
		newBasicShotgun.ViewModel:PlaySound("Reload")
	end)

	return newBasicShotgun
end

return BasicShotgun
