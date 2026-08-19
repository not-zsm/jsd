-- Manual Whitelist for Instance properties that are saveable to the datastore
-- Do not automate this for security reasons

return {
	Object = {
		"Name"
	};
	Instance = {
		"Parent"
	};
	BasePart = {
		"CFrame", "Size", "Transparency", "CastShadow", 
		"CanCollide", "Anchored", "Material", "Color",
		"MaterialVariant", "Reflectance", "Massless", "Locked"
	};
	Fire = {
		"Enabled", "Color", "Heat", "SecondaryColor", "Size", "TimeScale"
	};
	Smoke = {
		"Enabled", "Color", "Opacity", "RiseVelocity", "Size", "TimeScale";
	};
	Lighting = {
		"Ambient", "Brightness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", 
		"OutdoorAmbient", "ShadowSoftness", "ClockTime", "GeographicLatitude", "ExposureCompensation"
	};
	Clouds = {
		"Cover", "Density", "Color", "Enabled";
	};
	BloomEffect = {
		"Enabled", "Intensity", "Size", "Threshold"
	};
	Sky = {
		"CelestialBodiesShown", "SunAngularSize", "MoonAngularSize", "SunTextureId", "MoonTextureId", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SkyboxOrientation", "StarCount"
	};
	ColorCorrectionEffect = {
		"Brightness", "Contrast", "Enabled", "Saturation", "TintColor",
	};
	SunRaysEffect = {
		"Enabled", "Intensity", "Spread"
	};
	Atmosphere = {
		"Density", "Offset", "Color", "Decay", "Glare", "Haze"
	};
	Team = {
		"TeamColor", "AutoAssignable"
	};
	SpawnLocation = {
		"Neutral", "TeamColor", "AllowTeamChangeOnTouch"
	};
	VehicleSeat = {
		"Disabled", "HeadsUpDisplay", "MaxSpeed", "Steer", "SteerFloat", "Throttle", "ThrottleFloat", "Torque", "TurnSpeed";
	};
	AlignOrientation = {
		"AlignType", "CFrame", "MaxAngularVelocity", "MaxTorque", "Mode", "ReactionTorqueEnabled", "Responsiveness", "RigidityEnabled";
	};
	AlignPosition = {
		"ApplyAtCenterOfMass", "ForceLimitMode", "ForceRelativeTo", "MaxAxesForce", "MaxForce", "MaxVelocity", "Mode", "Position", "ReactionForceEnabled", "Responsiveness",
		"RigidityEnabled"
	};
	AngularVelocity = {
		"AngularVelocity", "MaxTorque", "ReactionTorqueEnabled", "RelativeTo"
	};
	HumanoidDescription = {
		"BackAccessory", "FaceAccessory", "FrontAccessory", "HairAccessory", "HatAccessory", "NeckAccessory", "ShouldersAccessory", "WaistAccessory", "HeadColor", "LeftArmColor", "LeftLegColor", "RightArmColor",
		"RightLegColor", "TorsoColor", "Face", "Head", "LeftArm", "LeftLeg", "RightArm", "RightLeg", "Torso", "GraphicTShirt", "Pants", "Shirt", "BodyTypeScale", "DepthScale", "HeadScale", "HeightScale", "ProportionScale", "WidthScale";
	};
	TremoloSoundEffect = {
		"Depth", "Duty", "Enabled", "Frequency", "Priority"
	};
	ReverbSoundEffect = {
		"DecayTime", "Density", "Diffusion", "DryLevel", "Enabled", "Priority", "WetLevel"
	};
	PitchShiftSoundEffect = {
		"Enabled", "Octave", "Priority",
	};
	FlangeSoundEffect = {
		"Depth", "Enabled", "Mix", "Priority", "Rate";
	};
	EqualizerSoundEffect = {
		"Enabled", "HighGain", "LowGain", "MidGain", "Priority",
	};
	EchoSoundEffect = {
		"Delay", "DryLevel", "Enabled", "Feedback", "Priority", "WetLevel",
	};
	DistortionSoundEffect = {
		"Enabled", "Level", "Priority"
	};
	CompressorSoundEffect = {
		"Attack", "Enabled", "GainMakeup", "Priority", "Ratio", "Release", "SideChain", "Threshold";
	};
	ChorusSoundEffect = {
		"Depth", "Enabled", "Mix", "Priority", "Rate";
	};
	UniversalConstraint = {
		"LimitsEnabled", "MaxAngle", "Radius", "Restitution"
	};
	PrismaticConstraint = {};
	CylindricalConstraint = { -- Constraint final boss (inherits from SlidingBallConstraint btw)
		"AngularActuatorType", "AngularLimitsEnabled", "AngularResponsiveness", "AngularRestitution", "AngularSpeed", "AngularVelocity",
		"InclinationAngle", "LowerAngle", "MotorMaxAngularAcceleration", "MotorMaxTorque", "RotationAxisVisible", "ServoMaxTorque", "TargetAngle",
		"UpperAngle", "WorldRotationAxis";
	};
	SlidingBallConstraint = {
		"ActuatorType", "LimitsEnabled", "LinearResponsiveness", "LowerLimit", "MotorMaxAcceleration", "MotorMaxForce", "Restitution", "ServoMaxForce",
		"Size", "Speed", "TargetPosition", "UpperLimit", "Velocity"
	};
	SpringConstraint = {
		"Coils", "Damping", "FreeLength", "LimitsEnabled", "MaxForce", "MaxLength", "MinLength", "Radius", "Stiffness", "Thickness"
	};
	PlaneConstraint = {};
	NoCollisionConstraint = {
		"Enabled", "Part0", "Part1";
	};
	RopeConstraint = {
		"Length", "Restitution", "Thickness", "WinchEnabled", "WinchForce", "WinchResponsiveness", "WinchSpeed", "WinchTarget";
	};
	Constraint = {
		"Active", "Attachment0", "Attachment1", "Color", "Enabled", "Visible"
	};
	HingeConstraint = {
		"ActuatorType", "AngularResponsiveness", "AngularSpeed", "AngularVelocity", "LimitsEnabled", "LowerAngle", 
		"MotorMaxAcceleration", "MotorMaxTorque", "Restitution", "ServoMaxTorque", "TargetAngle", "UpperAngle"
	};
	Trail = {
		"Color", "FaceCamera", "LightEmission", "LightInfluence", "Texture", "TextureLength", "TextureMode", "Transparency", "Attachment0", "Attachment1",
		"Enabled", "Lifetime", "MaxLength", "MinLength", "WidthScale";
	};
	BodyGyro = {
		"MaxTorque", "D", "P";
	};
	Part = {
		"Shape";
	};
	Light = {
		"Range", "Brightness", "Color", "Enabled", "Shadows"
	};
	SpotLight = {
		"Angle", "Face";
	};
	SurfaceLight = {
		"Angle", "Face"
	};
	Decal = {
		"Texture", "Transparency", "ZIndex", "Color3", "Face"
	};
	Texture = {
		"StudsPerTileU", "StudsPerTileV"
	};
	DataModelMesh = {
		"Offset",
		"Scale",
		"VertexColor"
	};
	MeshPart = {
		"TextureID"
	};
	SpecialMesh = {
		"MeshId", "MeshType", "TextureId"
	};
	Wire = {
		"SourceInstance", "TargetInstance";
	};
	ValueBase = {
		"Value";
	};
	Attachment = {
		"Visible";
		"CFrame";
	};
	BodyColors = {
		"HeadColor3", "TorsoColor3", "RightArmColor3", "LeftArmColor3", "RightLegColor3", "LeftLegColor3"
	};
	Clothing = {
		"Color3";
	};
	Shirt = {
		"ShirtTemplate"
	};
	Pants = {
		"PantsTemplate"
	};
	Motor6D = {};
	Motor = {
		"DesiredAngle", "MaxVelocity",
	};
	JointInstance = {
		"C0", "C1", "Enabled", "Part0", "Part1"
	};
	BallSocketConstraint = {
		"Radius";
		"LimitsEnabled";
		"MaxFrictionTorque";
		"Restitution";
		"TwistLimitsEnabled";
		"UpperAngle";
		"TwistLowerAngle";
		"TwistUpperAngle";
	};
	VectorForce = {
		"ApplyAtCenterOfMass";
		"Force";
		"RelativeTo";
	};
	LinearVelocity = {
		"VelocityConstraintMode";
		"VectorVelocity";
		"RelativeTo";
		"ForceLimitsEnabled";
		"ForceLimitMode";
		"MaxForce";
		"MaxAxesForce";
	};
	Humanoid = {
		"DisplayName", 
		"BreakJointsOnDeath", 
		"PlatformStand", 
		"Health", 
		"MaxHealth", 
		"HipHeight", 
		"MaxSlopeAngle", 
		"WalkSpeed",
		"JumpPower"
	};
	Beam = {
		"Color",
		"Enabled",
		"LightEmission",
		"LightInfluence",
		"Texture",
		"TextureLength",
		"TextureMode",
		"TextureSpeed",
		"Transparency",
		"ZOffset",
		"Attachment0",
		"Attachment1",
		"CurveSize0",
		"CurveSize1",
		"FaceCamera",
		"Segments",
		"Width0",
		"Width1"
	};
	Sound = {
		"SoundId";
		"Looped";
		"Playing";
		"PlaybackSpeed";
		"Volume";
		"RollOffMaxDistance",
		"RollOffMinDistance",
		"RollOffMode",
		"PlaybackRegionsEnabled",
		"LoopRegion",
		"PlaybackRegion",
	};
	ParticleEmitter = {
		"Color",
		"LightEmission",
		"LightInfluence",
		"Orientation",
		"Size",
		"Squash",
		"Texture",
		"Transparency",
		"ZOffset",
		"EmissionDirection",
		"Enabled",
		"Lifetime",
		"Rate",
		"Rotation",
		"RotSpeed",
		"Speed",
		"SpreadAngle",
		"Acceleration",
		"Drag",
		"LockedToPart",
		"TimeScale",
		"VelocityInheritance",
		"FlipbookLayout",
		"FlipbookFramerate",
		"FlipbookMode",
		"FlipbookStartRandom",
		"Brightness"
	};
	WeldConstraint = {
		"Enabled";
		"Part0";
		"Part1";
	};
	Rotate = {
		"Enabled";
		"Part0";
		"Part1";
		"C0";
		"C1";
	};
	Weld = {
		"Enabled";
		"Part0";
		"Part1";
		"C0";
		"C1";
	};
	ManualWeld = {
		"Enabled";
		"Part0";
		"Part1";
		"C0";
		"C1";
	};
	Snap = {
		"Enabled";
		"Part0";
		"Part1";
		"C0";
		"C1";
	};
	ProximityPrompt = {
		"Enabled",
		"RequiresLineOfSight",
		"ActionText",
		"ObjectText",
		"HoldDuration",
		"KeyboardKeyCode",
		"MaxActivationDistance",
		"GamepadKeyCode",
		"ClickablePrompt",
		"Exclusivity",
		"Style",
		"UIOffset"
	};
}