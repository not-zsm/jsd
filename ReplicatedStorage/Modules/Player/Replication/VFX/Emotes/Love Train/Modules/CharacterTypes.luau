export type Head = BasePart & {
	FaceCenterAttachment: Attachment,
	FaceFrontAttachment: Attachment,
	HairAttachment: Attachment,
	HatAttachment: Attachment,
	Mesh: SpecialMesh,
}

export type Torso = BasePart & {
	BodyBackAttachment: Attachment,
	BodyFrontAttachment: Attachment,
	LeftCollarAttachment: Attachment,
	["Left Hip"]: Motor6D,
	["Left Shoulder"]: Motor6D,
	Neck: Motor6D,
	NeckAttachment: Attachment,
	RightCollarAttachment: Attachment,
	["Right Hip"]: Motor6D,
	["Right Shoulder"]: Motor6D,
	WaistBackAttachment: Attachment,
	WaistCenterAttachment: Attachment,
	WaistFrontAttachment: Attachment,
}

export type InternalHumanoid = Humanoid & {
	Animator: Animator,
	HumanoidDescription: HumanoidDescription,
	Status: Status
}

export type RootPart = BasePart & {
	RootAttachment: Attachment,
	RootJoint: Motor6D
}

export type LeftArm = BasePart & {
	LeftGripAttachment: Attachment,
	LeftShoulderAttachment: Attachment
}

export type LeftLeg =  BasePart & {
	LeftFootAttachment: Attachment
}

export type RightArm = BasePart & {
	RightGripAttachment: Attachment,
	RightShoulderAttachment: Attachment
}

export type RightLeg = BasePart & {
	RightFootAttachment: Attachment
}

export type Character = Model & {
	["Body Colors"]: BodyColors?,
	Pants: Pants?,
	Shirt: Shirt?,
	["Shirt Graphic"]: ShirtGraphic?,
	Head: Head,
	Humanoid: InternalHumanoid,
	HumanoidRootPart: RootPart,
	["Left Arm"]: LeftArm,
	["Left Leg"]: LeftLeg,
	["Right Arm"]: RightArm,
	["Right Leg"]:RightLeg,
	Torso: Torso,
}

return nil