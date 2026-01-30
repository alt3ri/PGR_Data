--- 封装的对话内容随机选择器
--- 针对不同状态下，从文本、表情中随机选择一个
---@class XPokerGuessing2RandomSpeak
local XPokerGuessing2RandomSpeak = XClass(nil, 'XPokerGuessing2RandomSpeak')

local SpeakShowType = {
    Text = 1,
    Emoji = 2,
}

function XPokerGuessing2RandomSpeak:Ctor()
    -- <enum, array<int>> 结构，enum表示对话类型，如胜利/失败
    -- 数组内的int是类型*100+索引，类型表示是文本还是表情
    self._RandomMap = {} 
    self._RandomIndexer = {}
end

function XPokerGuessing2RandomSpeak:AddRandomGroup(textCount, emojiCount, speakPeriod)
    local array = {}

    for i = 1, textCount do
        table.insert(array, SpeakShowType.Text * 100 + i)
    end

    for i = 1, emojiCount do
        table.insert(array, SpeakShowType.Emoji * 100 + i)
    end
    
    -- 洗牌打乱
    XTool.RandomArray(array, os.time(), true)

    self._RandomMap[speakPeriod] = array
    self._RandomIndexer[speakPeriod] = 1
end

--- 重新打乱指定的列表
function XPokerGuessing2RandomSpeak:ReRandomGroup(speakPeriod, noReset)
    local array = self._RandomMap[speakPeriod]

    if array then
        XTool.RandomArray(array, os.time(), true)
    end

    if not noReset then
        self._RandomIndexer[speakPeriod] = 1
    end
end

--- 获取指定列表的随机值
function XPokerGuessing2RandomSpeak:GetRandomValBySpeakPeriod(speakPeriod)
    local array = self._RandomMap[speakPeriod]

    if array then
        local index = self._RandomIndexer[speakPeriod]
        local val = array[index]

        if not val then
            local count = #array

            if count > 0 then
                -- 如果没有值，即索引超过了，那么表示所有类型的反馈都展示过
                -- 此时完全随机即可
                val = array[math.random(1, #array)]
            end
        else
            self._RandomIndexer[speakPeriod] = index + 1
        end
        
        return val
    end
end

return XPokerGuessing2RandomSpeak