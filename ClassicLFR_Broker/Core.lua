local AceAddon = LibStub("AceAddon-3.0")
local ClassicLFR = AceAddon:GetAddon("ClassicLFR")

local LDB = LibStub("LibDataBroker-1.1"):NewDataObject(LFG_TITLE:gsub(" ",""),{
	type = "data source",
	icon = "Interface/Icons/INV_Misc_GroupNeedMore",
})

function LDB:OnClick(button)
	if button == "RightButton" then
		if IsControlKeyDown() or IsShiftKeyDown()  then
			ClassicLFR:SendMessage("LFG_ICON_RIGHT_CLICK", 0)
		else
			ClassicLFR:SendMessage("LFG_ICON_RIGHT_CLICK")
		end
	elseif button == "LeftButton" then
		ClassicLFR:SendMessage("LFG_ICON_LEFT_CLICK")
	else
		ClassicLFR:SendMessage("LFG_ICON_MIDDLE_CLICK")
	end
end

function LDB:OnEnter()
	GameTooltip:SetOwner(self)
	GameTooltip:ClearLines()
	GameTooltip:AddLine("ClassicLFR")
	local ClassicLFR_Options = AceAddon:GetAddon("ClassicLFR_Options",true)
	if ClassicLFR_Options and ClassicLFR_Options.Background_Timer then
		GameTooltip:AddLine("|cff8080cc"..SEARCHING.."|r")
		local bg_rs = ClassicLFR_Options.Background_Result
		if bg_rs then
			GameTooltip:AddLine(table.concat{"|cffff00ff",KBASE_SEARCH_RESULTS,"(",bg_rs,")|r"})
		end
	end
	GameTooltip:Show()
end

function LDB:OnLeave()
	GameTooltip:Hide()
end

ClassicLFR.LDB = LDB
