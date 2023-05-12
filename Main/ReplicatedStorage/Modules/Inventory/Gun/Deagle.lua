local RepStor = game:GetService("ReplicatedStorage")
local AnimationRepo = RepStor.Assets.Animations.Tools.BasicPistol

local Gun = require(script.Parent)

local Pistol = {}
Pistol.__index = Pistol
setmetatable(Pistol, Gun)

function Pistol.new(owner: Player, ignore: {Instance})
	local newPistol: Gun.Gun = Gun.new(script.Name, owner, ignore, "Pistol", nil, true)
	
	newPistol.Firerate = 267
	newPistol.Firemode = "Semi" -- "Semi", "Auto"

	newPistol.Ammo = 7
	newPistol.MagSize = 7
	newPistol.Reserve = math.huge

	newPistol.ReloadTime = 1.63
	
	newPistol.ShotCount = 1
	
	newPistol.VerticalRecoil = Vector2.new(-95,100)
	newPistol.HorizontalRecoil = Vector2.new(-50,50)
	
	newPistol.HorizontalSpread = Vector2.new(0,0)
	newPistol.VerticalSpread = Vector2.new(0,0)
	
	newPistol.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newPistol.ProjectileArg = {
		Damage = 7
	}
	
	newPistol.OnShot.Event:Connect(function()
		newPistol.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		newPistol.ViewModel:PlayAnimation(AnimationRepo.BasicPistol_Shoot, nil, nil, 5)
		newPistol.ViewModel:PlaySound("Fire")
	end)
	
	newPistol.OnReload.Event:Connect(function()
		newPistol.ViewModel:PlaySound("Reload")
	end)
	
	return newPistol
end

return Pistol
