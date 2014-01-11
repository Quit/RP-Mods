local Vec3 = _radiant.csg.Point3f
local CameraService = radiant.mods.load('stonehearth').camera

-- Do some localisation.
local _client = _radiant.client
local _renderer = _radiant.renderer
local _screen = _renderer.screen

local CONFIG = {
	-- Keys to control the camera
	camera_keys = {
		forward = "W",
		backward = "S",
		left = "A",
		right = "D",
		turn_left = "Q",
		turn_right = "E",
		fast_scrolling = nil
	},
	
	-- Whether or not left click can pan the mouse
	enable_mouse_panning = false,
	
	-- Side-scrolling stuff.
	side_scrolling_triggerzone = 0,
	side_scrolling_base_speed = 2, -- base speed, i.e. position.y * this
	side_scrolling_speed_multiplier = 3, -- maximum speed multiplier (at the edge of the screen => this, in the game => 0)
	
	-- Fast scrolling stuff
	fast_scrolling_multiplier = 2.5
}

CONFIG = rp.load_config(CONFIG)

-- Hotfix #1: Camera.
local KEYS = CONFIG.camera_keys
local SIDE_SCROLLING_TRIGGERZONE = CONFIG.side_scrolling_triggerzone
local SIDE_SCROLLING_SPEED_MULTIPLIER = CONFIG.side_scrolling_speed_multiplier
local SIDE_SCROLLING_BASE_SPEED = CONFIG.side_scrolling_base_speed
local ENABLE_MOUSE_PANNING = CONFIG.enable_mouse_panning
local FAST_SCROLLING_MULTIPLIER = CONFIG.fast_scrolling_multiplier

local KeyboardInput = _client.KeyboardInput

local function find_key(key)
	return KeyboardInput['KEY_' .. key]
end

local function validate_key(input, default)
	input = tostring(input):upper()
	local _, k = pcall(find_key, input)
	
	if _ then
		return k
	elseif default then
		rp.logf('Cannot find key %q', input)
		return KeyboardInput[default]
	end
end

local KEY_TURN_LEFT, KEY_TURN_RIGHT = validate_key(KEYS.turn_left, 'KEY_Q'), validate_key(KEYS.turn_right, 'KEY_E')
local KEY_FORWARD, KEY_BACKWARD = validate_key(KEYS.forward, 'KEY_W'), validate_key(KEYS.backward, 'KEY_S')
local KEY_LEFT, KEY_RIGHT = validate_key(KEYS.left, 'KEY_A'), validate_key(KEYS.right, 'KEY_D')
local KEY_FAST_SCROLL = validate_key(KEYS.fast_scrolling, nil)

CameraService._keyboard_delta, CameraService._mouse_delta = Vec3(0, 0, 0), Vec3(0, 0, 0)

function CameraService:_calculate_keyboard_orbit()
  if _client.is_key_down(KEY_TURN_LEFT) or _client.is_key_down(KEY_TURN_RIGHT) then
    local deg_x = 0
    local deg_y = 0
    if _client.is_key_down(KEY_TURN_LEFT) then
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
  local x_scale = 0
  local y_scale = 0
  local speed = self:get_position().y * (KEY_FAST_SCROLL and _client.is_key_down(KEY_FAST_SCROLL) and FAST_SCROLLING_MULTIPLIER or 1)
	
  if _client.is_key_down(KEY_LEFT) or _client.is_key_down(_client.KeyboardInput.KEY_LEFT) then
    x_scale = -speed
  elseif _client.is_key_down(KEY_RIGHT) or _client.is_key_down(_client.KeyboardInput.KEY_RIGHT) then
    x_scale = speed
  end
  
  if _client.is_key_down(KEY_FORWARD) or _client.is_key_down(_client.KeyboardInput.KEY_UP) then
    y_scale = -speed
  elseif _client.is_key_down(KEY_BACKWARD) or _client.is_key_down(_client.KeyboardInput.KEY_DOWN) then
    y_scale = speed
  end
  
  self._keyboard_delta = self:_move_camera(x_scale, y_scale)
	self._continuous_delta = self._keyboard_delta + self._mouse_delta
end

function CameraService:_move_camera(x_speed, y_speed)
	if x_speed == 0 and y_speed == 0 then
		return Vec3(0, 0, 0)
	end
	
	local left = _renderer.camera.get_left()
	left:scale(x_speed)
	
	-- Forward gets special treatment... okay?
	local forward = _renderer.camera.get_forward()
	forward.y = 0
	forward:normalize()
	forward:scale(y_speed)
	
	radiant.events.trigger(self, "stonehearth:camera:update",
		{
			pan = true,
			orbit = false,
			zoom = false
		}
	)
	
	return forward + left
end

if ENABLE_MOUSE_PANNING or SIDE_SCROLLING_TRIGGERZONE > 0 then
	function CameraService:_calculate_side_scrolling_speed_factor(x)
		if x <= 0 then
			return SIDE_SCROLLING_MULTIPLIER
		end
		
		return math.min((SIDE_SCROLLING_TRIGGERZONE - x) / SIDE_SCROLLING_TRIGGERZONE, SIDE_SCROLLING_SPEED_MULTIPLIER)
	end
	
	function CameraService:_calculate_drag(e)
		local drag_key_down = _client.is_key_down(_client.KeyboardInput.KEY_SPACE) or (ENABLE_MOUSE_PANNING and _client.is_mouse_button_down(_client.MouseInput.MOUSE_BUTTON_1))
		
		local screen_width, screen_height = _screen.get_width(), _screen.get_height()
		
		if drag_key_down and not self._dragging then
			do
				local r = _renderer.scene.cast_screen_ray(e.x, e.y)
				local screen_ray = _renderer.scene.get_screen_ray(e.x, e.y)
				self._dragging = true
				self._drag_origin = screen_ray.origin
				if r.is_valid then
					self._drag_start = r.point
				else
					local d = -self._drag_origin.y / screen_ray.direction.y
					screen_ray.direction:scale(d)
					self._drag_start = screen_ray.origin + screen_ray.direction
				end
				local root = _client.get_entity(1)
				local terrain_comp = root:get_component("terrain")
				local bounds = terrain_comp:get_bounds():to_float()
				if not bounds:contains(self._drag_start) then
					self._dragging = false
				end
			end
		elseif not drag_key_down and self._dragging then
			self._dragging = false
		else
			-- Determine if we're worthy
			local speed = self:get_position().y * SIDE_SCROLLING_BASE_SPEED * (KEY_FAST_SCROLL and _client.is_key_down(KEY_FAST_SCROLL) and FAST_SCROLLING_MULTIPLIER or 1)
			local x_scale = 0
			local y_scale = 0
			
			local screen_width, screen_height = _screen.get_width(), _screen.get_height()
			
			if e.x <=  SIDE_SCROLLING_TRIGGERZONE and e.x >= 0 then
				x_scale = -speed * self:_calculate_side_scrolling_speed_factor(e.x)
			elseif screen_width - e.x <= SIDE_SCROLLING_TRIGGERZONE and e.x <= screen_width then
				x_scale = speed * self:_calculate_side_scrolling_speed_factor(screen_width - e.x)
			end
			
			if e.y < SIDE_SCROLLING_TRIGGERZONE and e.y >= 0 then
				y_scale = -speed * self:_calculate_side_scrolling_speed_factor(e.y)
			elseif _screen.get_height() - e.y < SIDE_SCROLLING_TRIGGERZONE then
				y_scale = speed * self:_calculate_side_scrolling_speed_factor(screen_height - e.y)
			end
			
			self._mouse_delta = self:_move_camera(x_scale, y_scale)
			self._continuous_delta = self._keyboard_delta + self._mouse_delta
		end
		if not self._dragging then
			return
		end

		self:_drag(e.x, e.y)
	end
end
return true