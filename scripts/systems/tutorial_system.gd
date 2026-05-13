extends Node

signal tutorial_step_changed(step_index: int, step_data: Dictionary)
signal tutorial_completed
signal tutorial_started

var tutorial_steps: Array[Dictionary] = [
	{
		"title": "欢迎来到背刺拍卖会！",
		"description": "这是一款以拍卖竞价为核心的策略卡牌游戏。\n\n信任是奢侈品，背叛是常态。\n\n在30轮拍卖中，你将与其他AI玩家竞价物品，使用技能，进行黑市交易，最终成为最富有的玩家。",
		"highlight": "",
		"wait_for": ""
	},
	{
		"title": "拍卖系统",
		"description": "每轮会展示一件拍卖物品，包含名称、稀有度和起拍价。\n\n注意：物品的品相（真实价值）在拍卖结束后才会揭晓！\n\n• 珍品：价值x2（极稀有）\n• 完美：价值x1\n• 瑕疵：价值x0.8\n• 破损：价值x0.5\n• 赝品：价值x0.05（几乎不值钱）",
		"highlight": "ItemPanel",
		"wait_for": "round_started"
	},
	{
		"title": "出价系统",
		"description": "点击出价按钮来竞价：\n\n• +10：小幅加价\n• +30：中幅加价\n• +50：大幅加价\n\n当前最高出价会显示在物品面板中。\n\n注意：不要盲目追高！赝品会让你血本无归。",
		"highlight": "ActionPanel",
		"wait_for": "bid_placed"
	},
	{
		"title": "身份系统",
		"description": "每局开始，你会随机获得一个身份。\n\n你的身份决定了你可以使用的技能。其他玩家的身份是隐藏的！\n\n8种身份：商人、欺诈者、贵族、刺客、守护者、战士、猎人、法师\n\n通过观察对手的行为，推测他们的身份。",
		"highlight": "PlayersList",
		"wait_for": ""
	},
	{
		"title": "技能系统",
		"description": "每个身份拥有独特的技能：\n\n• 背刺：偷取最高出价者10%金币（免费）\n• 护盾：免疫攻击（50金币）\n• 冲刺：立即结束拍卖（30金币）\n• 透视：偷看下一件物品（40金币）\n• 破坏：让目标无法出价（60金币）\n• 祝福：出价减少20%（35金币）\n• 巧舌如簧：降低目标出价意愿（40金币）\n• 暗杀：淘汰目标（200金币，仅一次）\n\n技能使用时不暴露你的身份！",
		"highlight": "SkillButtons",
		"wait_for": "skill_used"
	},
	{
		"title": "黑市交易",
		"description": "每3轮拍卖后，进入黑市交易阶段。\n\nAI玩家可能向你发起交易，你也可以接受、拒绝或背叛！\n\n• 接受：双方按约定交换金币\n• 背叛：拿走对方的钱，不给自己的（双倍收益！）\n• 拒绝：交易取消\n\n但记住，背叛的代价可能是失去信任...",
		"highlight": "",
		"wait_for": "trade_initiated"
	},
	{
		"title": "借贷系统",
		"description": "资金不足？可以借钱！\n\n点击"借钱"按钮借入100金币。\n\n⚠️ 注意：\n• 每轮利息15%（复利计算）\n• 欠款上限500金币\n• 超过上限会强制拍卖你的物品还债\n\n借钱要谨慎，利息会快速累积！",
		"highlight": "LoanButton",
		"wait_for": "loan_taken"
	},
	{
		"title": "密封拍卖",
		"description": "每5轮触发一次密封拍卖！\n\n• 所有人同时秘密出价\n• 只有一次机会\n• 出价最高者获胜\n• 未获胜者不扣钱\n\n策略：不要出价过高，因为未获胜不扣钱！",
		"highlight": "SealedBidPanel",
		"wait_for": "sealed_bids_ready"
	},
	{
		"title": "随机事件",
		"description": "每轮有30%概率触发随机事件：\n\n• 通货膨胀：所有出价+20%\n• 经济萧条：所有出价-20%\n• 混乱时刻：计时器随机变化\n• 双倍收益：物品价值翻倍\n• 黑暗交易：偷看下一个物品\n• 狂热竞拍：AI更激进\n• 冷静期：AI更保守\n\n利用事件来获得优势！",
		"highlight": "",
		"wait_for": ""
	},
	{
		"title": "游戏目标",
		"description": "在30轮拍卖中，通过竞价、使用技能、心理博弈获取最多财富。\n\n最终净资产 = 金币 + 物品实际价值 - 欠款\n\n净资产最高的玩家获胜！\n\n当所有其他玩家被淘汰时，最后幸存者直接获胜。\n\n祝你好运，拍卖师！",
		"highlight": "",
		"wait_for": ""
	}
]

var current_step: int = -1
var is_active: bool = false
var tutorial_enabled: bool = true

func _ready() -> void:
	_load_tutorial_state()
	if tutorial_enabled and current_step < 0:
		current_step = 0

func _load_tutorial_state() -> void:
	var save_file = "user://tutorial.dat"
	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if data:
				current_step = data.get("current_step", -1)
				tutorial_enabled = data.get("enabled", true)
			file.close()

func _save_tutorial_state() -> void:
	var save_file = "user://tutorial.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		var data = {"current_step": current_step, "enabled": tutorial_enabled}
		file.store_string(JSON.stringify(data))
		file.close()

func start_tutorial() -> void:
	current_step = 0
	is_active = true
	tutorial_enabled = true
	tutorial_started.emit()
	_show_current_step()
	_save_tutorial_state()

func next_step() -> void:
	if current_step < tutorial_steps.size() - 1:
		current_step += 1
		_show_current_step()
	else:
		complete_tutorial()

func skip_tutorial() -> void:
	complete_tutorial()

func complete_tutorial() -> void:
	is_active = false
	current_step = tutorial_steps.size()
	tutorial_completed.emit()
	_save_tutorial_state()

func disable_tutorial() -> void:
	tutorial_enabled = false
	complete_tutorial()
	_save_tutorial_state()

func enable_tutorial() -> void:
	tutorial_enabled = true
	current_step = 0
	is_active = true
	_save_tutorial_state()

func reset_tutorial() -> void:
	current_step = -1
	tutorial_enabled = true
	is_active = false
	_save_tutorial_state()

func _show_current_step() -> void:
	if current_step >= 0 and current_step < tutorial_steps.size():
		var step = tutorial_steps[current_step]
		tutorial_step_changed.emit(current_step, step)

func get_current_step_data() -> Dictionary:
	if current_step >= 0 and current_step < tutorial_steps.size():
		return tutorial_steps[current_step]
	return {}

func get_progress() -> Dictionary:
	return {
		"current": current_step,
		"total": tutorial_steps.size(),
		"completed": current_step >= tutorial_steps.size(),
		"enabled": tutorial_enabled
	}

func is_tutorial_active() -> bool:
	return is_active and tutorial_enabled and current_step >= 0 and current_step < tutorial_steps.size()
