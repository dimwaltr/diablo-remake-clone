extends Area2D

# A villám repülési sebessége (pixel/másodperc)
@export var speed := 500.0

# A lövedék mozgási iránya (ezt a Player.gd számolja ki és adja át kilövéskor)
var direction := Vector2.ZERO

# Biztonsági kapcsoló: megakadályozza, hogy a villám egy képkocka alatt többször is sebezzen
var has_hit := false 

# Beolvassuk a lövedékhez tartozó animációt és a térbeli (2D) hangot a fáról
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_lightning: AudioStreamPlayer2D = $SfxLightning

# A lövedék megszületésekor (kilövésekor) lefutó kezdőfüggvény
func _ready() -> void:
	# Összekötjük a Godot beépített ütközésfigyelőjét a saját függvényünkkel
	body_entered.connect(_on_body_entered)
	
	# Biztonsági fal: Ha az irány valamiért nulla (pl. indításkori fantom-töltés), leállítjuk
	if direction == Vector2.ZERO:
		return
		
	# Azonnal elindítjuk a cikázó kék villám animációt
	if is_instance_valid(sprite):
		sprite.play("lightning_csapas")
	
	# Kézzel indítjuk el a hangot a lövés pillanatában, így indításkor nem fog feleslegesen szólni
	if is_instance_valid(sfx_lightning):
		sfx_lightning.play()
			
	# Időzítő: Ha a villám 2 másodpercig nem talált el semmit (pl. kirepült a pályáról), töröljük
	await get_tree().create_timer(2.0).timeout
	destroy_lightning()

# A fizikai motor minden képkockában meghívja ezt a mozgáshoz
func _physics_process(delta: float) -> void:
	# Amíg a villám nem ütközött semmibe, folyamatosan visszük előre az irány és a sebesség alapján
	if not has_hit:
		position += direction * speed * delta

# Ez a függvény fut le abban a tizedmásodpercben, amikor a villám fizikailag hozzáér valamihez
func _on_body_entered(body: Node2D) -> void:
	# Ha már egyszer eltaláltunk valamit, nem sebezhetünk újra
	if has_hit: return
	
	# Megvizsgáljuk, hogy az eltalált objektumnak (pl. az Enemy-nek) van-e take_damage függvénye
	if body.has_method("take_damage"):
		has_hit = true
		
		# === 👑 DIABLO 1 STÍLUSÚ DINAMIKUS VILLÁMSEBZÉS SZÁMÍTÁS ===
		# Közvetlenül leolvassuk a GlobalData-ból a Magic (Mágia) szintet.
		# (Ha nálad a GlobalData-ban nem stat_magic a neve, hanem simán magic, 
		# akkor írd át a pont után arra! pl. GlobalData.magic)
		var magic_szint = GlobalData.stat_magic
		
		# Kiszámoljuk a Diablo 1 stílusú határokat (Alap: 1-20 + Magic szint)
		# Minden egyes Magic tulajdonság pont +1-gyel emeli mindkét határt!
		var min_damage = 1 + magic_szint
		var max_damage = 20 + magic_szint
		
		# Véletlenszerű sebzést sorsolunk a megemelt határok között
		var random_damage = randi_range(min_damage, max_damage)
		
		# Átadjuk a kiszámolt sebzést a szörnynek, ami levonja a saját HP-jából
		body.take_damage(random_damage)
		
		# KÖTELEZŐ KIÍRÁS: Megjeleníti az adatokat és a növekedést az alsó Output panelen
		print("--------------------------------------------------")
		print("[SPELL_DEBUG] SIKERES VILLÁM TALÁLAT!")
		print("[SPELL_DEBUG] Aktuális Magic szinted: ", magic_szint)
		print("[SPELL_DEBUG] Sebzési határaid most: ", min_damage, " és ", max_damage, " között.")
		print("[SPELL_DEBUG] Ebből kisorsolt aktuális sebzés: ", random_damage)
		print("--------------------------------------------------")
		
	# Bármibe is ütközött a villám (szörny vagy szilárd kőfal), megindítjuk a takarítást
	destroy_lightning()

# === JAVÍTOTT MEGSEMMISÍTÉS: MEGŐRIZZÜK A HANGOT ===
func destroy_lightning() -> void:
	# Biztosítjuk, hogy a logikai folyamatok leálljanak
	has_hit = true
	
	# Elrejtjük a villámot és kikapcsoljuk az ütközéseket, hogy vizuálisan már ne látszódjon a képernyőn
	visible = false
	monitoring = false
	monitorable = false
	
	# Diablo-trükk: Ha a villám dörgés hangja még játszódik, megvárjuk, amíg teljesen lecseng,
	# különben a queue_free() csúnyán elvágná a hangfájlt a becsapódás pillanatában!
	if is_instance_valid(sfx_lightning) and sfx_lightning.playing:
		await sfx_lightning.finished
		
	# Ha a hang is végigért, teljesen kitöröljük a villám lövedéket a számítógép memóriájából
	queue_free()
