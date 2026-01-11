--[[-------------------------------------------------------------------------
SCP-1987-J "Freddy Fazbear" Registration
A joke SCP that spawns exclusively as a support group (not in regular rotation)
---------------------------------------------------------------------------]]

--Make sure shared file is sent to clients
AddCSLuaFile( "autorun/sh_scp_1987j.lua" )

--Spawn position for Freddy (uses CI spawn area - arrives with Chaos Insurgency style)
SPAWN_SUPPORT_1987J = {
	Vector( 540.00, 7050.00, 2035.00 ),
}

--Register the SCP
hook.Add( "RegisterSCP", "RegisterSCP1987J", function()
	RegisterSCP( "SCP1987J", "models/player/charple.mdl", "weapon_scp_1987j", {
		jump_power = 150,
		prep_freeze = true,
		no_select = true, --Cannot be selected in regular rotation
		dynamic_spawn = true, --Uses dynamic spawn position
	}, {
		base_health = { var = 1350, min = 800, max = 2000 },
		max_health = { var = 1350, min = 800, max = 2000 },
		base_speed = { var = 185, min = 150, max = 220 },
		buff_scale = 0.8,
		prot_scale = 0.9,
	}, nil, function( ply )
		--Post setup callback
		ply:SetBodygroup( 0, 0 )
	end )
end )

--Register support group class
hook.Add( "SLCRegisterClassGroups", "SCP1987JSupport", function()
	--Add the support group (only Freddy spawns)
	AddSupportGroup( "scp_1987j", 8, SPAWN_SUPPORT_1987J, 1, function()
		--Callback when Freddy spawns
		SetRoundProperty( "scp_1987j_spawned", true )

		--Play announcement
		--PlayPA( "scp_lc/announcements/scp1987j.ogg", 10 ) --Uncomment if you add a custom announcement

		--Broadcast message to all players
		for i, v in ipairs( player.GetAll() ) do
			if v:SCPTeam() != TEAM_SPEC then
				v:ChatPrint( "[ALERT] Anomalous animatronic entity detected in the facility!" )
			end
		end
	end, function()
		--Spawn rule: Only spawn once per round, after 2 minutes have passed
		if GetRoundProperty( "scp_1987j_spawned" ) then return false end

		local round = GetTimer( "SLCRound" )
		if !IsValid( round ) then return false end

		--Only spawn after 2 minutes (120 seconds) into the round
		return round:GetTime() - round:GetRemainingTime() >= 120
	end )
end )

--Register the support class (Freddy himself)
hook.Add( "SLCRegisterPlayerClasses", "SCP1987JSupportClass", function()
	RegisterSupportClass( "scp_1987j_freddy", "scp_1987j", "models/player/charple.mdl", {
		team = TEAM_SCP,
		name = "SCP1987J",
		loadout = nil,
		weapons = {},
		ammo = {},
		health = 1350,
		walk_speed = 185,
		run_speed = 185,
		max = 1, --Only one Freddy
		tier = 0,
		spawn_protection = false,
		callback = function( ply, class )
			--Setup player as SCP-1987-J
			local scp = GetSCP( "SCP1987J" )
			if scp then
				scp:SetupPlayer( ply, true, ply:GetPos() )
			end
		end
	} )
end )

print( "[SCP-LC] SCP-1987-J 'Freddy Fazbear' support group loaded!" )
