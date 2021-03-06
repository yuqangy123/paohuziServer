
local card = {}
card.id = 0
card.value = 0
card.capital = false

function card:set(value, isCapital, id)
	self.value = value
	self.capital = isCapital
	self.id = id
end
function card:values()
	return self.value * 10 + (self.capital and 1 or 0)
end
function card:equal(ecard)
	return self.value == ecard.value and self.capital == ecard.capital
end
function card:same(ecard)
	return self.value == ecard.value
end




function card:msgString()
	return string.format("%d_%d_%d", self.value, self.capital and 1 or 0, self.id)
end

return card