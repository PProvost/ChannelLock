WowStubs = {}
WowStubs.isLoggedIn = nil

function geterrorhandler()
	return function(err) print("ERROR - " .. err) end
end

WowStubs.eventMap = {}
-- TODO: make param1 be frame and if p1 is string, assume it is the "all" form
function RaiseEvent(event, ...)
	if not WowStubs.eventMap[event] then return end
	for i,frame in ipairs(WowStubs.eventMap[event]) do
		if frame.scripts["OnEvent"] then 
			print("firing " .. event .. " on " .. tostring(frame.name))
			pcall( frame.scripts["OnEvent"], frame, event, ... )
		end
	end
end

WowStubs.frames = {}
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
function UnitName(unit) return "Quaiche" end
function UnitClass(unit) return "Druid", "DRUID" end
function UnitRace(unit) return "Night Elf", "NIGHTELF" end
function UnitFactionGroup(unit) return "Alliance" end
function GetLocale() return "enUS" end

WowStubs.currentTime = nil
function GetTime() return WowStubs.currentTime or os.time() end

function GetChannelName(id) return 0, nil end
function IsLoggedIn() return WowStubs.isLoggedIn end
function InterfaceOptions_AddCategory(frame) end
