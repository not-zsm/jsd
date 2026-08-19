local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer;
local PlayerScripts = Player:WaitForChild("PlayerScripts");

local Table = require( "./Table" )
local Maid = require( "./Maid" )
local Signal = require( "./Signal" )

local DummyMethod = @native function() end;

local InputHelper = {};
InputHelper.PrimaryInputType = Enum.UserInputType.None;
InputHelper.OnPrimaryInputTypeChanged = Signal.new() :: Signal.Signal<Enum.UserInputType, Enum.UserInputType>
InputHelper.TouchDown = false;
InputHelper.UsingMobile = false;
InputHelper.UsingKeyboard = false;
InputHelper.UsingGamepad = false;

-- Constant list that contains any inputs related to mouse
InputHelper.MouseInputs = table.freeze {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3,
	Enum.UserInputType.MouseMovement,
	Enum.UserInputType.MouseWheel,
}

InputHelper.GamepadInputs = Table.bool_map{
	Enum.KeyCode.ButtonA,
	Enum.KeyCode.ButtonX,
	Enum.KeyCode.ButtonB,
	Enum.KeyCode.ButtonY,
	Enum.KeyCode.ButtonL1,
	Enum.KeyCode.ButtonL2,
	Enum.KeyCode.ButtonL3,
	Enum.KeyCode.ButtonR1,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonR3,
	Enum.KeyCode.ButtonStart,
	Enum.KeyCode.ButtonSelect,
	Enum.KeyCode.DPadUp,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadRight,
	Enum.KeyCode.Thumbstick1,
	Enum.KeyCode.Thumbstick2,
}

-- Gives whether the user is touch screen activated as last input
function InputHelper.IsMobile(UserInput: Enum.UserInputType?)
	if (UserInput or InputHelper.PrimaryInputType) == Enum.UserInputType.Touch then
		return true;
	end;
	
	return false;
end

function InputHelper.IsMouseInput(UserInput: Enum.UserInputType)
	return table.find(InputHelper.MouseInputs, UserInput) ~= nil;
end

function InputHelper.IsGamepadInput(UserInput: Enum.KeyCode)
	return InputHelper.GamepadInputs[UserInput] ~= nil;
end

function InputHelper.IsMovement(Input: InputObject): boolean
	return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch or Input.KeyCode == Enum.KeyCode.Thumbstick1)
end

-- this is truly dangerous, but the only way to truly stop mobile camera panning (thanks Roblox)
local function SetCameraInputEnabled(Value: boolean)
	local CameraInput = require(PlayerScripts.PlayerModule.CameraModule.CameraInput);
	CameraInput.setInputEnabled(Value);
end

function InputHelper.LockCameraRotation()
	-- Only need to lock camera rotation when using mobile 👿
	if not InputHelper.UsingMobile then return end;
	
	local function blockCamera(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
		return Enum.ContextActionResult.Sink;
	end
	
	ContextActionService:BindAction("BlockCameraPan", blockCamera, false, Enum.UserInputType.Touch)
	xpcall(SetCameraInputEnabled, warn, false);
end

function InputHelper.UnlockCameraRotation()
	ContextActionService:UnbindAction("BlockCameraPan")
	xpcall(SetCameraInputEnabled, warn, true);
end

local NameMaps = {
	[Enum.UserInputType.MouseButton1] = "M1";
	[Enum.UserInputType.MouseButton2] = "M2";
	[Enum.UserInputType.MouseButton3] = "M3";
}

function InputHelper.DisplayInput(UserInput: Enum.KeyCode | Enum.UserInputType): string
	if UserInput.EnumType == Enum.KeyCode then
		local Value: number = UserInput.Value;
		
		if Value >= 48 and Value <= 57 then
			return tostring(UserInput.Value - 48);
			
		elseif Value >= 160 and Value <= 255 then
			return "<Contextual>";
			
		elseif Value >= 256 and Value <= 265 then
			return tostring(UserInput.Value - 256);
			
		elseif Value >= 1000 and Value <= 1011 then
			return string.sub(UserInput.Name, 7);
			
		elseif UserInput == Enum.KeyCode.Unknown then
			return "-";
		end
	end
	
	return NameMaps[UserInput] or UserInput.Name;
end

function InputHelper.IsNumberKey(Key: Enum.KeyCode): boolean
	return Key.Value >= 48 and Key.Value <= 57;
end

function InputHelper.GetNumberKey(Key: Enum.KeyCode): number?
	return if InputHelper.IsNumberKey(Key) then Key.Value - 48 else nil;
end

function InputHelper.DisplaySpaced(Text: string): string
	return string.sub(Text, 1, 1) .. string.gsub(string.sub(Text, 2), "%u", " %0")
end

function InputHelper.IsInteract(Input: InputObject): boolean
	return Input.UserInputType == Enum.UserInputType.Touch
		or Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.KeyCode == Enum.KeyCode.ButtonA;
end

function InputHelper.IsClick(Input: InputObject): boolean
	return Input.UserInputState == Enum.UserInputState.Begin and InputHelper.IsInteract(Input);
end

function InputHelper.IsClickDown(): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or InputHelper.TouchDown;
end

function InputHelper.IsTouchBegin(Input: InputObject)
	return Input.UserInputType == Enum.UserInputType.Touch 
		and Input.UserInputState == Enum.UserInputState.Begin;
end

function InputHelper.IsTouchEnd(Input: InputObject)
	return Input.UserInputType == Enum.UserInputType.Touch 
		and Input.UserInputState == Enum.UserInputState.End;
end

function InputHelper.GetInputCode(Input: InputObject): (Enum.UserInputType | Enum.KeyCode)
	return if Input.KeyCode == Enum.KeyCode.Unknown then Input.UserInputType else Input.KeyCode;
end

function InputHelper.GetInputFromMappedValue(Value: number): (Enum.UserInputType | Enum.KeyCode)?
	if not Value then return nil end;
	
	if (Value < 0) then
		return Enum.UserInputType:FromValue(-Value - 1)
	else
		return Enum.KeyCode:FromValue(Value);
	end;
end

function InputHelper.MapInputToValue(Code: (Enum.UserInputType | Enum.KeyCode)): number?
	if not Code then return nil end;
	
	if Code:IsA("UserInputType") then
		return -Code.Value - 1;

	elseif Code:IsA("KeyCode") then
		return Code.Value;
	end;
	
	return nil;
end

function InputHelper.BindToContext(Button: GuiButton, HoldDuration: number, Context: any): Maid.Maid
	local ContextMaid = Maid.destroying(Button);
	local HoldStart: number = 0;
	local HoldPosition: Vector2 = Vector2.zero;
	local HoldThread: thread;
	
	if not Context[Enum.UserInputType.MouseButton1] then
		Context[Enum.UserInputType.MouseButton1] = DummyMethod;
	end;
	
	if not Context[Enum.UserInputType.MouseButton2] then
		Context[Enum.UserInputType.MouseButton2] = DummyMethod;
	end;
	
	local function HoldContext()
		if (HoldPosition - UserInputService:GetMouseLocation()).Magnitude < 12 then
			Context[Enum.UserInputType.MouseButton2]()
		end;
	end
	
	ContextMaid:add(Button.MouseButton1Down:Connect(function()
		HoldStart = tick();
		HoldPosition = UserInputService:GetMouseLocation();
		HoldThread = task.delay(HoldDuration, HoldContext)
	end))
	
	ContextMaid:add(Button.MouseLeave:Connect(function()
		Maid.cleanup(HoldThread);
	end))
	
	ContextMaid:add(Button.MouseButton1Up:Connect(function()
		Maid.cleanup(HoldThread);
		
		local Position = UserInputService:GetMouseLocation();
		
		if tick() - HoldStart < HoldDuration and (HoldPosition - UserInputService:GetMouseLocation()).Magnitude < 12 then
			Context[Enum.UserInputType.MouseButton1]()
		end
	end));
	
	ContextMaid:add(Button.MouseButton2Click:Connect(Context[Enum.UserInputType.MouseButton2]));
	
	return ContextMaid;
end

function InputHelper.BindToHandle(Handle: Handles, Context): RBXScriptConnection
	local Connection: RBXScriptConnection?;
	
	if not Context[Enum.UserInputState.Begin] then
		Context[Enum.UserInputState.Begin] = DummyMethod;
	end;
	
	if not Context[Enum.UserInputState.End] then
		Context[Enum.UserInputState.End] = DummyMethod;
	end;
	
	return Handle.MouseButton1Down:Connect(function()
		if Connection and Connection.Connected then
			Connection:Disconnect()
		end
		
		ContextActionService:BindAction("MobileInputSink", DummyMethod, false, Enum.UserInputType.Touch);
		
		Connection = UserInputService.InputEnded:Connect(function(input, processed)
			if InputHelper.IsInteract(input) or (input.KeyCode == Enum.KeyCode.ButtonA) then
				if Connection and Connection.Connected then
					Connection:Disconnect();
				end;
				
				ContextActionService:UnbindAction("MobileInputSink");
				Context[Enum.UserInputState.End](Handle);
			end
		end)
		
		Context[Enum.UserInputState.Begin](Handle);
	end)
end

function InputHelper.__main()
	UserInputService.InputBegan:Connect(function(input)
		local LastUsing = InputHelper.PrimaryInputType;
		
		if input.UserInputType == Enum.UserInputType.Keyboard then
			InputHelper.PrimaryInputType = input.UserInputType;
			InputHelper.UsingKeyboard = true;
			InputHelper.UsingGamepad = false;
			InputHelper.UsingMobile = false;

		elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
			InputHelper.PrimaryInputType = input.UserInputType;
			InputHelper.UsingGamepad = true;
			InputHelper.UsingKeyboard = false;
			InputHelper.UsingMobile = false;
			
		elseif input.UserInputType == Enum.UserInputType.Touch then
			InputHelper.PrimaryInputType = input.UserInputType;
			InputHelper.UsingMobile = true;
			InputHelper.UsingKeyboard = false;
			InputHelper.UsingGamepad = false;
		end
		
		if InputHelper.PrimaryInputType ~= LastUsing then
			InputHelper.OnPrimaryInputTypeChanged:Fire(InputHelper.PrimaryInputType, LastUsing);
		end
	end)
	
	UserInputService.TouchStarted:Connect(function()
		InputHelper.TouchDown = true;
	end);
	
	UserInputService.TouchEnded:Connect(function()
		InputHelper.TouchDown = false;
	end)
end

InputHelper.__main();

return InputHelper;