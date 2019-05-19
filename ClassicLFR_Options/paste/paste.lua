local ClassicLFR_Options = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR_Options")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function ClassicLFR_Options.Paste(text,backfunc)
	ClassicLFR_Options.option_table.args.paste =
	{
		name = CALENDAR_PASTE_EVENT,
		type = "group",
		order = -1,
		args =
		{
			paste =
			{
				name = LOCALE_TEXT_LABEL,
				type = "input",
				multiline = true,
				order = 1,
				width = "full",
				set = nop,
				get = function() return text end,
			},
			back =
			{
				name = BACK,
				type = "execute",
				order = 2,
				func = function()
					ClassicLFR_Options.option_table.args.paste = nil
					backfunc()
				end
			}
		}
	}
	AceConfigDialog:SelectGroup("ClassicLFR","paste")
end

function ClassicLFR_Options.paste(tb,key,ignoreblank,...)
	local argsd = {...}
	ClassicLFR_Options.option_table.args.paste =
	{
		name = CALENDAR_PASTE_EVENT,
		type = "group",
		order = -1,
		args =
		{
			edit =
			{
				name = EDIT,
				type = "input",
				multiline = true,
				order = 1,
				width = "full",
				confirm = true,
				set = function(_,val)
					local lower = string.lower
					local gsub = string.gsub
					local t = {}
					if ignoreblank == true then
						for str in string.gmatch(val, "([^\n]+)") do
							t[#t+1]=lower(gsub(str," ",""))
						end
					elseif ignoreblank == false then
						for str in string.gmatch(val, "([^\n]+)") do
							t[#t+1]=str
						end
					elseif ignoreblank == 0 then
						for str in string.gmatch(val, "([^\n]+)") do
							t[lower(str)]=true
						end
						if next(t) then
							tb[key] = t
						else
							tb[key] = nil
						end
						return
					else
						for str in string.gmatch(val, "([^\n]+)") do
							t[#t+1]=lower(str)
						end
					end
					if #t == 0 then
						if ignoreblank == false then
							tb[key] = t
						else
							tb[key] = nil
						end
					else
						table.sort(t)
						tb[key] = t
					end
				end,
				get = function()
					local ft = tb[key]
					if ft then
						if ignoreblank == 0 then
							local concat = {}
							for k,v in pairs(ft) do
								concat[#concat+1] = k
							end
							return table.concat(concat,'\n')
						else
							return table.concat(ft,'\n')
						end
					end
				end,
			},
			back =
			{
				name = BACK,
				type = "execute",
				order = 2,
				func = function()
					ClassicLFR_Options.option_table.args.paste = nil
					AceConfigDialog:SelectGroup("ClassicLFR",unpack(argsd))
				end
			}
		}
	}
	AceConfigDialog:SelectGroup("ClassicLFR","paste")
end
