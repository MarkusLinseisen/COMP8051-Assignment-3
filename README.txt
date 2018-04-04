=================================================
| CONTROLS                                      |
=================================================
| Movement              | Vertical Swiping      |
| Rotation              | Horizontal Swiping    |
| Reset Position        | Double-Tap            |
| Toggle Minimap        | Two-Finger Double-Tap |
| Toggle Flashlight     | "flashlight" Button   |
| Toggle Time of Day    | "time of day" Button  |
| Toggle Fog            | "fog" Button          |
| Linear Fog            | "lin" Button          |
| Exponential Fog       | "exp" Button          |
=================================================

5.
Spotlight FOV can be changed by setting UNIFORM_SPOTLIGHTCUTOFF to cos(FOV/2).
Spotlight color can be changed by setting UNIFORM_SPOTLIGHTCOLOR.

7.
Fog defaults to exponential fog.
Fog type can be changed from linear to exponential by setting UNIFORM_FOGUSEEXP.
Exponential fog density can be changed by setting UNIFORM_FOGDENSITY.
Linear fog end can be changed by setting UNIFORM_FOGEND.
Fog color can be changed by setting UNIFORM_FOGCOLOR.

8.
If you are in the same square as the monkey, the monkey will stop moving and the “monkey menu” will be displayed.
To assume control of the monkey, tap “swap control”, tapping the button a second time will resume control of the player. When controlling the monkey, the same controls are used from the player, however, it will be relative to the position/rotation of the monkey.
To change the scale of the monkey, use the +/- scale buttons.