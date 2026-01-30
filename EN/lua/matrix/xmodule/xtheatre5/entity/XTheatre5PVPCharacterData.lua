--region 类型定义

---@class XTheatre5PVPCharacter
---@field Id number
---@field Rating number
---@field IsUnlockAnimation boolean
---@field RankProtectNum number
---@field RewardRanks table
---@field FashionId number

--endregion

--- 管理PVP角色的服务端数据（局外数据）
---@class XTheatre5PVPCharacterData
---@field PVPCharacters XTheatre5PVPCharacter[]
local XTheatre5PVPCharacterData = XClass(nil, 'XTheatre5PVPCharacterData')

function XTheatre5PVPCharacterData:ClearData()
    self.PVPCharacters = nil
end

--- 更新PVP角色数据
function XTheatre5PVPCharacterData:UpdatePVPCharacters(characters)
    if XTool.IsTableEmpty(characters) then
        return
    end

    if XTool.IsTableEmpty(self.PVPCharacters) then
        self.PVPCharacters = characters
    else
        for i, characterData in pairs(characters) do
            if XMain.IsEditorDebug then
                if self.PVPCharacters[characterData.Id] then
                    self.PVPCharacters[characterData.Id].IsObsolete = true
                end
            end

            self.PVPCharacters[characterData.Id] = characterData
        end
    end
end

--- 更新角色积分
function XTheatre5PVPCharacterData:UpdatePVPCharacterRating(characterId, rating)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    
    if self.PVPCharacters and self.PVPCharacters[characterId] then
        self.PVPCharacters[characterId].Rating = rating
    end
end

--- 更新角色段位保护次数
function XTheatre5PVPCharacterData:UpdatePVPCharacterRankProtectNum(characterId, rankProtectNum)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if self.PVPCharacters and self.PVPCharacters[characterId] then
        self.PVPCharacters[characterId].RankProtectNum = rankProtectNum
    end
end

--- 更新角色皮肤
function XTheatre5PVPCharacterData:UpdateCharacterFashionId(characterId, fashionId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if self.PVPCharacters and self.PVPCharacters[characterId] then
        self.PVPCharacters[characterId].FashionId = fashionId
    end
end

function XTheatre5PVPCharacterData:GetPVPCharacters()
    return self.PVPCharacters
end

--- 获取指定Id的角色数据（Id是Theatre5Character配置表Id，非characterId）
function XTheatre5PVPCharacterData:GetPVPCharacterById(id, notips)
    if not XTool.IsNumberValid(id) or not self.PVPCharacters or not self.PVPCharacters[id] then
        if not notips then
            XLog.Error('获取PVP角色数据不存在，Id:'..tostring(id))
        end
        return
    end

    return self.PVPCharacters[id]
end

function XTheatre5PVPCharacterData:CheckCharacterIsGetRankReward(characterId, rankId)
    if XTool.IsNumberValid(characterId) and XTool.IsNumberValid(rankId) then
        local charaData = self:GetPVPCharacterById(characterId, true)

        if charaData then
            if not XTool.IsTableEmpty(charaData.RewardRanks) then
                local isIn = table.contains(charaData.RewardRanks, rankId)
                return isIn
            end
        end
    end
    
    return false
end

--- 获取指定Id的角色涂装
function XTheatre5PVPCharacterData:GetCharacterFashionId(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if self.PVPCharacters and self.PVPCharacters[characterId] then
        return self.PVPCharacters[characterId].FashionId
    end
end

--- 获取指定Id的段位保护次数
function XTheatre5PVPCharacterData:GetCharacterRankProtectedNumById(id)
    local data = self:GetPVPCharacterById(id)

    if data then
        return data.RankProtectNum
    end
    
    return 0
end

--- 获取指定Id的段位积分
function XTheatre5PVPCharacterData:GetCharacterRankRatingById(id)
    local data = self:GetPVPCharacterById(id)

    if data then
        return data.Rating
    end

    return 0
end

return XTheatre5PVPCharacterData