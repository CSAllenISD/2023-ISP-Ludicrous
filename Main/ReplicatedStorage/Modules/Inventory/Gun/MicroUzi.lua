local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.MicroUzi

local Gun = require(script.Parent)

local MicroUzi = {}
MicroUzi.__index = MicroUzi
setmetatable(MicroUzi, Gun)

function MicroUzi.new(owner: Player, ignore: {Instance})
	local newMicroUzi: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newMicroUzi.Firerate = 1300
	newMicroUzi.Firemode = "Auto" -- "Semi", "Auto"

	newMicroUzi.Ammo = 20
	newMicroUzi.MagSize = 20
	newMicroUzi.Reserve = math.huge

	newMicroUzi.ReloadTime = .5

	newMicroUzi.VerticalRecoil = Vector2.new(10,20)
	newMicroUzi.HorizontalRecoil = Vector2.new(-20,20)
	
	newMicroUzi.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newMicroUzi.ProjectileArg = {
		Damage = 1
	}
	
	newMicroUzi.OnShot.Event:Connect(function()
		newMicroUzi.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		--.ViewModel:PlayAnimation(AnimationRepo.MicroUzi_Shoot, nil, nil, 5)
		--newMicroUzi.ViewModel:PlaySound("Fire")
	end)
	
	newMicroUzi.OnReload.Event:Connect(function()
		--newMicroUzi.ViewModel:PlaySound("Reload")
	end)

	return newMicroUzi
end

return MicroUzi
