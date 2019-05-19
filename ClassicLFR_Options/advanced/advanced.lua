local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")
local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("ClassicLFR")

ClassicLFR_Options:push("advanced",{
	name = ADVANCED_LABEL,
	type = "group",
	args =
	{
		disable_blizzard =
		{
			name = DISABLE.." BlizzardUI",
			type = "group",
			args =
			{
				quick_join =
				{
					name = QUICK_JOIN,
					type = "toggle",
					get = function(info)
						return not ClassicLFR.db.profile.disable_quick_join
					end,
					confirm = true,
					set = function(info,val)
						if val then
							ClassicLFR.db.profile.disable_quick_join = nil
						else
							ClassicLFR.db.profile.disable_quick_join = true
						end
						ReloadUI()
					end,
				},
			}
		},
		window =
		{
			name = L.options_window,
			type = "group",
			args =
			{
				save = 
				{
					name = SAVE,
					order = 1,
					type = "execute",
					func = function()
						local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
						local height, width	= st.height, st.width
						local profile = ClassicLFR_Options.db.profile
						if height == 500 then
							profile.window_height = nil
						else
							profile.window_height = height
						end
						if width == 700 then
							profile.window_width = nil
						else
							profile.window_width = width
						end
					end,
				},
				cancel = 
				{
					name = RESET,
					order = 2,
					type = "execute",
					func = function()
						local v = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
						local profile = ClassicLFR_Options.db.profile
						v.height = nil
						profile.window_height = nil
						v.width = nil
						profile.window_width = nil
					end,
				},
				line =
				{
					name = nop,
					order = 3,
					type = "description",
					width = "full"
				},
				height =
				{
					name = COMPACT_UNIT_FRAME_PROFILE_FRAMEHEIGHT,
					type = "range",
					max = tonumber(GetCVar("gxFullscreenResolution"):match("%d+x(%d+)")),
					step = 0.01,
					get = function()
						local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")).height
						if v then
							return v
						else
							return 500
						end
					end,
					set = function(info,val)
						local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
						if val == 500 then
							st.height = nil
						else
							st.height = val
						end
					end,
				},
				width =
				{
					name = COMPACT_UNIT_FRAME_PROFILE_FRAMEWIDTH,
					type = "range",
					max = tonumber(GetCVar("gxFullscreenResolution"):match("(%d+)x%d+")),
					step = 0.01,
					get = function(info)
						local v = (LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")).width
						if v then
							return v
						else
							return 700
						end
					end,
					set = function(info,val)
						local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("ClassicLFR")
						if val == 700 then
							st.width = nil
						else
							st.width = val
						end
					end,
				},
			}
		},
		role_check =
		{
			name = LFG_LIST_ROLE_CHECK,
			desc = string.format(L.options_advanced_role_check,ROLE),
			type = "toggle",
			get = ClassicLFR_Options.get_function,
			set = ClassicLFR_Options.set_function,
		},
		hardware =
		{
			name = HARDWARE,
			desc = L.options_advanced_hardware,
			type = "toggle",
			get = ClassicLFR_Options.get_function,
			set = ClassicLFR_Options.set_function,
		},
		mute =
		{
			name = MUTE,
			desc = L.options_advanced_mute,
			type = "toggle",
			get = ClassicLFR_Options.get_function,
			set = ClassicLFR_Options.set_function,
		},
		taskbar_flash = 
		{
			name = L["Taskbar Flash"],
			type = "toggle",
			get = ClassicLFR_Options.get_function,
			set = ClassicLFR_Options.set_function,
		},
		complete =
		{
			name = COMPLETE,
			desc = L.options_advanced_complete,
			type = "toggle",
			get = ClassicLFR_Options.get_function,
			set = ClassicLFR_Options.set_function,
		},
	}
})
