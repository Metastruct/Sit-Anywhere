local useAlt = CreateClientConVar("sitting_use_alt",               "1.00", true, true)
local forceBinds = CreateClientConVar("sitting_force_binds",       "0", true, true)
local SittingNoAltServer = CreateConVar("sitting_force_no_alt","0", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

CreateClientConVar("sitting_ground_sit",         "1.00", true, true)
CreateClientConVar("sitting_disallow_on_me",       "0.00", true, true)

local function ShouldSit(ply)
	return hook.Run("ShouldSit", ply)
end

local arrow = Material("widgets/arrow.png")
local function DoSit(trace)
	local function StartSit()
		local wantedAng
		local start = CurTime()
		local ply = LocalPlayer()
		hook.Add("KeyRelease", "seats_use", function(_, key)
			if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
			if key ~= IN_USE then return end

			hook.Remove("KeyRelease", "seats_use")
			hook.Remove("PostDrawOpaqueRenderables", "SitAnywhere")

			if CurTime() - start < 0.25 then
				RunConsoleCommand("sit")
			elseif wantedAng then
				net.Start("SitAnywhere")
					net.WriteInt(SitAnywhere.NET.SitWantedAng, 4)
					net.WriteFloat(wantedAng.y)
					net.WriteVector(trace.StartPos)
					net.WriteVector(trace.Normal)
				net.SendToServer()
			end
		end)

		hook.Add("PostDrawOpaqueRenderables", "SitAnywhere", function(depth, skybox)
			if CurTime() - start <= 0.25 then return end
			if trace.StartPos:Distance(ply:EyePos()) > 10 then
				hook.Remove("KeyRelease", "seats_use")
				hook.Remove("PostDrawOpaqueRenderables", "SitAnywhere")
				return
			end

			local traceDist, drawScale = 20, 0.1
			local vec = util.IntersectRayWithPlane(ply:EyePos(), ply:EyeAngles():Forward(), trace.HitPos, Vector(0, 0, 1))
			if not vec then
				return
			end

			local posOnPlane = WorldToLocal(vec, Angle(0, 90, 0), trace.HitPos, Angle(0, 0, 0))
			local testVec = (posOnPlane):GetNormal() * traceDist / drawScale
			local currentAng = (trace.HitPos - vec):Angle()
			wantedAng = currentAng

			if posOnPlane:Length() < 2 then
				wantedAng = nil
				return
			end

			if wantedAng then
				local goodSit = SitAnywhere.CheckValidAngForSit(trace.HitPos, trace.HitNormal:Angle(), wantedAng.y)
				if not goodSit then wantedAng = nil end
				cam.Start3D2D(trace.HitPos + Vector(0, 0, 1), Angle(0, 0, 0), 0.1)
					surface.SetDrawColor(goodSit and Color(255, 255, 255, 255) or Color(255, 0, 0, 255))
					surface.SetMaterial(arrow)
					surface.DrawTexturedRectRotated(testVec.x * 0.5, testVec.y * -0.5, 2 / drawScale, traceDist / drawScale, currentAng.y + 90)
				cam.End3D2D()
			end
		end)
	end

	if not trace.Hit then return end

	local surfaceAng = trace.HitNormal:Angle() + Angle(-270, 0, 0)

	local playerTrace = not trace.HitWorld and IsValid(trace.Entity) and trace.Entity:IsPlayer()

	local goodSit = SitAnywhere.GetAreaProfile(trace.HitPos, 24, true)
	if math.abs(surfaceAng.pitch) >= 15 or not goodSit or playerTrace then
		RunConsoleCommand"sit"
		return
	end

	if trace.HitPos:Distance(trace.StartPos) > 100 then
		return
	end
	StartSit()
end


hook.Add("KeyPress","seats_use",function(ply, key)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end


	if key ~= IN_USE then return end
	local good = not useAlt:GetBool()
	local alwaysSit = ShouldSit(ply)

	if forceBinds:GetBool() then
		if useAlt:GetBool() and (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
			good = true
		end
	else
		if useAlt:GetBool() and ply:KeyDown(IN_WALK) then
			good = true
		end
	end

	if SittingNoAltServer:GetBool() then
		good = true
	end

	if alwaysSit == true then
		good = true
	elseif alwaysSit == false then
		good = false
	end

	if not good then return end
	local trace = LocalPlayer():GetEyeTrace()

	if trace.Hit then
		DoSit(trace)
	end
end)

--[[local useHeld = false
hook.Add("CreateMove", "seats_use", function(cmd)
	if not IsFirstTimePredicted() and not game.SinglePlayer() then return end
	local buttons = cmd:GetButtons()

	if bit.band(buttons, IN_USE) == 0 then
		useHeld = false
		return
	end

	
	local ply = LocalPlayer()
	local good = not useAlt:GetBool()
	local alwaysSit = ShouldSit(ply)

	if forceBinds:GetBool() then
		if useAlt:GetBool() and (input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)) then
			good = true
		end
	else
		if useAlt:GetBool() and bit.band(buttons, IN_WALK) == IN_WALK then
			good = true
		end
	end

	if SittingNoAltServer:GetBool() then
		good = true
	end

	if alwaysSit == true then
		good = true
	elseif alwaysSit == false then
		good = false
	end

	if not good then return end
	local trace = LocalPlayer():GetEyeTrace()
	if trace.Hit then
		cmd:SetButtons(bit.bxor(bit.bor(buttons, IN_USE), IN_USE))
		if useHeld then return true end
		useHeld = true
		DoSit(trace)
		--RunConsoleCommand("sit")
		return true
	end
end)]]