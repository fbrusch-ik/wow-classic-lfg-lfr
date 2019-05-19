local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")
local order = 0
local function get_order()
	local temp = order
	order = order +1
	return temp
end

ClassicLFR_Options:push("cr",{
	name = L["Cross Realm"],
	type = "group",
	args =
	{
		scan =
		{
			order = get_order(),
			name = L.cr_realm_scan,
			desc = L.cr_realm_scan_desc,
			type = "execute",
			func = function()
				ClassicLFR:SendMessage("LFG_ICON_RIGHT_CLICK")
			end,
		},
		rand_hop =
		{
			order = get_order(),
			name = L.cr_realm_rand_hop,
			desc = L.cr_realm_rand_hop_desc,
			type = "execute",
			func = function()
				ClassicLFR:SendMessage("LFG_ICON_RIGHT_CLICK",0)
			end,
		}
	}
})
