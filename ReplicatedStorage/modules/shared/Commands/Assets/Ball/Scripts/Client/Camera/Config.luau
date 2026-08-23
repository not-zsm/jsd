-- Camera configuration values
local Config = {}

-- Camera speed values
Config.HORIZONTAL_SPEED = 10
Config.VERTICAL_SPEED = 4
Config.FOV_SPEED = 4

-- FieldOfView values
Config.MIN_FOV = 60
Config.MAX_FOV = 80
-- FOV = MAX_FOV if ball speed is >= MAX_FOV_SPEED
Config.MAX_FOV_SPEED = 80

-- Minimum zoom distance when in the ball
Config.MIN_ZOOM_DISTANCE = 25

return Config
