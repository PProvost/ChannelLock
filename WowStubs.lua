WowStubs = {}
WowStubs.eventMap = {}
WowStubs.frames = {}
WowStubs.isLoggedIn = nil
WowStubs.currentTime = nil

-- Provide a default implementation of geterrorhandler() as provided by Wow
function geterrorhandler()
	return function(err) 
		print("ERROR - " .. err) 
	end
end

function WowStubs:CallFrameScript(frame, script, ...)
	if frame.scripts[script] then 
		print("Calling " .. script .. " on " .. tostring(frame.name))
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

function GetRealmName() return "Dragonblight" end
function GetLocale() return "enUS" end
function GetTime() return WowStubs.currentTime or os.time() end
function GetChannelName(id) return 0, nil end
function IsLoggedIn() return WowStubs.isLoggedIn end
function InterfaceOptions_AddCategory(frame) end
function UnitName(unit) return "Quaiche" end
function UnitClass(unit) return "Druid", "DRUID" end
function UnitRace(unit) return "Night Elf", "NIGHTELF" end
function UnitFactionGroup(unit) return "Alliance" end

