local ClassicLFR = LibStub("AceAddon-3.0"):GetAddon("ClassicLFR")

ClassicLFR:NewModule("Icon").OnEnable = function()
	LibStub("LibDBIcon-1.0"):Register(LFG_TITLE:gsub(" ",""),ClassicLFR.LDB,(LibStub("AceDB-3.0"):New("ClassicLFR_IconCharacterDB", {profile = {}})).profile)
end
