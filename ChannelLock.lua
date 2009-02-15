--[[
ChannelLock/ChannelLock.lua

Copyright 2008 Quaiche

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

ChannelLock = LibStub("AceAddon-3.0"):NewAddon("ChannelLock", "AceConsole-3.0", "AceTimer-3.0")
ChannelLock.revision = tonumber(("$Revision$"):match("%d+"))
ChannelLock.date = ("$Date$"):match("%d%d%d%d%-%d%d%-%d%d")

ChannelLock.debug = false

local timerDelay = 1

local TRADE_CHANNEL_NAME = "Trade - City"
local debugf = tekDebug and tekDebug:GetFrame("ChannelLock")

local knownTradeZones = {
	['Orgrimmar'] = 1,
	['Thunder Bluff'] = 1,
	['Undercity'] = 1,
	['Stormwind City'] = 1,
	['Darnassus'] = 1,
	['Ironforge'] = 1,
	['Shattrath City'] = 1,
	['Silvermoon City'] = 1,
	['The Exodar'] = 1,
	['Dalaran'] = 1,
}

function ChannelLock:OnInitialize()
	self.defaults = self:GetDefaults()
	self.db = LibStub("AceDB-3.0"):New("ChannelLockDB", self.defaults, "Default")


	self.options = self:GetOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("ChannelLock", self.options )
	LibStub("tekKonfig-AboutPanel").new(nil, "ChannelLock")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Channels", "ChannelLock", "channels")
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ChannelLock", "Profiles", "ChannelLock", "profiles")
end

function ChannelLock:OnEnable()
	self.commandQueue = {}
	self.deferredCommands = {}

	self:Debug( "Enable - Scheduling channel check")
	self:ScheduleTimer("CheckChannels", timerDelay)
end

function ChannelLock:Debug(...)
	if debugf then
		self:Print(debugf, ...)
	end
end

function ChannelLock:DebugF(...)
	if debugf then
		self:Print(debugf, string.format(...))
	end
end

-- TODO: We really need to compare slot, name and frameIndex to build the right command queue
function ChannelLock:CheckChannels()
	local myChannels = self.db.profile.channels
	for i = 1,10 do
		local id, name = GetChannelName(i)
		name = self:CleanChannelName(name)
		if myChannels[i] and myChannels[i].name and not myChannels[i].empty then
			if myChannels[i].name ~= name then
				-- The wrong channel is in this slot, remove it before adding the correct one
				if name then
					table.insert(self.commandQueue, { action="leave", id = i, name=name })
				end
				table.insert(self.commandQueue, { action="join", id = i, name = myChannels[i].name, frameIndex = myChannels[i].frameIndex })
			else
				-- Always add to frame... maybe this will help...
				table.insert(self.commandQueue, { action="addtoframe", id=i, name=myChannels[i].name, frameIndex=myChannels[i].frameIndex } )
			end
		else
			-- There should be nothing in this slot, remove it, add a stub and schedule the stub removal
			if id > 0 and name then
				table.insert(self.commandQueue, { action = "leave", id = i, name=name })
			end

			table.insert(self.commandQueue, { action = "join", id = i, name = "QCHANNEL"..i, frameIndex=1 })
			table.insert(self.deferredCommands, { action = "leave", id = i, name = "QCHANNEL"..i } )
		end
	end

	if not self.debug then
		self.processingTimer = self:ScheduleRepeatingTimer("ProcessUpdatesQueue", timerDelay)
	end
end

function ChannelLock:ProcessUpdatesQueue()
	local item = table.remove(self.commandQueue, 1)
	if not item then
		if self.deferredCommands then
			self.commandQueue = self.deferredCommands
			self.deferredCommands = nil
			item = table.remove(self.commandQueue, 1)
		else
			self:Print("Channel setup complete! You are ready to go.")
			self:CancelTimer(self.processingTimer)
			return
		end
	end

	if item.action == "join" then
		self:JoinChannel(item.name, item.frameIndex)
		table.insert(self.commandQueue, { action="addtoframe", id=item.id, name=item.name, frameIndex=item.frameIndex } )
	elseif item.action == "addtoframe" then
		ChatFrame_AddChannel(_G["ChatFrame"..item.frameIndex], item.name)
	elseif item.action == "leave" then
		self:LeaveChannel(item.name, item.frameIndex)
	end
end

-- this reduces server zone channels (general, trade, etc to their base parts with no zone info)
function ChannelLock:CleanChannelName(channel)
	if (channel == nil) then return nil; end
	local spaceFound = string.find(channel, " ");
	if (spaceFound) then
		channel = string.sub(channel, 1, spaceFound - 1);
	end
	return channel;
end

local function NoopFilter() return true end

function ChannelLock:JoinChannel(channel, frameIndex)
	if not frameIndex then return end
	local frame = _G["ChatFrame"..frameIndex]

	-- ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)

	if channel == "LookingForGroup" then SetLookingForGroup(3,5,3) end
	JoinPermanentChannel(channel, nil, frameIndex, nil)
	if channel == "LookingForGroup" then ClearLookingForGroup() end

	-- ChatFrame_RemoveMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", NoopFilter)
end

function ChannelLock:LeaveChannel(channel, frameIndex)
	if not channel then return end
	if not frameIndex then frameIndex = 1 end

	if channel == "LookingForGroup" then SetLookingForGroup(3, 5, 3) end
	if channel == TRADE_CHANNEL_NAME and not knownTradeZones(GetZoneText) then
		self:Debug( "LeaveChannel - Unable to drop the Trade channel because you are not in a trade zone.")
	end

	LeaveChannelByName(channel);

	if channel == "LookingForGroup" then ClearLookingForGroup() end
end

