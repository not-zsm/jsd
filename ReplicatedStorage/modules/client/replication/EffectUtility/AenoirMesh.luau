--!strict
-- mesh emit module that uses model pivoting without cloning

local replicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Rnd = Random.new();

----------------------------------------------------------------------------------------------

export type SourceModel = typeof(script.SourceModel);
export type SourceFinish = typeof(script.SourceModel["End"]);
export type SourceStart = typeof(script.SourceModel["Start"]);

export type MeshInfo = {
	Duration: number;
	Decal_EndTransparency: number;
	Decal_StartTransparency: number;
	Mesh_EndTransparency: number;
	Mesh_StartTransparency: number;
	
	Decal_TweenParams: string;
	Mesh_TweenParams: string;
	Part_TweenParams: string;
	
	EmitDuration: number?;
	Rate: number?;
	
	Random: boolean;
};

export type ClassMeshEmitter = {
	__index: ClassMeshEmitter;

	new: (source: SourceModel, info: MeshInfo?) -> MeshEmitter;
	destroy: (self: MeshEmitter) -> ();
	get_tween_info: (duration: number?, params: string?) -> TweenInfo;
	emit: (self: MeshEmitter, adornee: PVInstance | Attachment) -> ();
	emit_particle: (self: MeshEmitter, coordinate: CFrame) -> ();
};

export type MeshEmitter = typeof(setmetatable({} :: {
	
	source: SourceModel;
	start: SourceStart;
	finish: SourceFinish;
	
	info: MeshInfo;
	
}, {} :: ClassMeshEmitter));

----------------------------------------------------------------------------------------------

local MeshEmitter = {} :: ClassMeshEmitter;
MeshEmitter.__index = MeshEmitter;

function MeshEmitter.new(source, info): MeshEmitter
	if not info then
		info = source:GetAttributes();
	end;
	
	local self = setmetatable(
		{
			source = source;

			finish = source["End"];
			start = source["Start"];

			info = info :: MeshInfo;
		}, 
		MeshEmitter);
	
	return self;
end;

function MeshEmitter:destroy()
	table.clear(self :: any);
	setmetatable(self :: any, nil);
end

function MeshEmitter.get_tween_info(duration, params): TweenInfo
	local Split = string.split( params or "" , "," );
	local EasingStyle = Enum.EasingStyle:FromName( Split[1] or "" );
	local EasingDirection = Enum.EasingDirection:FromName( Split[2] or "" );
	
	return TweenInfo.new(
		duration or 1, 
		EasingStyle or Enum.EasingStyle.Quad, 
		EasingDirection or Enum.EasingDirection.Out
	);
end

local function get_cframe(adornee: PVInstance | Attachment): CFrame
	return if adornee:IsA("PVInstance") then adornee:GetPivot() else adornee.WorldCFrame;
end;

function MeshEmitter:emit(adornee)
	task.spawn(self.emit_particle, self, get_cframe(adornee));
	
	if self.info.EmitDuration and self.info.EmitDuration > 0 and self.info.Rate then
		local active = task.spawn(function()
			while task.wait( 1 / self.info.Rate ) do
				self:emit_particle( get_cframe(adornee) );
			end;
		end)
		
		task.delay(self.info.EmitDuration, function()
			if coroutine.status(active) == "suspended" then
				task.cancel(active);
			end;
		end)
	end
end

function MeshEmitter:emit_particle(coordinate: CFrame): ()
	local start = self.start:Clone();
	
	local mesh_start = start:FindFirstChild("Mesh");
	local decal_start = start:FindFirstChild("Decal");
	
	local mesh_finish = self.finish:FindFirstChild("Mesh");
	local decal_finish = self.finish:FindFirstChild("Decal");
	
	local tween_info = MeshEmitter.get_tween_info(self.info.Duration, self.info.Part_TweenParams);
	local mesh_tween_info = MeshEmitter.get_tween_info(self.info.Duration, self.info.Mesh_TweenParams) or tween_info;
	local decal_tween_info = MeshEmitter.get_tween_info(self.info.Duration, self.info.Decal_TweenParams) or tween_info;
	
	local influence_start = if self.info.Random then CFrame.lookAlong(Vector3.zero, Rnd:NextUnitVector()) else CFrame.identity;
	local influence_end = if self.info.Random then CFrame.lookAlong(Vector3.zero, Rnd:NextUnitVector()) else CFrame.identity;
	
	local source_cframe: CFrame = self.source:GetPivot();
	local finish_cframe: CFrame = ( coordinate * source_cframe:ToObjectSpace(self.finish.CFrame) ) * influence_start;
	local start_cframe: CFrame = ( coordinate * source_cframe:ToObjectSpace(start.CFrame) ) * influence_end;
	local finish_scale = 1;
	local start_scale = 1;
	
	if decal_start then
		decal_start.Transparency = self.info.Decal_StartTransparency;
	end;
	
	start.CFrame = start_cframe;
	start.Size = start.Size * start_scale;
	start.CanCollide = false;
	start.CanQuery = false;
	start.CanTouch = false;
	start.CollisionGroup = "Effects";
	start.Name = "MeshFX";
	start.Transparency = self.info.Mesh_StartTransparency;
	start.Parent = workspace.Visuals;
	
	local tween_part = TweenService:Create(start, tween_info, {
		Size = self.finish.Size * finish_scale;
		CFrame = finish_cframe;
	})

	tween_part:Play();
	
	local tween_transparency = TweenService:Create(start, tween_info, {
		Transparency = self.info.Mesh_EndTransparency
	})

	tween_transparency:Play();
	
	if mesh_start then
		local tween_mesh = TweenService:Create(mesh_start, tween_info, {
			Scale = mesh_finish.Scale * finish_scale;
			Offset = mesh_finish.Offset;
		})
		
		tween_mesh:Play();
	end
	
	if decal_start then
		local tween_transparency = TweenService:Create(decal_start, tween_info, {
			Transparency = self.info.Decal_EndTransparency
		})
		
		tween_transparency:Play();
	end;
	
	task.delay(tween_info.Time, function()
		start:Destroy();
		start = nil;
	end)
end

table.freeze(MeshEmitter);

return MeshEmitter;