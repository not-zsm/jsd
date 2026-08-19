return [[
This block will cancel (or branch) if damage was not dealt within last period of time.
<font color='rgb(255,215,215)'>Recommended to instead use <b>Hit Detect</b> as it offers more functionality.</font>

<b><font color='rgb(221,155,155)'>Inverted</font></b>
Whether the block should activate is damage was dealt instead.

<b><font color='rgb(221,155,155)'>Time</font></b>
The length of time that damage can be traced back to.

<b><font color='rgb(221,155,155)'>Endlag</font></b>
The endlag given to the user (time where after you cannot attack) if this block is activated.

<b><font color='rgb(221,155,155)'>Branch To</font></b>
When checked, will jump to the branch specified when the block is activated.
]]

--[[
<b><font color='rgb(221,155,155)'>Hit Branch To</font></b>
If the skill deals damage to a target, for each target hit, a new branch will be <b>spawned</b> that acts upon the target.
This is <font color='rgb(255,211,78)'><b>different</b></font> from the usual Branch To, as it <b>does not yield</b> your custom skill and runs seperately on for each target.
]]