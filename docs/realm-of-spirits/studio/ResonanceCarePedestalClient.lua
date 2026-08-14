-- ResonanceCarePedestalClient: prompt is server-authoritative (ResonanceCareService).
-- Do not FireServer Care with FromPedestal — that duplicated Care and allowed spoofing.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")

-- Legacy no-op: server no longer sends RequestPedestalCare
ResonanceEvent.OnClientEvent:Connect(function(action, _data)
	if action == "RequestPedestalCare" then
		print("[CarePedestalClient] ignored RequestPedestalCare (server handles Care)")
	end
end)
