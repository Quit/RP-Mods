local Vec3 = _radiant.csg.Point3f
local CameraService = radiant.mods.load('stonehearth').camera

local CONFIG = {
	camera_keys = {
		forward = "W",
		backward = "S",
		left = "A",
		right = "D",
		turn_left = "Q",
		turn_right = "E"
	}
}

CONFIG = rp.load_config(CONFIG)

-- Hotfix #1: Camera.
local KEYS = CONFIG.camera_keys

local KeyboardInput = _radiant.client.KeyboardInput

local function find_key(key)
	return KeyboardInput['KEY_' .. key]
end

local function validate_key(input, default)
	input = tostring(input):upper()
	local _, k = pcall(find_key, input)
	if not _ then
		rp.logf('Cannot find key %q', input)
		k = KeyboardInput[default]
	end
	
	return k
end

local KEY_TURN_LEFT, KEY_TURN_RIGHT = validate_key(KEYS.turn_left, 'KEY_Q'), validate_key(KEYS.turn_right, 'KEY_E')
local KEY_FORWARD, KEY_BACKWARD = validate_key(KEYS.forward, 'KEY_W'), validate_key(KEYS.backward, 'KEY_S')
local KEY_LEFT, KEY_RIGHT = validate_key(KEYS.left, 'KEY_A'), validate_key(KEYS.right, 'KEY_D')

function CameraService:_calculate_keyboard_orbit()
  if _radiant.client.is_key_down(KEY_TURN_LEFT) or _radiant.client.is_key_down(KEY_TURN_RIGHT) then
    local deg_x = 0
    local deg_y = 0
    if _radiant.client.is_key_down(KEY_TURN_LEFT) then
      deg_x = -3
    else
      deg_x = 3
    end
    local orbit_target = self:_get_orbit_target()
    if orbit_target then
      self:_orbit(orbit_target, deg_y, deg_x, 30, 70)
    end
  end
end

function CameraService:_calculate_keyboard_pan()
  local left = Vec3(0, 0, 0)
  local forward = Vec3(0, 0, 0)
  local x_scale = 0
  local y_scale = 0
  local speed = self:get_position().y
  if _radiant.client.is_key_down(KEY_LEFT) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_LEFT) then
    x_scale = -speed
  elseif _radiant.client.is_key_down(KEY_RIGHT) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_RIGHT) then
    x_scale = speed
  end
  left = _radiant.renderer.camera.get_left()
  left:scale(x_scale)
  if _radiant.client.is_key_down(KEY_FORWARD) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_UP) then
    y_scale = -speed
  elseif _radiant.client.is_key_down(KEY_BACKWARD) or _radiant.client.is_key_down(_radiant.client.KeyboardInput.KEY_DOWN) then
    y_scale = speed
  end
  forward = _radiant.renderer.camera.get_forward()
  forward.y = 0
  forward:normalize()
  forward:scale(y_scale)
  self._continuous_delta = forward + left
  if x_scale ~= 0 or y_scale ~= 0 then
    radiant.events.trigger(self, "stonehearth:camera:update", {
      pan = true,
      orbit = false,
      zoom = false
    })
  end
end

return true