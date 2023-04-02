local Gun = require(script.Parent)

local Pistol = {}
Pistol.__index = Pistol
setmetatable(Pistol, Gun)

function Pistol.new(owner: Player, ignore: {Instance})
	local newPistol: Gun.Gun = Gun.new(script.Name, owner, ignore, "Pistol")
	
	newPistol.Firerate = 450
	newPistol.Firemode = "Semi" -- "Semi", "Auto"

	newPistol.Ammo = 15
	newPistol.MagSize = 15
	newPistol.Reserve = math.huge

	newPistol.ReloadTime = 1.63
	
	newPistol.ShotCount = 1
	
	newPistol.VerticalRecoil = Vector2.new(-10,10)
	newPistol.HorizontalRecoil = Vector2.new(-10,10)
	
	newPistol.HorizontalSpread = Vector2.new(0,0)
	newPistol.VerticalSpread = Vector2.new(0,0)	
	
	newPistol.OnShot.Event:Connect(function()
		newPistol.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		newPistol.ViewModel:PlayAnimation(script.Animations.Shoot, nil, nil, 5)
		newPistol.ViewModel:PlaySound("Fire")
	end)
	
	newPistol.OnReload.Event:Connect(function()
		newPistol.ViewModel:PlaySound("Reload")
	end)
	
	return newPistol
end

return Pistol
