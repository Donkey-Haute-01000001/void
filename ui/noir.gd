class_name Noir
## Shared look for the UI: Sin City palette (black, white, greys and one red).
## Art deco only on big headlines; everything you read is in plain fonts.

const INK := Color("#060606")
const PAPER := Color("#ededed")
const DIM := Color("#8a8a8a")
## Highlights and emphasis: plain white, so the red stays rare.
const ACCENT := Color("#ffffff")
## The one colour: blood, danger, and words that matter.
const BLOOD := Color("#d01e2a")
const STEEL := Color("#a8a8a8")
const SANITY := Color("#c8c8c8")

## Big headlines only: names on cards, check results, end titles.
const DISPLAY_FONT := preload("res://art/fonts/Limelight-Regular.ttf")
## Labels, names over speech, HUD.
const TITLE_FONT := preload("res://art/fonts/BebasNeue-Regular.ttf")
const NARRATOR_FONT := preload("res://art/fonts/SpecialElite-Regular.ttf")
const SPEECH_FONT := preload("res://art/fonts/CourierPrime-Bold.ttf")
const BODY_FONT := preload("res://art/fonts/CourierPrime-Regular.ttf")
## Inner voices: italic, so they never read as spoken aloud.
const VOICE_FONT := preload("res://art/fonts/CourierPrime-Italic.ttf")

## Name-tag colour for each speaker.
const SPEAKER_COLORS := {"adrian": ACCENT, "tom": STEEL}
const SPEAKER_NAMES := {"adrian": "VALE", "tom": "GARRITY"}


static func box(bg := Color(0.02, 0.02, 0.03, 0.92), border := Color(1, 1, 1, 0.14), pad := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_content_margin_all(pad)
	return s


static func label(text: String, font: Font, size: int, color := PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func rich(font: Font, size: int, color := PAPER) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", font)
	r.add_theme_font_override("bold_font", TITLE_FONT)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	return r
