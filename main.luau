local configs = {}

configs.path = '/ReplicatedStorage/Serialized'

configs.rename_duplicates = false
configs.bracket_property = true
configs.ignore_defaults = true
configs.ignore_nils = true
configs.rounding = 0.1

configs.skip_property = {
	'Parent',
}

configs.datatype = {
	udim = 'data.udim',
	rect = 'data.rect',
	color3 = 'data.rgb',
	udim2 = 'data.udim2',
	vector2 = 'data.vect2',
	colorsequence = 'data.rgbseq',
	numbersequence = 'data.numseq',
	colorsequencekeypoint = 'data.rgbkey',
	numbersequencekeypoint = 'data.numkey',
}

configs.variable = function(name)
	return `instances ['{name}']`
end

configs.callback = function(name, class, parent)
	-- `{name} = {parent}:new('{class}', \{\n`
	return `{name} = {parent}:new('{class}', \{\n`
end

configs.new_property = function(property, value)
	return `\t{property} = {value};\n`
end

configs.new_instance = function(...)
	local args = {...}

	local name 		= args[1]
	local class 		= args[2]
	local properties 	= args[3]
	local attributes 	= args[4]
	local object 		= args[5]

	local finalize, parent

	-- String Holder
	name = configs.variable(name)
	parent = configs.variable(properties.Parent)

	properties.Parent = parent

	-- String Concationate
	finalize = configs.callback(name, class, parent)

	for property, value in properties do
		if table.find(configs.skip_property, property) then continue end

		finalize ..= configs.new_property(property, value)
	end

	for property, value in attributes do
		if configs.skip_property[property] then continue end

		finalize ..= configs.new_property(property, value)
	end

	return finalize:sub(1, -3) .. "\n})\n\n"
end
























































-- DUMPS

local round = function(num, float) 
	return tonumber(string.format("%.14g", float * math.round(num / float))) 
end

local path = string.split(configs.path, '/')
local fullpath = assert(path[1] == '' and game:GetService(path[2]), 'invalid path')

path[1], path[2] = nil

for index, name in path do
	local parent = fullpath
	fullpath = parent:FindFirstChild(name)

	if fullpath then continue end

	fullpath = Instance.new('Folder')
	fullpath.Parent = parent
	fullpath.Name = name
end

return {
	RENAME_DUPLICATES = configs.rename_duplicates,
	IGNORE_NILS = configs.ignore_nils_duplicates,
	IGNORE_DEFAULTS = configs.ignore_defaults,
	FORMAT = configs.new_instance,
	SCRIPT_PATH = fullpath,

	TYPE_OVERRIDES = {
		Color3 = function(value: Color3)
			return `{configs.datatype.color3}({math.floor(value.R * 255)}, {math.floor(value.G * 255)}, {math.floor(value.B * 255)})`
		end,

		ColorSequenceKeypoint = function(value: ColorSequenceKeypoint, types)
			return `{configs.datatype.colorsequencekeypoint}({math.round(value.Time * 1000) / 1000}, {types.Color3(value.Value)})`
		end,

		ColorSequence = function(value: ColorSequence, types)
			local keypoints = ""

			for i, keypoint in value.Keypoints do
				keypoints ..= `{types.ColorSequenceKeypoint(keypoint, types)}{if i < #value.Keypoints then ", " else ""}`
			end

			return `{configs.datatype.colorsequence}\{{keypoints}}`
		end,

		NumberSequenceKeypoint = function(value: NumberSequenceKeypoint, types)
			return `{configs.datatype.numbersequencekeypoint}({math.round(value.Time * 1000) / 1000}, {value.Value})`
		end,

		NumberSequence = function(value: NumberSequence, types)
			local keypoints = ""

			for i, keypoint in value.Keypoints do
				keypoints ..= `{types.NumberSequenceKeypoint(keypoint, types)}{if i < #value.Keypoints then ", " else ""}`
			end

			return `{configs.datatype.numbersequence}\{{keypoints}}`
		end,

		UDim2 = function(value: UDim2)
			return `{configs.datatype.udim2}({round(value.X.Scale, configs.rounding)}, {value.X.Offset}, {round(value.Y.Scale, configs.rounding)}, {value.Y.Offset})`
		end,

		UDim = function(value: UDim)
			return `{configs.datatype.udim}({round(value.Scale, configs.rounding)}, {value.Offset})`
		end,

		Vector2 = function(value: Vector2)
			return `{configs.datatype.vector2}({value.X}, {value.Y})`
		end,

		Rect = function(value: Rect, types)
			return `{configs.datatype.rect}({types.Vector2(value.Min)}, {types.Vector2(value.Max)})`
		end
	}
}
