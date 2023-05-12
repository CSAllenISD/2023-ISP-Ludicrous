local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.BasicRevolver

local Gun = require(script.Parent)

local Revolver = {}
Revolver.__index = Revolver
setmetatable(Revolver, Gun)

function Revolver.new(owner: Player, ignore: {Instance})
	local newRevolver: Gun.Gun = Gun.new(script.Name, owner, ignore, "Pistol", nil, true)
	
	newRevolver.Firerate = 250
	newRevolver.Firemode = "Semi" -- "Semi", "Auto"

	newRevolver.Ammo = 6
	newRevolver.MagSize = 6
	newRevolver.Reserve = math.huge

	newRevolver.ReloadTime = 1.63
	
	newRevolver.ShotCount = 1
	
	newRevolver.VerticalRecoil = Vector2.new(85,100)
	newRevolver.HorizontalRecoil = Vector2.new(-30,30)
	
	newRevolver.HorizontalSpread = Vector2.new(0,0)
	newRevolver.VerticalSpread = Vector2.new(0,0)	
	
	newRevolver.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newRevolver.ProjectileArg = {
		Damage = 10,	
	}
	
	newRevolver.OnShot.Event:Connect(function()
		newRevolver.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		--newRevolver.ViewModel:PlayAnimation(AnimationRepo.BasicRevolver_Shoot, nil, nil, 5)
		newRevolver.ViewModel:PlaySound("Fire")
	end)
	
	newRevolver.OnReload.Event:Connect(function()
		newRevolver.ViewModel:PlaySound("Reload")
	end)
	
	return newRevolver
end

return Revolver
