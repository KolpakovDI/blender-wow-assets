-- ProfileServiceAdapter (Q4): migration shim — BLOCKED by ExpansionGate until Q4 unlock

local ProfileServiceAdapter = {}

ProfileServiceAdapter.Enabled = false -- hard default; never flip without ExpansionGate
ProfileServiceAdapter.StoreName = "RealmOfSpirits_Profiles_v1"
ProfileServiceAdapter.MigrateFromKeyPrefix = "Player_"

local function gateAllows()
	local ok, ExpansionGate = pcall(function()
		return require(game:GetService("ReplicatedStorage").RealmOfSpirits:WaitForChild("ExpansionGate"))
	end)
	if not ok or not ExpansionGate then
		return false
	end
	return ExpansionGate.AssertProfileServiceBlocked() == true
end

function ProfileServiceAdapter.GetStatus()
	return {
		Enabled = ProfileServiceAdapter.Enabled,
		GateAllows = gateAllows(),
		StoreName = ProfileServiceAdapter.StoreName,
		Note = "Blocked until ExpansionGate.AllowProfileService + Enabled — keep DataStoreManager",
	}
end

function ProfileServiceAdapter.ShouldUse()
	if not ProfileServiceAdapter.Enabled then
		return false
	end
	if not gateAllows() then
		warn("[ProfileServiceAdapter] blocked by ExpansionGate (AllowProfileService=false)")
		return false
	end
	local sss = game:GetService("ServerScriptService"):FindFirstChild("RealmOfSpirits")
	if not sss then
		return false
	end
	return sss:GetAttribute("UseProfileServiceAdapter") == true
end

function ProfileServiceAdapter.LoadPlayerData(_userId)
	if not ProfileServiceAdapter.ShouldUse() then
		return nil
	end
	warn("[ProfileServiceAdapter] Load not implemented — use DataStoreManager")
	return nil
end

function ProfileServiceAdapter.SavePlayerData(_userId, _data)
	if not ProfileServiceAdapter.ShouldUse() then
		return false
	end
	warn("[ProfileServiceAdapter] Save not implemented — use DataStoreManager")
	return false
end

return ProfileServiceAdapter
