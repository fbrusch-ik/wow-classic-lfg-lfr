local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")

local mplus_name,label_name = C_LFGList.GetActivityInfo(459) -- "Eye of Azshara (Mythic Keystone)"

ClassicLFR_Options.mythic_keystone = mplus_name:sub(C_LFGList.GetActivityGroupInfo(112):len()+1)


ClassicLFR_Options:RegisterMessage("LFG_OPT_CATEGORY",function(message,option_table,category)
	if category == 2 then
		option_table.f.args.opt.args.mplus=
		{
			name = label_name,
			type = "toggle",
			set = function(_,val)
				ClassicLFR_Options.db.profile.mplus = val or nil
			end,
			get = function()
				return ClassicLFR_Options.db.profile.mplus
			end,
		}
	else
		option_table.f.args.opt.args.mplus=nil
	end
end)

ClassicLFR_Options.RegisterSimpleFilter("find",function(info)
	local fullName, shortName = C_LFGList.GetActivityInfo(info.activityID)
	if shortName ~= label_name then
		return 1
	end
end,function(profile)
	local a = profile.a
	return a.category == 2 and profile.mplus
end)
