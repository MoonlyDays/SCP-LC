--[[-------------------------------------------------------------------------
SCP-1987-J "Freddy Fazbear" - Shared/Client Setup
---------------------------------------------------------------------------]]

--Register the class name globally (needs to be available on both realms)
CLASSES = CLASSES or {}
CLASSES.SCP1987J = "SCP1987J"

--Add language entries (client needs these too)
hook.Add( "SLCLanguagesLoaded", "SCP1987JLanguageShared", function()
	--English
	if _LANG and _LANG["english"] then
		_LANG["english"]["CLASSES"] = _LANG["english"]["CLASSES"] or {}
		_LANG["english"]["CLASS_OBJECTIVES"] = _LANG["english"]["CLASS_OBJECTIVES"] or {}
		_LANG["english"]["WEAPONS"] = _LANG["english"]["WEAPONS"] or {}
		_LANG["english"]["EFFECTS"] = _LANG["english"]["EFFECTS"] or {}

		_LANG["english"]["CLASSES"]["SCP1987J"] = "SCP-1987-J"
		_LANG["english"]["CLASS_OBJECTIVES"]["SCP1987J"] = "You are Freddy Fazbear, an anomalous animatronic. Hunt down personnel using your jumpscare attacks, disable lights with Power Outage, and unleash Showtime for devastating area damage."

		_LANG["english"]["WEAPONS"]["SCP1987J"] = {
			name = "SCP-1987-J",
			desc = "Freddy Fazbear - An anomalous animatronic entity",

			jumpscare = {
				name = "Jumpscare",
				desc = "Close-range attack that deals damage and applies the Frightened effect, slowing and disorienting the target.",
			},

			power_outage = {
				name = "Power Outage",
				desc = "Disable lights in the area, reducing visibility for nearby humans.",
			},

			showtime = {
				name = "Showtime!",
				desc = "Become invulnerable and immobile for 3 seconds, then release a devastating burst attack that damages and frightens all nearby enemies.",
			},
		}

		_LANG["english"]["EFFECTS"]["frightened"] = "Frightened"
		_LANG["english"]["EFFECTS"]["scp1987j_blackout"] = "Blackout"
	end

	--Copy to other languages (they can be translated later)
	local langs = { "russian", "ukrainian", "polish", "french", "chinese", "german", "korean", "turkish" }
	for _, lang in ipairs( langs ) do
		if _LANG and _LANG[lang] then
			_LANG[lang]["CLASSES"] = _LANG[lang]["CLASSES"] or {}
			_LANG[lang]["CLASS_OBJECTIVES"] = _LANG[lang]["CLASS_OBJECTIVES"] or {}
			_LANG[lang]["WEAPONS"] = _LANG[lang]["WEAPONS"] or {}
			_LANG[lang]["EFFECTS"] = _LANG[lang]["EFFECTS"] or {}

			_LANG[lang]["CLASSES"]["SCP1987J"] = _LANG[lang]["CLASSES"]["SCP1987J"] or "SCP-1987-J"
			_LANG[lang]["CLASS_OBJECTIVES"]["SCP1987J"] = _LANG[lang]["CLASS_OBJECTIVES"]["SCP1987J"] or _LANG["english"]["CLASS_OBJECTIVES"]["SCP1987J"]
			_LANG[lang]["WEAPONS"]["SCP1987J"] = _LANG[lang]["WEAPONS"]["SCP1987J"] or _LANG["english"]["WEAPONS"]["SCP1987J"]
			_LANG[lang]["EFFECTS"]["frightened"] = _LANG[lang]["EFFECTS"]["frightened"] or "Frightened"
			_LANG[lang]["EFFECTS"]["scp1987j_blackout"] = _LANG[lang]["EFFECTS"]["scp1987j_blackout"] or "Blackout"
		end
	end
end )

if CLIENT then
	print( "[SCP-LC] SCP-1987-J client data loaded!" )
end
