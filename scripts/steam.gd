extends RefCounted
## Optional Steam layer. Active only when the GodotSteam extension is installed
## (see docs/SHIPPING.md); otherwise every call is a safe no-op, so mobile and
## dev builds are unaffected.


static func available() -> bool:
	return Engine.has_singleton("Steam")


static func start() -> void:
	if available():
		Engine.get_singleton("Steam").steamInitEx(false)


## Achievement API names mirror unlock ids, e.g. ACH_HATTRICK, ACH_ARMY_MERCHANT, ACH_WIN.
static func achieve(id: String) -> void:
	if not available():
		return
	var steam = Engine.get_singleton("Steam")
	steam.setAchievement("ACH_" + id.replace("army:", "ARMY_").to_upper())
	steam.storeStats()
