extends Node
class_name Ads
## Заглушки под AdMob. После экспорта подключите плагин:
## https://github.com/Poing-Studios/godot-admob-plugin
## App ID / banner / interstitial / rewarded unit IDs — в AdMob console.

const APP_ID := "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
const BANNER_ID := "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const INTERSTITIAL_ID := "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const REWARDED_ID := "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"

static func show_banner() -> void:
	print("[Ads] banner ", BANNER_ID)


static func hide_banner() -> void:
	print("[Ads] hide banner")


static func show_interstitial() -> void:
	print("[Ads] interstitial ", INTERSTITIAL_ID)


static func show_rewarded(on_reward: Callable) -> void:
	print("[Ads] rewarded ", REWARDED_ID)
	on_reward.call()
