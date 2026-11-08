class_name ChapterRouter
extends RefCounted
## 全游戏**唯一**知道「哪个场景叫什么」的地方。
##
## 别处一律写 `ChapterRouter.to_shore(self)`，不许再自己拼路径、也不许自己判断
## 「通关了该去哪」——那个判断只有 `chapter_of()` 一处。
##
## 铁律：跳场景只在这里发生。

const MENU := "res://menu.tscn"
const SHORE := "res://shore.tscn"      # 第一章 hub：岸边
const GAME := "res://main.tscn"        # 第一章本体：抛竿打鱼
const DIVE := "res://scenes/dive.tscn" # 第二章：港口
const GALLERY := "res://gallery.tscn"
const SETTINGS := "res://settings.tscn"
const ABOUT := "res://about.tscn"
const CONTACTS := "res://contacts.tscn"
const SAVES := "res://saves.tscn"


## 通用跳转。node 只用来拿 SceneTree，不必是场景根。
static func go(node: Node, target: String) -> void:
	if node == null or not node.is_inside_tree():
		return
	node.get_tree().change_scene_to_file(target)


## 「最远走到哪」——单向流程的唯一判断点。
## 已通关第一章 → 港口；否则 → 岸边。
static func chapter_of(progress: Progress) -> String:
	return DIVE if SaveSchema.chapter1_cleared(progress) else SHORE


static func to_menu(node: Node) -> void: go(node, MENU)
static func to_shore(node: Node) -> void: go(node, SHORE)
static func to_game(node: Node) -> void: go(node, GAME)
static func to_dive(node: Node) -> void: go(node, DIVE)
static func to_gallery(node: Node) -> void: go(node, GALLERY)
static func to_settings(node: Node) -> void: go(node, SETTINGS)
static func to_about(node: Node) -> void: go(node, ABOUT)
static func to_contacts(node: Node) -> void: go(node, CONTACTS)
static func to_saves(node: Node) -> void: go(node, SAVES)
