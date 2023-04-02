local RepStor = game:GetService("ReplicatedStorage")

local Gun = require(script.Parent)

local SpellBook = {}
SpellBook.__index = SpellBook
setmetatable(SpellBook, Gun)

function SpellBook.new(owner: Player, ignore: {Instance})
	local newSpellBook: Gun.Gun = Gun.new(script.Name, owner, ignore, "Special", RepStor.Modules.ProjectileModules.Projectiles.FireBall)

	newSpellBook.Firerate = 250
	newSpellBook.Firemode = "Auto" -- "Semi", "Auto"

	newSpellBook.Ammo = 10
	newSpellBook.MagSize = 10
	newSpellBook.ShotCount = 1
	
	newSpellBook.Reserve = math.huge

	newSpellBook.ReloadTime = 2.317

	newSpellBook.VerticalRecoil = Vector2.new(0,0)
	newSpellBook.HorizontalRecoil = Vector2.new(0,0)
	
	newSpellBook.HorizontalSpread = Vector2.new(-3,3)
	newSpellBook.VerticalSpread = Vector2.new(-3,3)

	newSpellBook.OnShot.Event:Connect(function()
		newSpellBook.ViewModel:PlayAnimation(script.Animations.Shoot, nil, nil, 4)
		newSpellBook.ViewModel:PlaySound("Fire")
	end)

	newSpellBook.OnReload.Event:Connect(function()
		newSpellBook.ViewModel:PlaySound("Reload")
	end)

	return newSpellBook
end

return SpellBook
