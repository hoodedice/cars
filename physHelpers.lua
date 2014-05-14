function force2vec(self,p)
	local output = {x = 0, y = 0, z = 0}
	local alpha = p.dir
	local beta = 180 - 90 - alpha
	local hyp = p.accel
	output.x = (math.sin(alpha) * hyp * -1)
	output.z = (math.sin(beta) * hyp)
	return output
end

function merge_single_forces(x,z)
	return math.sqrt(math.pow(x,2) + math.pow(z,2))
end