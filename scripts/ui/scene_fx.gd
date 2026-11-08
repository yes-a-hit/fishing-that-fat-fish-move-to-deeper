class_name SceneFx
extends RefCounted
## 场景里用的几张小贴图，运行时画一次、全局共用。
##
## 放在 core 之外、ui 之下：只产出纹理，不认识任何界面。
## 谁要谁调，第一次调用生成，之后拿缓存。

static var _shadow: Texture2D = null
static var _ripple: Texture2D = null


## 椭圆软阴影：站在地上的人脚下垫一张。
static func shadow() -> Texture2D:
	if _shadow != null:
		return _shadow
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 128:
			var dx := (x - 64.0) / 64.0
			var dy := (y - 32.0) / 32.0
			var a := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a * a))
	_shadow = ImageTexture.create_from_image(img)
	return _shadow


## 水面涟漪：中间淡、边缘亮一点。
static func ripple() -> Texture2D:
	if _ripple != null:
		return _ripple
	var img := Image.create(160, 56, false, Image.FORMAT_RGBA8)
	for y in 56:
		for x in 160:
			var dx := (x - 80.0) / 80.0
			var dy := (y - 28.0) / 28.0
			var d := sqrt(dx * dx + dy * dy)
			if d > 1.0:
				continue
			img.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - d, 0.0, 1.0), 1.6) * 0.55))
	_ripple = ImageTexture.create_from_image(img)
	return _ripple
