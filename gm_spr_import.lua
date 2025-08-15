-- This lua script lets you open an Aseprite animation directly from Gamemaker, and syncronise any changes!

------------------
-- >> CONFIG << --
------------------
console_log = true
delete_pre_renamed_ase_file = true -- Delete the old ase file after renaming. Note that this will delete the first found ase file in the sprite's directory. Recommended to leave at "true"

------------------------
-- Requirements
------------------------
local json = require"json" --Allows you to load and save json files: https://github.com/dacap/export-aseprite-file/blob/master/json.lua

-- Functions
------------------------------------
function print_c(string)
	if console_log == true then
		print(string)
	end
end

-- Returns either the original value if it existed or the provided coalescent
function parse_error(value, coalescent)
	if value == nil then
		return coalescent
	else
		return value
	end
end

function string_get_pos(string, sub)
	return string:match(".*"..sub.."()")
end

-- Returns parsed json from the sprite's YY file 
function open_yy_file(filename)
	local haystack = app.fs.filePath(app.sprite.filename)
	local needle = app.fs.pathSeparator
	
	-- Get YY filename and path
	local fileYY_name = haystack:sub(haystack:match(".*"..needle.."()"), haystack:len())
	local filePath = haystack .. app.fs.pathSeparator .. fileYY_name .. ".yy"
	
	-- Open the YY file and parse its json data
	local file = io.open(filePath)
	if not file then
		error("Could not open file: " .. filePath)
	end
	
	local js = ""
	for line in file:lines() do
		js = js .. line
	end
	file:close()
	
	-- Fix null values disappearing
	js = js:gsub('null', '"null"')
	
	-- Parse JSON and return
	local parsed_js = json.decode(js)
	return parsed_js
end

-- Safe file operations with error handling
function safe_file_operation(operation)
	local success, result = pcall(operation)
	if not success then
		print_c("File operation failed: " .. tostring(result))
		return nil
	end
	return result
end

-- Ensure directory exists
function ensure_directory(path)
	local success = pcall(function()
		os.execute('powershell -Command "New-Item -ItemType Directory -Force -Path \\"' .. path .. '\\""')
	end)
	return success
end

function main()
	local spr = app.sprite -- Active sprite
	
	-- Get Sprite's filename and directory
	local filename = app.sprite.filename
	local directory = app.fs.filePath(app.sprite.filename)
	print_c("dir: " .. directory)
	
	-- Attempt to load Ase file
	local gmAsset = directory:sub(directory:match(".*"..app.fs.pathSeparator.."()"), directory:len())
	print_c("GM Asset: "..gmAsset)
	
	if filename == directory..app.fs.pathSeparator..gmAsset..".ase" then
		print_c("File "..gmAsset.." is already open")
	else
		local newSprite = safe_file_operation(function()
			return Sprite{ fromFile = directory..app.fs.pathSeparator..gmAsset..".ase" }
		end)
		
		-- Search directory for ase file if not found
		if newSprite == nil then
			local p = io.popen('powershell -Command "Get-ChildItem -LiteralPath \\"'..directory..'\\" -File | Select-Object -ExpandProperty Name"')
			
			if p then
				for file in p:lines() do
					if file:match("%.ase$") then
						newSprite = safe_file_operation(function()
							return Sprite{ fromFile = directory..app.fs.pathSeparator..file }
						end)
						
						if newSprite and delete_pre_renamed_ase_file == true then
							safe_file_operation(function()
								os.remove(directory..app.fs.pathSeparator..file)
							end)
						end
						
						print_c("Aseprite file or GM asset was renamed!")
						print_c("Renamed " .. file.." -> "..gmAsset..".ase")
						break
					end
				end
				p:close()
				
				-- IF NOTHING FOUND - Generate new sprite from YY
				if newSprite == nil then
					-- Make sure we have the YY data
					local js = open_yy_file(spr.filename)
					if not js or not js.sequence or not js.sequence.tracks or not js.sequence.tracks[1] then
						print_c("Error: Invalid YY file structure")
						return
					end
					
					local frames = js.sequence.tracks[1].keyframes.Keyframes
					local newAse = nil
					local oldAse = app.sprite
					
					-- Import frames
					for i, frame in ipairs(frames) do
						if not frame.Channels or not frame.Channels["0"] or not frame.Channels["0"].Id then
							print_c("Warning: Skipping invalid frame " .. i)
							goto continue
						end
						
						local frame_name = frame.Channels["0"].Id.name
						local newFrameFile = directory..app.fs.pathSeparator.. frame_name .. ".png"
						
						if i < 2 then -- Load first frame
							newAse = safe_file_operation(function()
								return Sprite{fromFile=newFrameFile}
							end)
							
							if newAse then
								app.command.SaveFileAs{
									ui = false,
									filename = directory..app.fs.pathSeparator..gmAsset..".ase"
								}
							end
						else -- Load new frame
							if newAse then
								local img = safe_file_operation(function()
									return Image{fromFile=newFrameFile}
								end)
								
								if img then
									local newFrame = newAse:newEmptyFrame()
									newAse:newCel(app.activeLayer, newFrame, img)
								end
							end
						end
						
						::continue::
					end
					
					-- Close original and switch to new ASEPRITE file
					if newAse then
						oldAse:close()
						app.sprite = newAse
						print_c("Successfully created new aseprite for "..gmAsset.."!")
						
							-- Save ASEPRITE file
						app.command.SaveFileAs{
							ui = false,
							filename = directory..app.fs.pathSeparator..gmAsset..".ase"
						}
					else
						print_c("Failed to create new aseprite file")
						return
					end
				end
			end
		else
			-- Load existing ase file
			spr:close()
			app.sprite = newSprite
			print_c("Successfully loaded existing aseprite for "..gmAsset.."!")
		end
	end
	

	
end -- eof Main()

------------------------
-- RUN SCRIPT
------------------------
local spr = app.sprite

-- Pre-script checks
if not spr then -- No sprite is open
	app.alert("No sprite is currently open.")
	return
end

-- Sprite not saved
if not app.sprite.filename or app.sprite.filename:match(".*"..app.fs.pathSeparator.."()") == nil then
	app.command.SaveFile{}
else -- Check if is GM asset
	-- Check if this is a gamemaker sprite
	local success, js = pcall(open_yy_file, spr.filename)
	
	if not success or js == nil then
		app.command.SaveFile{ui = false} -- Save normally when not a GM sprite
	else
		main() -- Open and Export sprite
	end
end