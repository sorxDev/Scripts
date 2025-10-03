metadata = {
	name = "Free Camera tweaks",
	description = "A floating camera that can be controlled with keyboard and gamepad.",
	author = "Sorx",
	defaultKeybind = "x",
}

local forwardKey = Input.Key.W
local backwardKey = Input.Key.S
local leftKey = Input.Key.A
local rightKey = Input.Key.D
local upKey = Input.Key.E
local downKey = Input.Key.Q
--- This moves the camera up and down along the gravity vector instead of local up. It also makes W and S work in the plane defined by the gravity
local gravityAlignedMovementModifier = Input.Key.LeftAlt
local localMovementAxesDefault = true

local snapToGravityKey = Input.Key.SpaceBar

local pitchUpKey = Input.Key.Up
local pitchDownKey = Input.Key.Down
local yawLeftKey = Input.Key.Left
local yawRightKey = Input.Key.Right

local rollMouseEnable = Input.Key.RightMouseButton
local rollLeftGp = Input.Gamepad.DPad_Left
local rollRightGp = Input.Gamepad.DPad_Right
local rollResetTolerance = 5

-- Tap these keys to adjust the camera movement speed
local fastKey = Input.Key.LeftShift
local slowKey = Input.Key.LeftControl

local zoomInGp = Input.Gamepad.DPad_Up
local zoomOutGp = Input.Gamepad.DPad_Down
local zoomSpeedGp = 0.5
local zoomSpeedKb = 5

local minFov = 0.05
local maxFov = 170
camera.fieldOfView = 70

local rotSpeed = 180
--- How much the zoom level affects view rotation speed control. 0 to disable the effect.
local fovRotSpeedMultiplier = 2

local moveSpeed = config.moveSpeed or 1600
local maxMoveSpeed = 50000
local minMoveSpeed = 200
--- How fast the speed adjustment buttons affect the camera speed
local speedAdjustmentRate = 1
local mouseSensitivity = config.mouseSensitivity or 3.6
-- Should be a number between 0 and 1, with 1 being infinitely smooth (the camera won't rotate)
local lookSmoothness = 0
local lookInputTarget = Vec3.zeroVector
local rotEuler = Vec3.zeroVector
local firstTransition = true
local smoothing = false
local toggleSmoothingKey = Input.Key.LeftAlt
local showNameTags = false

-- Change apparent gravity direction quickly when looking around, or slowly passively to avoid disorientation
local gravityChaseSpeed = 6
local gravitySlowChaseSpeed = 0.5
local gravityChaser = gravity.upRotation

-- Post Processing
local autoFocusKeyKB = Input.Key.MiddleMouseButton
local autoFocusKeyGP = Input.Gamepad.RightThumbstick
local continuousAutoFocus = false
local alignToGravity = true

local playGoalExplosions = true
local playScraprunSpinners = true
local placeBallEnabled = true
local ballScaleMultiplier = 1

function onTransitionBegin(transitionInfo: Transition)
	if firstTransition then
		-- Sets a nice overview location for the Halcyon ring
		transitionInfo.length = 10
		camera.position = Vec3.new( 0, 2440, -28020)
		rotEuler = Vec3.new(0, 0, 90)
		camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
	else
		camera.position = transitionInfo.startPosition
		camera.rotation = transitionInfo.startRotation
		rotEuler = transitionInfo.startRotation:euler()
		rotEuler.x = 0
	end
	firstTransition = false
	setSmoothing(smoothing)
end

-- analysis script

alwaysTick = true

local drawTrails = false
local drawConnectingLines = false
local lineThickness = 4
local pointSize = 6
local lastFrame: ReplayFrame = nil
local resolution = 5

local targetPlayer: string = ""
local range = Vec2.new(0, 0)

local function randomColor(seed: number): { number }
	math.randomseed(seed)
	return { hsvToRGB(math.random(), 1, 1) }
	-- return { math.random(), math.random(), math.random() }
end

local function colorFromSpeed(speed: number): { number }
	local slowest = Vec3.new(0, 1, 0)
	local fastest = Vec3.new(1, 0, 0)
	local speed01 = math.clamp(speed / 1000, 0, 1)
	local out = Vec3.lerp(slowest, fastest, speed01)
	return { out.x, out.y, out.z }
end

function hsvToRGB(h: number, s: number, v: number)
	local r, g, b

	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	i = i % 6

	if i == 0 then
		r, g, b = v, t, p
	elseif i == 1 then
		r, g, b = q, v, p
	elseif i == 2 then
		r, g, b = p, v, t
	elseif i == 3 then
		r, g, b = p, q, v
	elseif i == 4 then
		r, g, b = t, p, v
	elseif i == 5 then
		r, g, b = v, p, q
	end

	return r, g, b
end

local function drawPointCloud()
	WorldDraw.clear()
	local points = 0
	local replays = Replay.listLoaded()
	for i = 1, #replays do
		local replay = Replay.getByIndex(i)
		if replay == nil then
			error("Replay is nil. " .. i .. " of " .. #replays)
			return
		end
		for i = 1, (range.y - range.x) * resolution do
			local frame = replay:getFrameAtTimeSeconds((i - 1) / resolution + range.x, true)
			for j = 1, #frame.players do
				local player = frame.players[j]
				local c = colorFromSpeed(player.velocity:length())
				WorldDraw.drawPoint(player.head.position, c[1], c[2], c[3], pointSize, 0)
				points += 1
			end
		end
	end
	print("Total points drawn: " .. points)
end

local function drawAllLines()
	WorldDraw.clear()
	local segments = 0
	local replays = Replay.listLoaded()
	for i = 1, #replays do
		local replay = Replay.getByIndex(i)
		if replay == nil then
			warn("Replay is nil. " .. i .. " of " .. #replays)
			return
		end
		local lastFrame: ReplayFrame = nil
		for i = 1, (range.y - range.x) * resolution do
			local frame = replay:getFrameAtTimeSeconds((i - 1) / resolution + range.x, true)
			for j = 1, #frame.players do
				local player = frame.players[j]
				if targetPlayer ~= "" and player.playerName ~= targetPlayer then
					continue
				end
				local lastPlayer: ReplayPlayer = nil
				if lastFrame then
					lastPlayer = lastFrame:getPlayerById(player.playerId)
				end

				if lastPlayer then
					local c = colorFromSpeed(player.velocity:length())
					WorldDraw.drawLine(lastPlayer.head.position, player.head.position, c[1], c[2], c[3], lineThickness, 0)
					segments = segments + 1
				end
			end
			lastFrame = frame
		end
	end
	print("Total line segments drawn: " .. segments)
end

function tick(dt)
	if drawTrails then
		if #Replay.listLoaded() > 0 then
			local replay = Replay.getByIndex(1)
			if replay == nil then
				error("Replay is nil. 1 of " .. #Replay.listLoaded())
				return
			end
			local frame = replay:getCurrentFrame(false)
			for i = 1, #frame.players do
				local player = frame.players[i]
				if targetPlayer ~= "" and player.playerName ~= targetPlayer then
					continue
				end
				local lastPlayer: ReplayPlayer = nil
				if lastFrame then
					lastPlayer = lastFrame:getPlayerById(player.playerId)
				end

				if lastPlayer then
					local c = colorFromSpeed(player.velocity:length())
					WorldDraw.drawLine(lastPlayer.head.position, player.head.position, c[1], c[2], c[3], lineThickness, 10)
				end
			end
			for i = 1, #frame.balls do
				local ball = frame.balls[i]
				local lastBall: ReplayBall = nil
				if lastFrame then
					lastBall = lastFrame.balls[i]
				end

				if lastBall and (lastBall.transform.position - ball.transform.position):length() < 100 then
					WorldDraw.drawLine(lastBall.transform.position, ball.transform.position, 0, 0, 1, lineThickness, 10)
				end
			end
			lastFrame = frame
			-- print("Drawing points")
		end
	end

	if drawConnectingLines then
		if #Replay.listLoaded() > 0 then
			local replay = Replay.getByIndex(1)
			if replay == nil then
				error("Replay is nil. 1 of " .. #Replay.listLoaded())
				return
			end
			local frame = replay:getCurrentFrame(true)
			WorldDraw.clear()
			for i = 1, #frame.players do
				local player = frame.players[i]

				-- draw a line to every other player
				for j = 1, #frame.players do
					if i ~= j then
						local otherPlayer = frame.players[j]
						if (player.head.position - otherPlayer.head.position):length() < 5000 then
							local c = player.playerColor.teamLogoIndex == otherPlayer.playerColor.teamLogoIndex and { 0, 1, 0 } or { 1, 0, 0 }
							WorldDraw.drawLine(player.head.position, otherPlayer.head.position, c[1], c[2], c[3], lineThickness, 0)
						end
					end
				end
			end
			for i = 1, #frame.balls do
				local ball = frame.balls[i]

				-- draw a line to every other player
				for j = 1, #frame.players do
					if i ~= j then
						local otherPlayer = frame.players[j]
						local distance = (ball.transform.position - otherPlayer.head.position):length()
						if distance < 5000 then
							local c = colorFromSpeed(distance / 2)
							WorldDraw.drawLine(ball.transform.position, otherPlayer.head.position, c[1], c[2], c[3], lineThickness, 0)
						end
					end
				end
			end
			lastFrame = frame
		end
	end
end





function onGui()
	if Gui.collapsingHeader("Debug") then
		Gui.text("" .. #Replay.listLoaded() .. " replays loaded\nLoad replays with the Replays window.")
	Gui.spacing()
	targetPlayer = Gui.inputText("Target Player", targetPlayer)
	Gui.setItemTooltip("Only show this player. Leave blank for all players")
	resolution = Gui.sliderFloat("Samples per second", resolution, 0.1, 10)
	if Gui.button("Draw point cloud") then
		drawPointCloud()
	end
	Gui.sameLine()
	pointSize = Gui.sliderFloat("Point Size", pointSize, 1, 50)
	Gui.spacing()
	if Gui.button("Draw Paths") then
		drawAllLines()
	end
	Gui.sameLine()
	lineThickness = Gui.sliderFloat("Line Thickness", lineThickness, 1, 50)
	Gui.spacing()
	local newDrawTrails = Gui.checkbox("Draw Trails", drawTrails)
	if newDrawTrails ~= drawTrails then
		drawTrails = newDrawTrails
		if not drawTrails then
			WorldDraw.clear()
		end
	end
	local newDrawConnectingLines = Gui.checkbox("Draw Player Connections", drawConnectingLines)
	if newDrawConnectingLines ~= drawConnectingLines then
		drawConnectingLines = newDrawConnectingLines
		if not drawConnectingLines then
			WorldDraw.clear()
		end
	end

	local replay = Replay.getByIndex(1)
	if replay ~= nil then
		if range.x == 0 and range.y == 0 then
			range = Vec2.new(0, replay:getDurationSeconds())
		end
		Gui.text("Replay range: ")
		Gui.text(`Start: {range.x}`)
		Gui.text(`End: {range.y}`)
		local nextRange = Gui.rangeSlider("timelineRange", range, 0, replay:getDurationSeconds())
		if nextRange.x ~= range.x then
			replay:setPlaybackTimeSeconds(nextRange.x)
		end
		if nextRange.y ~= range.y then
			replay:setPlaybackTimeSeconds(nextRange.y)
		end
		range = Vec2.new(nextRange.x, nextRange.y)
	end
		Gui.indent()
		camera.hideNearestHead = Gui.checkbox("Hide nearest head", camera.hideNearestHead)

		local newGoalExplosions = Gui.checkbox("Goal explosions", playGoalExplosions)
		if newGoalExplosions ~= playGoalExplosions then
			playGoalExplosions = newGoalExplosions
			spectatorDebug.goalExplosions = playGoalExplosions
		end

		local newScraprunSpinners = Gui.checkbox("Scraprun spinners", playScraprunSpinners)
		if newScraprunSpinners ~= playScraprunSpinners then
			playScraprunSpinners = newScraprunSpinners
			spectatorDebug.scrapRunSpinners = playScraprunSpinners
		end

		local newPlaceBallEnabled = Gui.checkbox("'Place Ball' visuals", placeBallEnabled)
		if newPlaceBallEnabled ~= placeBallEnabled then
			placeBallEnabled = newPlaceBallEnabled
			spectatorDebug.placeBallHereVisuals = placeBallEnabled
		end

		local newBallScaleMultiplier = Gui.sliderFloat("Ball scale multiplier", ballScaleMultiplier, 0, 10)
		if newBallScaleMultiplier ~= ballScaleMultiplier then
			ballScaleMultiplier = newBallScaleMultiplier
			spectatorDebug.replayBallScaleMultiplier = ballScaleMultiplier
		end
		Gui.unindent()
	end

	if Gui.collapsingHeader("Controls") then
		Gui.indent()
		Gui.text("Various tweaks to the Default Camera")
		Gui.unindent()
		Gui.newLine()
	end

	moveSpeed = Gui.sliderFloat("Move Speed", moveSpeed, minMoveSpeed, maxMoveSpeed)
	mouseSensitivity = Gui.sliderFloat("Mouse Sensitivity", mouseSensitivity, 0, 10)

	speedAdjustmentRate = Gui.sliderFloat("Speed Adjustment Rate", speedAdjustmentRate, 0, 5)
	Gui.setItemTooltip("How fast the speed adjustment buttons affect the camera speed")
	alignToGravity = Gui.checkbox("Automatically Align to Gravity", alignToGravity)
	localMovementAxesDefault = Gui.checkbox("Use Local Movement Axes (Hold alt to use other set of axes)", localMovementAxesDefault)

	Gui.separatorText("Manual Controls")
	camera.position = Gui.dragFloat3("Position", camera.position, 10, -100000, 100000)
	local newRot = Gui.dragFloat3("Rotation (roll, pitch, yaw)", rotEuler, 1, -180, 180)
	if Gui.isItemActive() then
		gravityChaser = gravity.upRotation
		rotEuler = newRot
		camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
	end
	camera.fieldOfView = Gui.sliderFloat("Field of View", camera.fieldOfView, minFov, maxFov)

	camera.showNameTags = Gui.checkbox("Show name tags", camera.showNameTags)
	Gui.newLine()

	if Gui.collapsingHeader("Smoothing##smoothingSettingsHeader") then
		Gui.indent()
		local newSmoothing = Gui.checkbox("Smoothing##smoothingCheckbox", smoothing)
		if newSmoothing ~= smoothing then
			smoothing = newSmoothing
			setSmoothing(smoothing)
		end
		lookSmoothness = Gui.sliderFloat("Look Smoothness", lookSmoothness, 0, 1)
		camera.positionSmoothing = Gui.sliderFloat("Position Smoothing", camera.positionSmoothing, 0, 1)
		camera.rotationSmoothing = Gui.sliderFloat("Rotation Smoothing", camera.rotationSmoothing, 0, 1)
		camera.fieldOfViewSmoothing = Gui.sliderFloat("Field of View Smoothing", camera.fieldOfViewSmoothing, 0, 1)
		Gui.unindent()
	end

	-- Post Processing Effects:
	if Gui.collapsingHeader("Post Processing Settings") then
		Gui.indent()
		camera.nearClippingPlane = Gui.sliderFloat("Near Clipping Plane", camera.nearClippingPlane, 1, 100)

		if Gui.button("Auto Focus") then
			autoFocusCenter()
		end
		Gui.sameLine()
		continuousAutoFocus = Gui.checkbox("Continuous Auto Focus", continuousAutoFocus)
		Gui.unindent()
	end
end

function tick(dt)
	if Input.getKey(autoFocusKeyKB) or Input.getKey(autoFocusKeyGP) or continuousAutoFocus then
		autoFocusCenter()
	end

	local forward = camera.rotation:getForwardVector()
	local currentGravityDirection = gravityChaser:getUpVector()
	local gravityForward = projectVectorOntoPlane(forward, currentGravityDirection):getSafeNormal()
	local right = camera.rotation:getRightVector()
	local up = camera.rotation:getUpVector()
	local useLocalMovementAxes = xor(localMovementAxesDefault, Input.getKey(gravityAlignedMovementModifier))

	-- Speed
	if Input.getKey(fastKey) or Input.getKey(Input.Gamepad.RightShoulder) then
		moveSpeed *= (1 + speedAdjustmentRate * dt)
		if moveSpeed < minMoveSpeed then
			moveSpeed = minMoveSpeed
		end
		if moveSpeed > maxMoveSpeed then
			moveSpeed = maxMoveSpeed
		end
	elseif Input.getKey(slowKey) or Input.getKey(Input.Gamepad.LeftShoulder) then
		moveSpeed *= (1 - speedAdjustmentRate * dt)
		if moveSpeed > maxMoveSpeed then
			moveSpeed = maxMoveSpeed
		end
	end

	if Input.getKeyDown(toggleSmoothingKey) then
		smoothing = not smoothing
		setSmoothing(smoothing)
	end

	-- Zoom
	-- Keyboard
	camera.fieldOfView -= Input.getAnalog(Input.Key.MouseWheelAxis) * zoomSpeedKb
	-- Gamepad
	if Input.getKey(zoomInGp) then
		camera.fieldOfView -= zoomSpeedGp
	elseif Input.getKey(zoomOutGp) then
		camera.fieldOfView += zoomSpeedGp
	end

	camera.fieldOfView = math.clamp(camera.fieldOfView, minFov, maxFov)

	-- Movement
	--- Holds the input vector combined from keyboard and gamepad
	local input = Vec3.zeroVector
	-- Keyboard
	if Input.getKey(forwardKey) then
		if useLocalMovementAxes then
			input += forward
		else
			input += gravityForward
		end
	end
	if Input.getKey(backwardKey) then
		if useLocalMovementAxes then
			input -= forward
		else
			input -= gravityForward
		end
	end
	if Input.getKey(rightKey) then
		input += right
	end
	if Input.getKey(leftKey) then
		input -= right
	end
	if Input.getKey(upKey) then
		if useLocalMovementAxes then
			input += up
		else
			input += currentGravityDirection
		end
	end
	if Input.getKey(downKey) then
		if useLocalMovementAxes then
			input -= up
		else
			input -= currentGravityDirection
		end
	end

	-- Gamepad
	input += right * Input.getAnalog(Input.Gamepad.LeftX)
	input += forward * Input.getAnalog(Input.Gamepad.LeftY)
	input += up * Input.getAnalog(Input.Gamepad.RightTriggerAxis)
	input -= up * Input.getAnalog(Input.Gamepad.LeftTriggerAxis)

	-- Rotation
	-- slow down rotation if zoomed in
	local adjustedRotSpeed = fovRotSpeedMultiplier * (camera.fieldOfView - 90) / 90 + rotSpeed
	local adjustedMouseSensitivity = fovRotSpeedMultiplier * (camera.fieldOfView - 90) / 90 + mouseSensitivity
	local adjustedLookSmoothness = 1 - (1 - lookSmoothness) ^ 3
	local lookInputTargetDelta = Vec3.zeroVector

	-- Mouse
	local mouse = Input.getMouseDelta()
	local rollAngle = -rotEuler.x * math.pi / 180.0
	if mouse and mouse.x then
		if Input.getKey(rollMouseEnable) then
			-- Roll
			lookInputTargetDelta.x += mouse.x * mouseSensitivity / 2.0
		else
			-- Yaw
			lookInputTargetDelta.z += mouse.x * adjustedMouseSensitivity
			-- Pitch
			lookInputTargetDelta.y += mouse.y * adjustedMouseSensitivity
		end
	end

	-- Keyboard
	if Input.getKey(yawRightKey) then
		lookInputTargetDelta.z += adjustedRotSpeed * dt
	end
	if Input.getKey(yawLeftKey) then
		lookInputTargetDelta.z -= adjustedRotSpeed * dt
	end
	if Input.getKey(pitchUpKey) then
		lookInputTargetDelta.y += adjustedRotSpeed * dt
	end
	if Input.getKey(pitchDownKey) then
		lookInputTargetDelta.y -= adjustedRotSpeed * dt
	end

	-- Gamepad
	-- Roll
	if Input.getKey(rollRightGp) then
		lookInputTargetDelta.x += rotSpeed * dt / 2
	elseif Input.getKey(rollLeftGp) then
		lookInputTargetDelta.x -= rotSpeed * dt / 2
	end
	-- Yaw
	lookInputTargetDelta.z += Input.getAnalog(Input.Gamepad.RightX) * adjustedRotSpeed * dt
	-- Pitch
	lookInputTargetDelta.y += Input.getAnalog(Input.Gamepad.RightY) * adjustedRotSpeed * dt

	-- Smoothing
	local rollAdjustedInput = Vec3.new(
		lookInputTargetDelta.x,
		lookInputTargetDelta.y * math.cos(rollAngle) + lookInputTargetDelta.z * math.sin(rollAngle),
		lookInputTargetDelta.z * math.cos(rollAngle) - lookInputTargetDelta.y * math.sin(rollAngle)
	)
	lookInputTarget += rollAdjustedInput
	local nextLookDiff = lookInputTarget * math.min((1 - adjustedLookSmoothness) * dt * 60, 1)

	-- Gravity Roll Adjustment
	if alignToGravity then
		if gravityChaser ~= gravity.upRotation and gravity.strength ~= 0 then
			local inputTotal = nextLookDiff:length()
			local nextGravityChaser = Quat.slerp(gravityChaser, gravity.upRotation, (inputTotal * gravityChaseSpeed + gravitySlowChaseSpeed) * dt)

			local nextRotation = nextGravityChaser:inverse() * Quat.fromXZ(forward, nextGravityChaser:rotateVector(Vec3.new(0, 0, 1)))
			rotEuler = nextRotation:euler() + Vec3.new(rotEuler.x, 0, 0) -- preserve existing roll
			gravityChaser = nextGravityChaser
		end
	end
	if Input.getKeyDown(snapToGravityKey) then
		gravityChaser = gravity.upRotation
		rotEuler.x = 0
	end

	rotEuler += nextLookDiff
	lookInputTarget -= nextLookDiff

	-- Clamp rotation
	if rotEuler.y > 89.9 then
		rotEuler.y = 89.9
	end
	if rotEuler.y < -89.9 then
		rotEuler.y = -89.9
	end

	-- Reset roll if close to 0
	if Input.getKeyUp(rollMouseEnable) or Input.getKeyUp(rollRightGp) or Input.getKeyUp(rollLeftGp) then
		local clampedRoll = math.abs(rotEuler.x) % 360
		if clampedRoll <= rollResetTolerance then
			rotEuler.x = 0
			lookInputTarget.x = 0
		end
	end

	camera.position += input * moveSpeed * dt
	camera.rotation = gravityChaser * Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
end

function setSmoothing(smoothing: boolean)
	if smoothing then
		camera.positionSmoothing = 0.15
		camera.rotationSmoothing = 0.02
		lookSmoothness = 0.7
		camera.fieldOfViewSmoothing = 0.15
	else
		camera.positionSmoothing = 0.02
		camera.rotationSmoothing = 0.02
		lookSmoothness = 0
		camera.fieldOfViewSmoothing = 0.05
	end
end

function onMessageReceived(message)
	if message.messageType == "setTransform" then
		rotEuler = message.rotation:euler()
		rotEuler.x = 0
		camera.position = message.position
		camera.rotation = message.rotation
		camera.fieldOfView = message.fieldOfView
	elseif message.messageType == "lookAt" then
		camera:lookAt(message.target, message.upVector)
		rotEuler = camera.rotation:euler()
	end
end

function autoFocusCenter()
	local maxAutoFocusDistance = 1000000
	local hit = camera:castRay(camera.position, camera.position + camera.rotation:getForwardVector() * maxAutoFocusDistance)
	if hit.successful then
		local distanceToHit = Vec3.distance(camera.position, hit.position)
		postProcessSettings.depthOfFieldFocalDistance = distanceToHit
	end
end

function projectVectorOntoPlane(vec: Vec3, normal: Vec3)
	local normalizedNormal = normal:getSafeNormal()
	local dot1 = vec:dot(normalizedNormal)
	local proj = normalizedNormal * dot1
	local answer = vec - proj
	return answer
end

function xor(a, b)
	return (a and not b) or (not a and b)
end
