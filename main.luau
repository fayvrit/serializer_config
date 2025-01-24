local configs = {}

configs.path = '/ReplicatedStorage/Serialized'

configs.rename_duplicates = false
configs.bracket_property = true
configs.ignore_defaults = true
configs.ignore_nils = true

configs.datatype = {
	udim = 'udim',
	rect = 'rect',
	color3 = 'rgb',
	udim2 = 'udim2',
	vector2 = 'vect2',
	colorsequence = 'rgbseq',
	numbersequence = 'numseq',
	colorsequencekeypoint = 'rgbkey',
	numbersequencekeypoint = 'numkey',
}

configs.variable = function(name)
	return `objects ['{name}']`
end

configs.callback = function(name, class, parent)
	return `{name} = {parent}:new('{class}', \{\n`
end

configs.new_property = function(property, value)
	return `\t{property} = {value};\n`
end

configs.new_instance = function(...)
	local args = {...}

	local name 			= args[1]
	local class 		= args[2]
	local properties 	= args[3]
	local attributes 	= args[4]
	local object 		= args[5]

	local finalize, parent

	-- String Holder
	name = configs.variable(name)
	parent = configs.variable(properties.Parent)

	properties.Parent = nil

	-- String Concationate
	finalize = configs.callback(name, class, parent)

	for property, value in properties do
		finalize ..= configs.new_property(property, value)
	end

	for property, value in attributes do
		finalize ..= configs.new_property(property, value)
	end

	return finalize:sub(1, -3) .. "\n})\n\n"
end
























































-- DUMPS

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
	IGNORE_DEFAULTS = configs.ignore_defaults,
	IGNORE_NILS = configs.ignore_nils_duplicates,
	SCRIPT_PATH = fullpath,
	FORMAT = configs.new_instance,

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
			return `{configs.datatype.udim2}({value.X.Scale}, {value.X.Offset}, {value.Y.Scale}, {value.Y.Offset})`
		end,

		UDim = function(value: UDim)
			return `{configs.datatype.udim.new}({value.Scale}, {value.Offset})`
		end,

		Vector2 = function(value: Vector2)
			return `{configs.datatype.vector2}({value.X}, {value.Y})`
		end,

		Rect = function(value: Rect, types)
			return `{configs.datatype.rect}({types.Vector2(value.Min)}, {types.Vector2(value.Max)})`
		end
	}
}
