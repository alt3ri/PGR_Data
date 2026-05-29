-- require("XCommon/XClass")
-- require("XCommon/XGlobalFunc")

local function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

---------------------------------------------------------------
-- @class module
-- @name Stack
-- @author liqiang
local Stack = XClass(nil, "Stack")

--[[--
得到栈内元素数量
@treturn number size 元素个数
]]
function Stack:size()
	return #self
end

--[[--
栈是否为空
@treturn boolean b true为空,否则为不空
]]
function Stack:empty()
	return (self:size() == 0)
end

--[[--
出栈
@treturn void value 返回删除的元素,空返回nil
]]
function Stack:pop()
	local tmp = self:top()
	table.remove(self)
	return tmp
end

--[[--
入栈
@tparam void value 入栈的元素
@treturn number size 入栈后元素个数
]]
function Stack:push(value)
	table.insert(self, value)
	return self:size()
end

--[[--
得到栈顶元素
@treturn void value 栈顶元素,空返回nil
]]
function Stack:top()
	local size = self:size()
	if size == 0 then
		return nil
	end
	return self[size]
end

---@class XArithmetic
local XArithmetic = XClass(nil, "XArithmetic")

local defaultOperatorLevel = {
	["+"] = 0,
	["-"] = 0,
	["("] = 10,
	["*"] = 1,
	["/"] = 1,
	[")"] = 0,
	["<"] = 1,
	[">"] = 1,
	["^"] = 2,
}

local defaultOperatorPattern = {
	["%+"] = "+",
	["%-"] = "-",
	["%("] = "(",
	["%*"] = "*",
	["/"] = "/",
	["%)"] = ")",
	["<"] = "<",
	[">"] = ">",
	["%^"] = "^",
}

local charsReg = "^%a+%d*$"

function XArithmetic:Ctor(enableCache)
	self.OperatorLevel = defaultOperatorLevel
	self.OperatorPattern = defaultOperatorPattern
	self.UnaryOperators = {}    -- 子类按需注册一元运算符：self.UnaryOperators["!"] = true
	self.GetVariableDelegate = nil
	self.StackContainer = Stack.New()
	self.EnableCache = enableCache
	if enableCache then
		self.CacheDict = {}
	end
end

function XArithmetic:SetTextValueHandler(handle)
	self.GetVariableDelegate = handle
end

function XArithmetic:Calculate(expression)
	if self.EnableCache then
		if self.CacheDict[expression] then
			return self:GetResult(self.CacheDict[expression])
		end
		local rpnExperssion = self:ConvertToRPN(self:InsertBlank(expression))
		local list = split(rpnExperssion, " ")
		self.CacheDict[expression] = list
		return self:GetResult(list)
	else
		local rpnExperssion = self:ConvertToRPN(self:InsertBlank(expression))
		return self:GetResultByExperssion(rpnExperssion)
	end
end

function XArithmetic:GetValue(left, right, operator)
	if "+" == operator then
		return left + right
	elseif "-" == operator then
		return left - right
	elseif "*" == operator then
		return left * right
	elseif "/" == operator then
		return left / right
	elseif "<" == operator then
		return math.min(left, right)
	elseif ">" == operator then
		return math.max(left, right)
	elseif "^" == operator then
		return math.pow(left, right)
	end
	XLog.Warning("XArithmetic:GetValue error! operator: %s", operator)
	return 0
end

-- 一元运算符默认实现，子类按需覆写。仅在 self.UnaryOperators[operator] 为真时被调用
function XArithmetic:GetUnaryValue(operand, operator)
	XLog.Warning("XArithmetic:GetUnaryValue not implemented for operator: %s", tostring(operator))
	return operand
end

function XArithmetic:GetResult(list)
	local operatorLevel = self.OperatorLevel
	local unaryOperators = self.UnaryOperators
	self:ClearArray(self.StackContainer)
	local stack = self.StackContainer
	for i, current in ipairs(list) do
		if tonumber(current) then
			stack:push(tonumber(current))
		elseif string.match(current, charsReg) then
			stack:push(current)
		elseif unaryOperators and unaryOperators[current] then
			local operand = self:GetValueByText(stack:pop())
			stack:push(self:GetUnaryValue(operand, current))
		elseif operatorLevel[current] then
			local right = self:GetValueByText(stack:pop())
			local left = self:GetValueByText(stack:pop())
			stack:push(self:GetValue(left, right, string.sub(current, 1, 1)))
		end
	end
	return stack:pop(), #stack
end

function XArithmetic:GetResultByExperssion(source)
	local list = split(source, " ")
	return self:GetResult(list)
end

function XArithmetic:GetValueByText(text)
	if self.GetVariableDelegate then
		return self.GetVariableDelegate(text)
	end
	if tonumber(text) then
		return tonumber(text)
	end
	XLog.Warning("XArithmetic.GetVariableDelegate == nil")
	return 1
end

function XArithmetic:ConvertToRPN(source)
	local operatorLevel = self.OperatorLevel
	local result = ""
	self:ClearArray(self.StackContainer)
	local stack = self.StackContainer
    local list = split(source, " ")
    for i, current in ipairs(list) do
    	-- log("current %s", current)
        if tonumber(current) then
			result = result..current.." "
		elseif string.match(current, charsReg) then
			result = result..current.." "
		elseif operatorLevel[current] then
			if #stack > 0 then
				local prev = stack:top()
				-- log("prev %s", prev)
				if prev == "(" then
					stack:push(current)
				elseif current == "(" then
					stack:push(current)
				elseif current == ")" then
					while #stack > 0 and stack:top() ~= "(" do
						result = result..stack:pop().." "
					end
					--Pop the "("
					if #stack > 0 and stack:top() == "(" then
						stack:pop()
					end
				elseif self.UnaryOperators[current] then
					-- 一元运算符右结合：不弹同级别栈顶，直接入栈
					stack:push(current)
				elseif operatorLevel[current] <= operatorLevel[prev] then
					while #stack > 0 do
						local top = stack:pop()
						if top ~= "(" and top ~= ")" and operatorLevel[current] <= operatorLevel[top] then
							result = result..top.." "
						else
							-- break
							stack:push(top)
							break
						end
					end
					stack:push(current)
				else
					stack:push(current)
				end
			else
				stack:push(current)
			end
		end

		local text = ""
		local i = 1
		while stack[i] ~= nil do
			text = text.." "..stack[i]
			i = i + 1
		end
		-- log("                   "..text)
	end
	if #stack > 0 then
		while #stack > 0 do
			local top = stack:pop()
			if top ~= "(" and top ~= ")" then
				result = result..top.." "
			end
		end
	end
	-- log(result)
	return result
end

function XArithmetic:InsertBlank(source)
	for p, v in pairs(self.OperatorPattern) do
		source = string.gsub(source, p, " "..v.." ")
	end
	return source
end

function XArithmetic:ClearArray(array)
	if XTool.IsTableEmpty(array) then
		return
	end
	for i,_ in ipairs(array) do
		array[i] = nil
	end	
end

return XArithmetic

-- local function Test(expression, result)
-- 	local realyResult = XArithmetic:Calculate(expression);
-- 	XLog.Warning(realyResult, result)
-- 	if realyResult ~= result then
-- 		XLog.Warning("Formula.Calculate(\"%s\") != %d, realy result = %d", expression, result, realyResult)
-- 	else
-- 		XLog.Debug("XArithmetic test ok")
-- 	end 
-- end

-- XLog.Warning("===========asdasd")
-- Test("4-2-1+3", 4)
-- Test("1+1*(2+1)-3.8/2 + 1 * (2+1)", 5.1)
-- Test("1000+0+0+0+0-0-0-0+0-100-0-0-0", 900)
-- Test("1000-0-100", 900)
-- Test("0-2*(3+4*6/5)", -15.6)