-- SpiritMeshGenerationService (Q4 stub): ONLINE path hard-blocked by ExpansionGate
-- Offline resolve stays in SpiritMeshResolve — this module must not publish assets until unlocked.

local SpiritMeshGenerationService = {}

SpiritMeshGenerationService.OnlineEnabled = false

local function gateAllows()
	local ok, ExpansionGate = pcall(function()
		return require(game:GetService("ReplicatedStorage").RealmOfSpirits:WaitForChild("ExpansionGate"))
	end)
	if not ok or not ExpansionGate then
		return false
	end
	return ExpansionGate.AssertAiMeshBlocked() == true
end

function SpiritMeshGenerationService.CanGenerateOnline()
	if not SpiritMeshGenerationService.OnlineEnabled then
		return false, "OnlineEnabled=false"
	end
	if not gateAllows() then
		return false, "ExpansionGate.AllowAiMeshOnline=false"
	end
	return true, "ok"
end

function SpiritMeshGenerationService.GenerateAsync(_spiritRow)
	local ok, reason = SpiritMeshGenerationService.CanGenerateOnline()
	if not ok then
		warn("[SpiritMeshGenerationService] blocked:", reason)
		return nil, reason
	end
	return nil, "not_implemented_until_Q4_unfreeze"
end

return SpiritMeshGenerationService
