return [[
This is an advanced block that allows you to use build mode's modifiers within your custom skill.

<b><font color='rgb(221,155,155)'>Save Part</font></b>
The instance that will be saved (and its descendants) to be pulsed/powered to when this block is activated.
Recommended to be a part, as the part will be pulsed/powered with your humanoid.

<b><font color='rgb(221,155,155)'>Use Cache</font></b>
Whether the same saved part will be used again when this block is activated, if enabled - only a single part is used.
If this is enabled, <b>Lifetime</b> will have <b>no</b> effect.
<font color='rgb(255,215,215)'>Recommended to disable for most general compatibility.</font>

<b><font color='rgb(221,155,155)'>Always Update Position</font></b>
Whether the part will update to its positional offset every frame for the duration of <b>Power Duration</b>.

<b><font color='rgb(221,155,155)'>Cancellable</font></b>
Whether this block is cancellable.

<b><font color='rgb(221,155,155)'>Power Duration</font></b>
The duration for which the saved part will be powered on for. If set to zero, a pulse will instead be made to the saved part.

<b><font color='rgb(221,155,155)'>Lifetime</font></b>
The time until the saved part will be deleted.

<b><font color='rgb(221,155,155)'>Position</font></b>
Controls the relative offset from your player character for where the part is moved to.

<b><font color='rgb(221,155,155)'>Orientation</font></b>
Controls the relative rotation from your player character for where the part is moved to.
The axes are represented in <b>degrees</b>.

<b><font color='rgb(221,155,155)'>Parent</font></b>
Sets the location of the saved part.
<b>None</b> - The parent will be nil (invisible).
<b>Storage</b> - The parent will be inside the Replicated Storage (invisible).
<b>Workspace</b> - The parent will be inside the Workspace (and therefore visible).

<b><font color='rgb(221,155,155)'>Targeting</font></b>
Controls the target that the modifier is applied to (position and humanoid pulse). If this block isn't accessed by a retargeting feature like 'Hit Branch To' of the skill block, there will be no target and this will do nothing.
]]