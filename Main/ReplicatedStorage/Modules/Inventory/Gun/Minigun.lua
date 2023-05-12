local RepStor = game:GetService("ReplicatedStorage")
local AnimationRepo = RepStor.Assets.Animations.Tools.Minigun

local TweenSer = game:GetService("TweenService")

local Gun = require(script.Parent)

local Minigun = {}
Minigun.__index = Minigun
setmetatable(Minigun, Gun)

function Minigun.new(owner: Player, ignore: {Instance})
	local newMinigun: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newMinigun.Firerate = 3000
	newMinigun.Firemode = "Auto" -- "Semi", "Auto"

	newMinigun.Ammo = 300
	newMinigun.MagSize = 300
	newMinigun.ShotCount = 1
	newMinigun.Reserve = math.huge

	newMinigun.ReloadTime = 3

	newMinigun.VerticalRecoil = Vector2.new(-5,5)
	newMinigun.HorizontalRecoil = Vector2.new(-5,5)
	
	newMinigun.VerticalSpread = Vector2.new(-4,4)
	newMinigun.HorizontalSpread = Vector2.new(-4,4)
	
	newMinigun.Projectile = RepStor.Modules.ProjectileModules.Projectiles.PlasmaBall
	
	local mouse = owner:GetMouse()
	
	local FiringAnimation: AnimationTrack = nil
	local ShootTweenRight: Tween
	local ShootTweenLeft: Tween
	
	local LeftLightTween
	local RightLightTween
	newMinigun.StartShooting.Event:Connect(function()
		if newMinigun.Equipped then
			FiringAnimation = newMinigun.ViewModel:PlayAnimation(AnimationRepo.Minigun_Shoot, .5, nil, 5)
			newMinigun.ViewModel:PlaySound("Fire")
			
			RightLightTween = TweenSer:Create(newMinigun.ViewModel.Model.Main.RightBarrel.PointLight, TweenInfo.new(3, Enum.EasingStyle.Quad), {Brightness = 40})
			RightLightTween:Play()
			LeftLightTween = TweenSer:Create(newMinigun.ViewModel.Model.Main.LeftBarrel.PointLight, TweenInfo.new(3, Enum.EasingStyle.Quad), {Brightness = 40})
			LeftLightTween:Play()
			
			ShootTweenRight = TweenSer:Create(newMinigun.ViewModel.Model.Main.RightBarrel, TweenInfo.new(3), {Color = Color3.new(1, 0.368627, 0)})
			ShootTweenRight:Play()	
			ShootTweenLeft = TweenSer:Create(newMinigun.ViewModel.Model.Main.LeftBarrel, TweenInfo.new(3), {Color = Color3.new(1, 0.368627, 0)})
			ShootTweenLeft:Play()
		end
	end)
	
	newMinigun.EndShooting.Event:Connect(function()
		if newMinigun.Equipped then
			if FiringAnimation then
				FiringAnimation:Stop(1.818)
			end
			newMinigun.ViewModel:StopSound("Fire")
			newMinigun.ViewModel:PlaySound("Stop")
			
			if RightLightTween then
				RightLightTween:Cancel()
			end
			if LeftLightTween then 
				LeftLightTween:Cancel()
			end
			
			if ShootTweenRight then
				ShootTweenRight:Cancel()
			end
			if ShootTweenLeft then
				ShootTweenLeft:Cancel()
			end
			
			RightLightTween = TweenSer:Create(newMinigun.ViewModel.Model.Main.RightBarrel.PointLight, TweenInfo.new(3), {Brightness = 0})
			RightLightTween:Play()
			LeftLightTween = TweenSer:Create(newMinigun.ViewModel.Model.Main.LeftBarrel.PointLight, TweenInfo.new(3), {Brightness = 0})
			LeftLightTween:Play()
			
			ShootTweenRight = TweenSer:Create(newMinigun.ViewModel.Model.Main.RightBarrel, TweenInfo.new(3), {Color = Color3.new(0, 0, 0)})
			ShootTweenRight:Play()	
			ShootTweenLeft = TweenSer:Create(newMinigun.ViewModel.Model.Main.LeftBarrel, TweenInfo.new(3), {Color = Color3.new(0, 0, 0)})
			ShootTweenLeft:Play()
		end
	end)
	
	newMinigun.OnUnEquip.Event:Connect(function()
		if FiringAnimation then
			FiringAnimation:Stop()
		end
		newMinigun.ViewModel:StopSound("Fire")
		newMinigun.ViewModel:StopSound("Stop")
		
		if ShootTweenLeft	then
			ShootTweenLeft:Cancel()
		end
		if ShootTweenRight then
			ShootTweenRight:Cancel()
		end
		
		newMinigun.ViewModel.Model.Main.LeftBarrel.Color = Color3.new(0,0,0)
		newMinigun.ViewModel.Model.Main.RightBarrel.Color = Color3.new(0,0,0)
		newMinigun.ViewModel.Model.Main.LeftBarrel.PointLight.Brightness = 0
		newMinigun.ViewModel.Model.Main.RightBarrel.PointLight.Brightness = 0
	end)
	
	newMinigun.OnShot.Event:Connect(function()
		newMinigun.ViewModel.Model.Main.FirePart["1"].MuzzleFlash:Emit(1)
		newMinigun.ViewModel.Model.Main.FirePart["2"].MuzzleFlash:Emit(1)
	end)

	newMinigun.OnReload.Event:Connect(function()
		newMinigun.ViewModel:PlaySound("Reload")
	end)

	return newMinigun
end

return Minigun
