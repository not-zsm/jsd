return [[
This block will move your character with a velocity.

<b><font color='rgb(221,155,155)'>Push Type</font></b>
This controls the relativity of direction the velocity goes.
<b>Local</b> - <i>Push Vector</i> will be relative to your player character.
<b>Global</b> - <i>Push Vector</i> will be relative to world space.

<b><font color='rgb(221,155,155)'>Push Power</font></b>
This controls the power applied to the <i>Push Vector</i>.

<b><font color='rgb(221,155,155)'>Push Duration</font></b>
This controls how long the velocity is applied for.

<b><font color='rgb(221,155,155)'>Push Vector</font></b>
This controls the direction of the velocity relative to <i>Push Type</i>. The given vector is a direction and will be made into a unit vector - use <i>Push Power</i> to apply more power.

<b><font color='rgb(221,155,155)'>Max Force</font></b>
This controls the maximum amount of force the velocity can appy. If too low it may be overriden by velocities applied from skills, if too high it may cause flings from walls.
This value is <b>not</b> considered if <i>Push Duration</i> is 0.

<b><font color='rgb(221,155,155)'>Axes</font></b>
This value controls the per-axis max force of the velocity, this value is multiplied by <i>Max Force</i>.
This value is <b>not</b> considered if <i>Push Duration</i> is 0.

<b><font color='rgb(221,155,155)'>Ragdoll Duration</font></b>
The duration of the ragdoll, set to zero if you do not want ragdoll. 

<b><font color='rgb(221,155,155)'>Tapering</font></b>
This controls the velocity power over the course of the velocity's lifetime (<i>Push Duration</i>).

<b><font color='rgb(221,155,155)'>Aligned</font></b>
This controls whether the velocity reacts to your player character's rotation.
Has <b>no</b> effect if <i>Push Type</i> is not set to <i>Local</i>

<b><font color='rgb(221,155,155)'>Cancellable</font></b>
Whether the velocity is cancellable.

<b><font color='rgb(221,155,155)'>Targeting</font></b>
Controls the target that the velocity is applied to. If this block isn't accessed by a retargeting feature like 'Hit Branch To' of the skill block, there will be no target and this will do nothing.
]]