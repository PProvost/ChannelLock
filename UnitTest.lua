-- 
-- This file is meant to be run from a wowlua interactive shell
--

require("WowStubs")
require("TocLoader")
require("Utils")
require("Libs/LuaUnit/LuaUnit")

ChannelLockTests = {}

-- Bogus SV setup for tests
ChannelLockDB = {
	["profileKeys"] = {
		["Quaiche - Dragonblight"] = "Default",
	},
	["profiles"] = {
		["Default"] = {
			["channels"] = {
				[3] = {
					["name"] = "Pissoff",
					["frameIndex"] = "3",
				},
				[5] = {
					["name"] = "DBAOF",
					["frameIndex"] = "3",
				},
				[6] = {
					["name"] = "BTRL09",
					["frameIndex"] = "4",
				},
			},
		},
	},
}

function ChannelLockTests:setUp()
	-- Only do this once
	if not self.addonLoaded then
		LoadToc("ChannelLock.toc")
		WowStubs.isLoggedIn = true
		WowStubs:RaiseEvent("PLAYER_LOGIN")
		WowStubs:RaiseEvent("VARIABLES_LOADED")
		WowStubs:RaiseEvent("ADDON_LOADED", "ChannelLock")
		self.addonLoaded = true
	end
end

function ChannelLockTests:test_CleanChannelName()
	assertEquals( ChannelLock:CleanChannelName(nil), nil )
	assertEquals( ChannelLock:CleanChannelName("Icecrown"), "Icecrown" )
	assertEquals( ChannelLock:CleanChannelName("Trade (City)"), "Trade" )
end

function ChannelLockTests:test_GetSourceList()
	WowStubs.channels = {
		[1] = { 1, "General" },
		[2] = { 2, "Trade" } ,
		[5] = { 5, "DBAOF" },
	}

	local source = ChannelLock:GetSourceList()

	assertEquals( source[1].name, "general" )
	assertEquals( source[2].name, "trade" )
	assertEquals( source[5].name, "dbaof" )
end

function ChannelLockTests:test_MakeCommandQueue()
	assert(false)
end

--- GO!!
LuaUnit:run('ChannelLockTests')

