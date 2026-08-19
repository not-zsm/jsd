return [[
This block will trigger a skill that you <b>have access to</b>.
If you use a skill that another person does <b>not</b> have access to, then they will not be able to activate this block, and will cause your custom skill to not function as intended.
An example is if you use a skill from <i>Chara's</i> Moveset, and if the other player hasn't unlocked <i>Chara</i> yet and obtains your custom skill, the skill from the moveset will not work for them.

<b><font color='rgb(221,155,155)'>Skill List</font></b>
This is a list of of all the skills you can use. Click any one to choose.

<b><font color='rgb(221,155,155)'>Speed</font></b>
This controls the animation speed of the skill, and therefore the overall speed of the skill. 
This value does <b>not</b> affect endlag.

<b><font color='rgb(221,155,155)'>Damage Multiplier</font></b>
This value will be multiplied on top of the base damage of the skill.

<b><font color='rgb(221,155,155)'>Ragdoll Multiplier</font></b>
If the skill does any ragdolls, then this value will be multiplied on top of the base ragdoll duration of the skill.
Does <b>not</b> affect backrolls or pushbacks.

<b><font color='rgb(221,155,155)'>Knockback Multiplier</font></b>
This value will be multiplied on top of the magnitude of knockbacks applied from the skill.

<b><font color='rgb(221,155,155)'>Stun Multiplier</font></b>
This value will be multiplied on top of the base stun (or true stun) of the skill.

<b><font color='rgb(221,155,155)'>Animated</font></b>
Controls whether the skill will use its default animation. Leave unchecked and use an Animation block to make your own custom animation.

<b><font color='rgb(221,155,155)'>Visual Scripts</font></b>
Controls if client callbacks and effects are ran. Leaving this unchecked will disable most visual effects, velocities, and sound effects created by this skill.

<b><font color='rgb(221,155,155)'>Sound Effects</font></b>
Controls whether dedicated sound effects are enabled. Having this checked will disable any sound effects not covered by visual scripts. (usually voice SFX)

<b><font color='rgb(221,155,155)'>Concurrent</font></b>
Controls whether the skill will yield to let itself complete before moving on to the next block.

<b><font color='rgb(221,155,155)'>Finishers</font></b>
Controls whether finishers will activate when a victim is hit by the skill and they are low enough.

<b><font color='rgb(221,155,155)'>Cancel Previous</font></b>
Controls whether the previous skill will be cancelled. This will only affect the last skill block that was activated.

<b><font color='rgb(221,155,155)'>Auto-Variants</font></b>
Controls whether the default variant checking will be used for this skill. 
For example, if the skill has a variant that activates only when space is held, then it will trigger if this value is checked.

<b><font color='rgb(221,155,155)'>Force Variant</font></b>
If checked will forcefully use the variant of this skill, usually the space-held variant of the skill.

<b><font color='rgb(221,155,155)'>Force Special Variant</font></b>
If checked will forcefully use the special variant of this skill, this is used when a skill has more than two variants, for example: Leviathan Rush.

<b><font color='rgb(221,155,155)'>Cancellable</font></b>
Controls whether the skill is cancellable.
]]

--[[
<b><font color='rgb(221,155,155)'>Hit Branch To</font></b>
If the skill deals damage to a target, for each target hit, a new branch will be <b>spawned</b> that acts upon the target.
This is <font color='rgb(255,211,78)'><b>different</b></font> from the usual Branch To, as it <b>does not yield</b> your custom skill and runs seperately on for each target.
]]