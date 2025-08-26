-- This lua script lets you open an Aseprite animation directly from Gamemaker, and syncronise any changes!

------------------
-- >> CONFIG << --
------------------
Console_log = false

------------------------
-- Requirements
------------------------
json = require"utilities.json" --Allows you to load and save json files: https://github.com/dacap/export-aseprite-file/blob/master/json.lua

-- Functions
------------------------------------
function Print(string)-- Print when console_log is enabled.
	if Console_log == true then
		print(string)
	end
end


-- Returns parsed json from the sprite's YY file 
function Open_yy_file()
	local haystack = app.fs.filePath(app.sprite.filename)
	local needle = app.fs.pathSeparator
	
	-- Get YY filename and path
	local fileYY_name = haystack:sub(haystack:match(".*"..needle.."()"), haystack:len())
	local yy_filePath = haystack .. app.fs.pathSeparator .. fileYY_name .. ".yy"
	
	-- Open the YY file and parse its json data
	local file = io.open(yy_filePath)
	if not file then
		error("Could not open file: " .. yy_filePath)
	end
	
	-- Convert multi-line file to string
	local js = ""
	for line in file:lines() do
		js = js .. line
	end
	file:close()
	
	-- Fix null values disappearing
	js = js:gsub('null', '"null"')
	
	-- Parse JSON and return
	return json.decode(js)
end


------------------------
-- RUN SCRIPT
------------------------
Spr= app.sprite -- Active sprite

-- Pre-script checks
if not Spr then -- No sprite is open
	app.alert("No sprite is currently open.")
	return
end

-- Load JSON data from YY file
js= Open_yy_file()
if js == nil then
	print("Error could not find YY file for "..app.sprite.filename)
	return
end



-- Get Sprite's filename and directory
Filename = app.sprite.filename
Dir_asset= app.fs.filePath(Filename)..app.fs.pathSeparator
GM_asset= js.name
local oldAse = app.sprite
local newAse = nil

-- Find the aseprite file in the asset's directory
local files= app.fs.listFiles(Dir_asset)
local file_list= {}
local file_found= false
for i, file in pairs(files) do
	if file:find(".ase") ~= nil then

		if file == GM_asset..".ase" then
			file_found= true
			newAse= Sprite{ fromFile = Dir_asset..file}-- Open found file
		else
			file_list[#file_list]= file
			Print("File "..#file_list.."="..file)
		end
	end
end



-- ATTEMPT TO FIND RENAMED ASSET OR CREATE THE SPRITE FROM SOURCE DATA
----------------------------------------------------------------------
if file_found == false then
	local file= file_list[0]

	if file ~= nil then
		os.rename(Dir_asset..file, Dir_asset..GM_asset..".ase")-- Rename found file to match asset
		newAse= Sprite{ fromFile= Dir_asset..GM_asset..".ase"}-- Open first ase file in the directory if it exists
		
		print("Asesprite file not found! Renamed ".. file .." -> "..GM_asset..".ase")

	else-- CREATE NEW ASEPRITE FILE FROM GAME-MAKER
		print("creating from new")
		local frames = js.sequence.tracks[1].keyframes.Keyframes
		
		
		-- Import frames
		for i, frame in ipairs(frames) do
			

			local png_file = Dir_asset..frame.Channels["0"].Id.name.. ".png"
			
			if i < 2 then -- Create file from first frame
				
				newAse= Sprite{fromFile= png_file}
				
				if newAse then
					app.sprite= newAse
				else
					app.alert("Warning could not find file for frame "..i..": "..png_file)-- File not found
					return
				end

			else -- Insert next frame
				
				local img= Image{fromFile=png_file}
				local newFrame = newAse:newEmptyFrame()

				if img then	
					newAse:newCel(app.activeLayer, newFrame, img)-- Import new frame
				else
					app.alert("Warning could not find file for frame "..i..": "..png_file)-- File not found
				end
			end

			app.frame.duration= frame.Length * (js.sequence.playbackSpeed * 10)-- Convert GM speed to milliseconds
		end
		
		-- Save aseprite after importing
		app.command.SaveFileAs{
			ui = false,
			filename = Dir_asset..GM_asset..".ase"
		}
	end
end


-- Close original and switch to new ASEPRITE file
if newAse ~= nil then
	oldAse:close()
	app.sprite = newAse
	Print("Successfully loaded "..GM_asset.."!")
	
	-- Save ASEPRITE file
	app.command.SaveFileAs{
		ui = false,
		filename = Dir_asset..GM_asset..".ase"
	}
else
	print("Failed to create new aseprite file")
	return
end