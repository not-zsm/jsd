return [[
This block will loop back to the block 'Previous' steps back.

<b><font color='rgb(221,155,155)'>Previous</font></b>
This specifies how many steps back it should loop back to.

<b><font color='rgb(221,155,155)'>Max Loops</font></b>
The maximum number of times this block can loop back. Set to '-1' for no limit.

<b><font color='rgb(221,155,155)'>Min Loops</font></b>
The minimum number of loops needed before the loop can exit.
The loop will exit on the minimum loop at the loop block (even if Immediate Exit is checked) if any loop condition was met before this value is reached.

<b><font color='rgb(221,155,155)'>Immediate Exit</font></b>
Controls whether the current running block will immediately stop and move onto the block after this loop block, when the conditions are met.
If unchecked, then the loop can only exit when the loop block is reached again.

<b><font color='rgb(221,155,155)'>Until Pressed Again</font></b>
When enabled, determines if this loop will exit if the skill is activated again while inside the loop.

<b><font color='rgb(221,155,155)'>Until Time Elapsed</font></b>
When enabled, determines how long the loop can last for (in seconds) before exiting.

<b><font color='rgb(221,155,155)'>Until Awakening In Range</font></b>
When enabled, determines what percentage range your ultimate bar should be in the range of before exiting.
For example, set this value to <i>'100, 100'</i> to make the loop exit only when you have full ultimate bar.

<b><font color='rgb(221,155,155)'>Until Health In Range</font></b>
When enabled, determines what your health should be in the range of before exiting.
For example, set this value to <i>'100, 100'</i> to make the loop exit only when you have full health.
]]