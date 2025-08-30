-- AutoConvertOrSwitchToAseprite.lua
-- From a PNG: open existing .aseprite version if it exists; otherwise, save as .aseprite

------------------
-- >> CONFIG << --
------------------
Console_log= false

------------------------
-- Requirements
------------------------
require"utilities.json" --Allows you to load and save json files: https://github.com/dacap/export-aseprite-file/blob/master/json.lua
local importer_funcs= require"import_to_Aseprite"

-- Globals
Filename = ""
Directory= ""
Temp_folder= ""
Spr= nil

--#region FUNCTIONS
------------------------------------

function FS_delete_directory( dir_string)
	local dir= dir_string..app.fs.pathSeparator
	local files= app.fs.listFiles(dir_string)

	for _,filename in pairs(files) do -- frames folder dir
		
		local this= dir..filename

		if app.fs.isFile(this) then -- delete file
			os.remove(this)
		else -- recursively delete contents of directory
			FS_delete_directory(this)
		end
	end
	os.remove(dir_string) -- delete directory
end



-- UUID Generator (Version 4 - Random)
-- Generates UUIDs in format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
function generateUUID()
    -- Set up random seed
    math.randomseed(os.time() + os.clock() * 1000000)
    
    -- Helper function to generate random hex character
    local function randomHex()
        return string.format("%x", math.random(0, 15))
    end
    
    -- Generate UUID parts
    local uuid = {}
    
    -- First group: 8 hex digits
    for i = 1, 8 do
        uuid[#uuid + 1] = randomHex()
    end
    uuid[#uuid + 1] = "-"
    
    -- Second group: 4 hex digits
    for i = 1, 4 do
        uuid[#uuid + 1] = randomHex()
    end
    uuid[#uuid + 1] = "-"
    
    -- Third group: 4 hex digits (version 4, so first digit is always 4)
    uuid[#uuid + 1] = "4"
    for i = 1, 3 do
        uuid[#uuid + 1] = randomHex()
    end
    uuid[#uuid + 1] = "-"
    
    -- Fourth group: 4 hex digits (variant bits, first digit is 8, 9, a, or b)
    local variantDigits = {"8", "9", "a", "b"}
    uuid[#uuid + 1] = variantDigits[math.random(1, 4)]
    for i = 1, 3 do
        uuid[#uuid + 1] = randomHex()
    end
    uuid[#uuid + 1] = "-"
    
    -- Fifth group: 12 hex digits
    for i = 1, 12 do
        uuid[#uuid + 1] = randomHex()
    end
    
    return table.concat(uuid)
end
--#endregion FUNCTIONS



------------------------
-- PRE-CHECKS
------------------------
local spr = app.sprite

-- Pre-script checks
if not spr then -- No sprite is open
	app.alert("No sprite is currently open.")
	return app.alert("No sprite is open.")
end

-- Sprite not saved
if app.sprite.filename:match(".*"..app.fs.pathSeparator.."()") == nil then
	app.command.SaveFile{}

else--Check if is GM asset

	-- Check if this is a gamemaker sprite
	js= Open_yy_file()

	if js == nil then
		app.command.SaveFile{ui= false} -- Save normally when not a GM sprite
		return
	end
end

-------------------------
--- MAIN
-------------------------
Spr= app.sprite -- Active sprite

-- Get Sprite's filename and directory
Filename = app.sprite.filename
Dir_asset= app.fs.filePath(Filename)..app.fs.pathSeparator
GM_asset= js.name

-- DELETE OLD EXPORTED IMAGES
local files= app.fs.listFiles(Dir_asset)
for _,filename in pairs(files) do
	-- print("File ".._..": "..filename)
	if filename:find(".png") ~= nil then
		os.remove(Dir_asset..filename)
	end
end

-- DELETE OLD LAYER DIRECTORY
local dir_layers= Dir_asset.."layers"
FS_delete_directory(dir_layers)
app.fs.makeDirectory(dir_layers)-- recreate layers directory



------------------
-- Perform export!
------------------

-- Sprite Origin
local origin= js.origin + 1
local origin_x= js.sequence.xorigin
local origin_y= js.sequence.yorigin
switch_table= {
	function()--0 TL
		js.sequence.xorigin= 0
		js.sequence.yorigin= 0
	end,
	function()--1 TM
		js.sequence.xorigin= math.floor(app.sprite.width * 0.5)
		js.sequence.yorigin= 0
	end,
	function()--2 TR
		js.sequence.xorigin= app.sprite.width
		js.sequence.yorigin= 0
	end,
	function()--3 ML
		js.sequence.xorigin= 0
		js.sequence.yorigin= math.floor(app.sprite.height * 0.5)
	end,
	function()--4 MM
		js.sequence.xorigin= math.floor(app.sprite.width * 0.5)
		js.sequence.yorigin= math.floor(app.sprite.height * 0.5)
	end,
	function()--5 MR
		js.sequence.xorigin= app.sprite.width
		js.sequence.yorigin= math.floor(app.sprite.height * 0.5)
	end,
	function()--6 BL
		js.sequence.xorigin= 0
		js.sequence.yorigin= app.sprite.height
	end,
	function()--7 BM
		js.sequence.xorigin= math.floor(app.sprite.width * 0.5)
		js.sequence.yorigin= app.sprite.height
	end,
	function()--8 BR
		js.sequence.xorigin= app.sprite.width
		js.sequence.yorigin= app.sprite.height
	end,
	function()--9 Custom
		if app.sprite.width ~= js.width or app.sprite.height ~= js.height then
			print("Sprite's custom origin has changed due to canvas resize!")
		end
	end,
}

switch_table[origin]()

-- Update sprite info
js.sequence.length= #app.sprite.frames -- get array length
js.width= app.sprite.width
js.height= app.sprite.height
--
js.sequence.seqWidth= js.width
js.sequence.seqHeight= js.height


-- Prepare frame data
local layer_uid=  js.layers[1]["name"]-- Only using first layer here as Aseprite file should contain the important data
local frame_data= {}-- temp "array" to hold frame data
local frame_key= 0.0-- Timeline position of current frame

-- Export all frames
for i, frame in ipairs(app.sprite.frames) do
	
	-- Get existing or generate new Frame UID
	local img_uid= js.frames[i]["name"]
	if js.frames[i]["name"] == nil then
		img_uid= generateUUID()
	end
	
	-- FRAMES
	frame_data[i]= json.decode'{"$GMSpriteFrame":"","%Name":"ERR","name":"ERR","resourceType":"GMSpriteFrame","resourceVersion":"2.0"}'-- Create empty struct for this frame's data
	frame_data[i]["%Name"]= img_uid
	frame_data[i]["name"]= img_uid
	
	-- SEQUENCE-TRACK
	local track_data= json.decode('{"$Keyframe<SpriteFrameKeyframe>":"","Channels":{   "0":{"$SpriteFrameKeyframe":"","Id":{"name":"ERROR frame uid","path":"ERROR sprites/ASSET/ASSET.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},   },"Disabled":false,"id":"ERROR UID","IsCreationKey":false,"Key":0.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":false,}') 
	
	track_data.id= generateUUID()
	track_data.Channels["0"]["Id"]["name"]= img_uid
	track_data.Channels["0"]["Id"]["path"]= "sprites/"..GM_asset.."/"..GM_asset..".yy"
	

	-- Create temp file for export
	app.command.GotoFirstFrame()
	local newFile = Sprite(app.sprite)
	app.sprite= newFile
	app.command.GotoFirstFrame()
	

	-- Delete frames for single image export
	local frame_offset= 0
	for x=1, #newFile.frames do -- # get's the length of the array
		
		if app.frame.frameNumber + frame_offset ~= i then
			app.command.RemoveFrame()
			frame_offset= frame_offset + 1
		else
			app.command.GotoNextFrame()
		end
	end
	
	
	-- SEQUENCE-TRACK FRAME DURATION
	local frame_duration= app.frame.duration * 10

	track_data.Key= frame_key
	track_data.Length= frame_duration
	frame_key= frame_key + frame_duration-- Get timeline position of next frame

	
	app.command.FlattenLayers()-- flatten image

	-- Export images
	newFile:saveCopyAs( Dir_asset.."layers"..app.fs.pathSeparator..img_uid..app.fs.pathSeparator..layer_uid..".png")-- Exported as solo Layer
	newFile:saveCopyAs( Dir_asset..img_uid..".png")-- Exported Frame
	

	-- Finish up exporting current frame
	newFile:close()
	app.sprite = Spr
	js.sequence.tracks[1].keyframes.Keyframes[i]= track_data -- Append created data to it's frame data in the json.
end

-- Replace json frame data with local
js.frames= frame_data


-------------------
-- WRITE TO YY FILE
-------------------
local yy_temp_file= Dir_asset..GM_asset..".yytmp"
local yy_file= Dir_asset..GM_asset..".yy"

local file= io.open(yy_temp_file, "w")-- Open and write to temp file first
if file then
	
	-- Encode json
	js= json.encode(js)
	
	-- Fix encoding errors
	js= js:gsub('"eventToFunction"%s*:%s*%[%s*%]', '"eventToFunction":{}')
	js= js:gsub('"null"', 'null')
	
	-- Write json to temp file
	file:write(js )
	file:close()
	
	-- Atomic File Operation to stop gamemaker crashing!
	os.rename(yy_file, yy_file.."DEL")-- Rename orignal yy file
	os.rename(yy_temp_file, yy_file)-- Sneak in replacement yy file.
	os.remove(yy_file.."DEL")-- Delete old yy file.
	-- No one will ever know!
	

	Print("Finished exporting: "..GM_asset)
else
	print("Error writing to: "..yy_temp_file)
end