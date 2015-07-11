function scalar2vec(self,p)
	local output = {x = 0, y = 0, z = 0}
	local alpha = p.dir
	local beta = math.pi - math.pi / 2 - alpha
	local hyp = p.scalar
	output.x = (math.sin(alpha) * hyp * -1)
	output.z = (math.sin(beta) * hyp)
	return output
end

function merge_single_forces(x,z)
	return math.sqrt(math.pow(x,2) + math.pow(z,2))
end

function vector.resulting(vecs)
	local res = {x = 0, y = 0, z = 0}
	local allX = {}
	local allY = {}
	local allZ = {}

	for k, v in pairs(vecs) do
		table.insert(allX, v.x)
		table.insert(allY, v.y)
		table.insert(allZ, v.z)
	end

	for k, v in pairs(allX) do
		res.x = res.x + v
	end
	res.x = res.x / #allX
	
	for k, v in pairs(allY) do
		res.y = res.y + v
	end
	res.y = res.y / #allY
	
	for k, v in pairs(allZ) do
		res.z = res.z + v
	end
	res.z = res.z / #allZ
	
	return res
end