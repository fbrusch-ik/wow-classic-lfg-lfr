local LibStub = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")
local wipe = wipe
local pairs = pairs
local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")

local order = 0
local function get_order()
	local temp = order
	order = order +1
	return temp
end

local select_tb = {}

local rm_str = FRIENDS_LIST_REALM:match("^(.*)%:") or FRIENDS_LIST_REALM:match("^(.*)%：") or FRIENDS_LIST_REALM

function ClassicLFR_Options.add_realm_filter(_,val)
	if val:len() == 0 then
		return
	end
	local tb = ClassicLFR.db.profile.realm_filters
	if tb == nil then
		tb = {}
	end
	tb[val:lower()] = true
	ClassicLFR.db.profile.realm_filters = tb
end

local temp = {}

ClassicLFR_Options:push("realm_filter",{
	name = rm_str,
	type = "group",
	args =
	{
		enable =
		{
			name = ENABLE,
			desc = format(L.bwlist_desc,rm_str,rm_str,DISABLE),
			order = get_order(),
			type = "toggle",
			get = function(info)
				local mode_rf = ClassicLFR.db.profile.mode_rf
				if mode_rf then
					return true
				elseif mode_rf == false then
					return nil
				else
					return false
				end
			end,
			set = function(info,val)
				if val then
					ClassicLFR.db.profile.mode_rf = true
				elseif val == nil then
					ClassicLFR.db.profile.mode_rf = false
				else
					ClassicLFR.db.profile.mode_rf = nil
				end
			end,
			width = "full",
			tristate = true
		},
		add =
		{
			name = ADD,
			type = "input",
			order = get_order(),
			set = ClassicLFR_Options.add_realm_filter,
			get = nop,
			width = "full"
		},
		rmv =
		{
			name = REMOVE,
			type = "execute",
			order = get_order(),
			func = function()
				local realm_filters = ClassicLFR.db.profile.realm_filters
				if realm_filters then
					for k,v in pairs(select_tb) do
						realm_filters[k] = nil
					end
					if next(realm_filters) == nil then
						ClassicLFR.db.profile.realm_filters=nil
					end
				end
				wipe(select_tb)
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = get_order(),
			func = function() wipe(select_tb) end
		},
		fts =
		{
			name = FILTERS,
			type = "multiselect",
			order = get_order(),
			values = function()
				wipe(temp)
				if ClassicLFR.db.profile.realm_filters then
					for k,v in pairs(ClassicLFR.db.profile.realm_filters) do
						temp[k] = k
					end
					return temp
				end
			end,
			set = function(_,key,val)
				if val then
					select_tb[key] = true
				else
					select_tb[key] = nil
				end
			end,
			get = function(_,key)
				return select_tb[key]
			end,
			width = "full",
		},
		cpft =
		{
			order = get_order(),
			name = COPY_FILTER,
			type = "execute",
			func = function()
				ClassicLFR_Options.paste(ClassicLFR.db.profile,"realm_filters",0,"realm_filter")
			end
		}
	}
})

ClassicLFR_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,func)
	return func(info.leaderName) and 1
end,function()
	if ClassicLFR.db.profile.mode_rf ~= nil then
		return ClassicLFR.realm_filter
	end
end)
