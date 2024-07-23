class_name Mortar
extends StaticBody3D


func _ready():
    if self.has_user_signal("interacted"):
       connect("interacted", Callable(self, "use_mortar"))
    else:
        printerr("Mortar has no interacted signal")


func use_mortar():
    if GameManager.player.ingredient_in_hand:
        pass
    print("Mortar used")