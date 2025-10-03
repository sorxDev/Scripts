--!strict
-- @name CastCinematics
-- @description VariousCinematics
-- @author Sorx

metadata = {
	name = "CastCinematics",
	description = "VariousCinematics",
	author = "Sorx",
	defaultKeybind = "c",
}


-- This is a helper function to initialize the config with default values
local function initializeConfig(defaultConfig: {
	autoSwitch: boolean,
	autoSwitchDelay: number,
	cameraPositions: { CameraPositionPreset },
})
	for i, v in pairs(defaultConfig) do
		if config[i] == nil then
			config[i] = v
		end
	end
end

-- idk bout this
        
function onTransitionBegin(transitionInfo: Transition)
	if firstTransition then
		transitionInfo.length = 10
		camera.position = Vec3.new(-10.212, 7724.490, -29488.592)
        rotEuler = Vec3.new(0, 0, 90)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
	else
		camera.position = transitionInfo.startPosition
		camera.rotation = transitionInfo.startRotation
		rotEuler = transitionInfo.startRotation:euler()
		rotEuler.x = 0
	end
	firstTransition = false
	setSmoothing(smoothing)
end

-- Gui

function onGui()
    if Gui.collapsingHeader("ArenaSelection") then
        Gui.indent()
        if Gui.collapsingHeader("DriftballDistrict") then
            Gui.indent()
        if Gui.button("Gateway") then 
            camera.position = Vec3.new(-10.212, 7724.490, -29488.592)
            rotEuler = Vec3.new(0, 0, 90)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Plaza West") then 
        camera.position = Vec3.new(2344, 18551, -29552)
        rotEuler = Vec3.new(0, 0, 0)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Plaza East") then 
        camera.position = Vec3.new(-2344, 18551, -29552)
        rotEuler = Vec3.new(0, 0, 180)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.sameLine()
         if Gui.button("Prime") then 
        camera.position = Vec3.new(19.854, 25123.805, -27921.199)
        rotEuler = Vec3.new(0, 0, 90)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Bunker") then 
        camera.position = Vec3.new(-97.892, 26877.877, -31381.199)
        rotEuler = Vec3.new(0, 0, -90)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Fieldhouse West") then 
        camera.position = Vec3.new(2364.471, 27095.367, -29743.154)
        rotEuler = Vec3.new(0, 0, 0)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Fieldhouse East") then 
        camera.position = Vec3.new(-2347.948, 27095.186, -29743.154)
        rotEuler = Vec3.new(0, 0, -180)
        camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
        setSmoothing(smoothing)
        end
        Gui.unindent()  
    end
    if Gui.collapsingHeader("Driftplex") then
        Gui.indent()
        if Gui.button("Driftplex01") then 
            camera.position = Vec3.new(14623.896, 6403.168, -26351.438)
            rotEuler = Vec3.new(0, -25, 180)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Driftplex02") then 
            camera.position = Vec3.new(15526.873, 6403.168, -25801.924)
            rotEuler = Vec3.new(0, 28, 0)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Driftplex03") then 
            camera.position = Vec3.new(14623.896, 13603.168, -26351.438)
            rotEuler = Vec3.new(0, -25, 180)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Driftplex04") then 
             camera.position = Vec3.new(15526.873, 13603.168, -25801.924)
            rotEuler = Vec3.new(0, 28, 0)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Driftplex05") then 
            camera.position = Vec3.new(14623.896, 23203.168, -26351.438)
            rotEuler = Vec3.new(0, -25, 180)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("Driftplex06") then 
             camera.position = Vec3.new(15526.873, 23203.168, -25801.924)
            rotEuler = Vec3.new(0, 28, 0)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.sameLine()
        if Gui.button("DriftplexLab") then 
            camera.position = Vec3.new(15053.456, 27004.410, -26071.969)
            rotEuler = Vec3.new(30, 0, 90)
            camera.rotation = Quat.fromEuler(rotEuler.x, rotEuler.y, rotEuler.z)
            setSmoothing(smoothing)
        end
        Gui.unindent()
    end 
end




Gui.unindent()
    if Gui.collapsingHeader("Smoothing") then
        Gui.indent()
        camera.positionSmoothing = Gui.sliderFloat("Position Smoothing", camera.positionSmoothing, 0, 1)
		camera.rotationSmoothing = Gui.sliderFloat("Rotation Smoothing", camera.rotationSmoothing, 0, 1)
		camera.fieldOfViewSmoothing = Gui.sliderFloat("Field of View Smoothing", camera.fieldOfViewSmoothing, 0, 1)
        Gui.unindent()
        Gui.newLine()
    end
end