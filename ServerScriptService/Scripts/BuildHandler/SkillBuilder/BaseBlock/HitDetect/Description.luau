return [[
This block will detect hits made by the latest previous skill used.

<b><font color='rgb(221,155,155)'>Duration</font></b>
How long it should detect for before ending the hit detection in seconds.

<b><font color='rgb(221,155,155)'>Delay</font></b>
The delay for when your branching or cancelling happens when the previous skill hits a target.

<b><font color='rgb(221,155,155)'>Max Hits</font></b>
The maximum number of hits that can be before hit detection begins ignoring hits.

<b><font color='rgb(221,155,155)'>Cancels</font></b>
Whether the latest previous skill should cancel when a target is hit.

<b><font color='rgb(221,155,155)'>Cancel All On End</font></b>
Whether your custom skill will cancel if duration has passed, or the previous skill has ended (if duration is not above zero) - and no hits were made.

<b><font color='rgb(221,155,155)'>Blocked</font></b>
When enabled, checks if the target was blocking or not.
If left unchecked, hit detection will hit regardless of block.

<b><font color='rgb(221,155,155)'>Ragdolled</font></b>
When enabled, checks if the target is ragdolled or not.

<b><font color='rgb(221,155,155)'>Health In Range</font></b>
When enabled, checks if the target's health is within the range provided.

<b><font color='rgb(221,155,155)'>Hit Branch To</font></b>
When checked, for each target hit, a new branch will be <b>spawned</b> that acts upon the target.
This is <font color='rgb(212,118,118)'><b>different</b></font> from the usual Branch To, as it <b>does not yield</b> your custom skill and runs seperately on for each target.
If your hit branch has additional branching behaviour, or cancels certain things, it may unusally affect your skill if its still active.

<b><font color='rgb(221,155,155)'>Branch To</font></b>
When checked, the skill will jump to the branch specified when a target is hit.
]]

--[[
<b><font color='rgb(221,155,155)'>Hit Branch To</font></b>
If the skill deals damage to a target, for each target hit, a new branch will be <b>spawned</b> that acts upon the target.
This is <font color='rgb(255,211,78)'><b>different</b></font> from the usual Branch To, as it <b>does not yield</b> your custom skill and runs seperately on for each target.
]]