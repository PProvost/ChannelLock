-- Set this to true to debug stub issues
local verbose = nil

--[[
-- PRIVATE IMPLEMNENTATION HELPER CRAP
--]]

WowStubs = {}
WowStubs.eventMap = {}
WowStubs.frames = {}
WowStubs.isLoggedIn = nil
WowStubs.currentTime = nil
WowStubs.channels = {}

function WowStubs:CallFrameScript(frame, script, ...)
	if frame.scripts[script] then 
		if (verbose) then print("Calling " .. script .. " on " .. tostring(frame.name)) end
		pcall( frame.scripts[script], frame, ... )
	end
end

function WowStubs:RaiseEvent(event, ...)
	if not self.eventMap[event] then return end
	for i,frame in ipairs(self.eventMap[event]) do
		self:CallFrameScript(frame, "OnEvent", event, ...)
	end
end

function WowStubs:OnUpdate(elapsed)
	if not elapsed then elapsed = 1000 end
	for i,frame in ipairs(self.frames) do
		self:CallFrameScript(frame, "OnUpdate", elapsed)
	end
end

--[[
-- GLOBAL IMPLEMENTATIONS OF WOW FUNCTIONS
--]]

SlashCmdList = {}

function geterrorhandler()
	return function(err) 
		print("ERROR - " .. err) 
	end
end

function CreateFrame(type, name, template)
	local frame = {}

	frame.type = type
	frame.name = name
	frame.template = template

	frame.scripts = {}
	frame.RegisterEvent = function(self, event)
		if not WowStubs.eventMap[event] then WowStubs.eventMap[event] = {} end
		table.insert(WowStubs.eventMap[event], frame)
	end
	frame.SetScript = function(self, handler, script)
		self.scripts[handler] = script
	end
	frame.Hide = function() end
	frame.SetAutoFocus = function(val) end
	frame.SetHeight = function(y) end
	frame.SetWidth = function(w) end
	frame.SetPoint = function(...) end
	frame.ClearAllPoints = function(...) end
	frame.SetFontObject = function(...) end
	frame.CreateFontString = function(...)
		local fs = {}
		fs.SetPoint = function(...) end
		fs.SetJustifyH = function(...) end
		fs.SetJustifyV = function(...) end
		fs.SetText = function(...) end
		return fs
	end
	frame.CreateTexture = function(...)
		local tex = {}
		tex.SetWidth = function(w) end
		tex.SetHeight = function(h) end
		tex.SetPoint = function(...) end
		tex.SetTexture = function(...) end
		tex.SetTexCoord = function() end
		return tex
	end

	table.insert(WowStubs.frames, frame)
	return frame
end

function GetChannelName(id)
	if WowStubs.channels[id] then
		return unpack(WowStubs.channels[id])
	else
		return 0, nil
	end
end

function LeaveChannelByName(name)
	for i = 1,10 do
		local id, name = WowStubs.channels[i]
		if id then
			WowStubs.channels[i] = nil
		end
	end
end

-- Monkey patch JoinPermanentChannel to use the local channels array
function JoinPermanentChannel(name)
	for i = 1,10 do
		if WowStubs.channels[i] == nil then
			WowStubs.channels[i] = { i, name }
		end
	end
end



function GetRealmName() return "Dragonblight" end
function GetRealZoneText() return "Dalaran" end
function GetLocale() return "enUS" end
function GetTime() return WowStubs.currentTime or os.time() end
function IsLoggedIn() return WowStubs.isLoggedIn end
function InterfaceOptions_AddCategory(frame) end
function UnitName(unit) return "Quaiche" end
function UnitClass(unit) return "Druid", "DRUID" end
function UnitRace(unit) return "Night Elf", "NIGHTELF" end
function UnitFactionGroup(unit) return "Alliance" end

