-- ProfileServiceAdapter (Q4): migration shim over DataStoreManager
-- Does NOT replace live saves yet — opt-in via UseProfileServiceAdapter on SSS.RealmOfSpirits

local ProfileServiceAdapter = {}

ProfileServiceAdapter.Enabled = false
ProfileServiceAdapter.StoreName = "RealmOfSpirits_Profiles_v1"
ProfileServiceAdapter.MigrateFromKeyPrefix = "Player_"

function ProfileServiceAdapter.GetStatus()
	return {
		Enabled = ProfileServiceAdapter.Enabled,
		StoreName = ProfileServiceAdapter.StoreName,
		Note = "Stub 2026-08-15: keep DataStoreManager UpdateAsync until Q4 cutover",
	}
end

function ProfileServiceAdapter.ShouldUse()
	local sss = game:GetService("ServerScriptService"):FindFirstChild("RealmOfSpirits")
	if not sss then
		return false
	end
	return sss:GetAttribute("UseProfileServiceAdapter") == true and ProfileServiceAdapter.Enabled
end

function ProfileServiceAdapter.LoadPlayerData(_userId)
	return nil
end

function ProfileServiceAdapter.SavePlayerData(_userId, _data)
	return false
end

return ProfileServiceAdapter
