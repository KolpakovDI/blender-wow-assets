-- ResonanceCarePedestalClient: pedestal E → same Care path as UI button
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")

local lastCareAt = 0

local function resolveSpiritIndex()
	local idx = tonumber(player:GetAttribute("ActiveSpiritIndex"))
	if idx and idx >= 1 then
		return math.floor(idx)
	end
	return 1
end

local function requestPedestalCare(source)
	local now = os.clock()
	if now - lastCareAt < 0.75 then
		return
	end
	lastCareAt = now
	local idx = resolveSpiritIndex()
	print("[CarePedestalClient]", source, "SpiritIndex=", idx)
	ResonanceEvent:FireServer("Care", {
		SpiritIndex = idx,
		UseTreat = false,
		FromPedestal = true,
	})
end

ResonanceEvent.OnClientEvent:Connect(function(action, _data)
	if action == "RequestPedestalCare" then
		requestPedestalCare("server-event")
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
	if who ~= player then
		return
	end
	if prompt.Name ~= "CarePrompt" then
		return
	end
	requestPedestalCare("prompt")
end)
