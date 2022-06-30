-- コメント落下全体制御用モジュール
---@class CommentsCls @データ同期用クラス
---@field subitem Transform[] @サブアイテム
---@field textitem string[] @テキストアイテム
---@field garbTimes number[] @握った時間
local commentsCls = {}

local fallCommentsControlModule = {}

local DEFINE = require("define_Module")
local FALL_COMMENTS_DEFINE = require("fallCommentsControlDefine_Module")

local micItem = vci.assets.GetTransform("MicItem")
local isGrab = {}
local randDate = {}
local timeDate = 0

---物理初期化
---@param commentNumber number @コメント番号
local function resetPysics(commentNumber)
    if commentsCls.subitem[commentNumber].IsMine then
        commentsCls.subitem[commentNumber].AddForce(Vector3.zero)
        commentsCls.subitem[commentNumber].SetVelocity(Vector3.zero)
        commentsCls.subitem[commentNumber].SetAngularVelocity(Vector3.zero)
        commentsCls.subitem[commentNumber].SetLocalScale(Vector3.__new(0.001, 0.001, 0.001))
        if commentsCls.subitem[commentNumber].IsAttached then
            commentsCls.subitem[commentNumber].DetachFromAvatar()
            commentsCls.subitem[commentNumber].SetPosition(Vector3.__new(commentNumber, -10000, 0))
        end
    end
end

---コメント表示
---@param commentNumber number @コメント番号
---@param char string @コメント
local function commentShow(commentNumber, char)
    vci.assets._ALL_SetText(commentsCls.textitem[commentNumber], char)

end

---コメント落下
---@param commentArray string[] @コメント配列
---@param useArray number[] @使用する配列
---@param charArray string[] @コメント表記配列
---@param state number[] @コメント状態配列
---@param times number[] @コメント時間配列
---@return string[] @コメント配列,コメント状態配列,コメント時間配列更新
local function fallComment(stringArray, useArray, charArray, state, times)
    if (os.clock() - timeDate) > 3 then
        local randNumber = math.random(1, #randDate)
        local randZ = randDate[randNumber]
        table.remove(randDate, randNumber)
        if #randDate == 0 then
            for i = 1, #FALL_COMMENTS_DEFINE.RAND_ARRAY do
                randDate[i] = FALL_COMMENTS_DEFINE.RAND_ARRAY[i]
            end
            timeDate = os.clock()
        end

        randNumber = math.random(1, #FALL_COMMENTS_DEFINE.RAND_ARRAY)
        local randX = FALL_COMMENTS_DEFINE.RAND_ARRAY[randNumber]

        local defaultPosition = Vector3.__new(0, 2.5, 0) + micItem.GetPosition()
        local defaultRotation = micItem.GetRotation() * Quaternion.Euler(0, 180, 0)
        for i = 1, #useArray do
            state[useArray[i]] = FALL_COMMENTS_DEFINE.FALL_STATE
            times[useArray[i]] = 0
            charArray[useArray[i]] = stringArray[i]
            commentShow(useArray[i], stringArray[i])

            commentsCls.subitem[useArray[i]].SetRotation(defaultRotation)
            resetPysics(useArray[i])

            commentsCls.subitem[useArray[i]].SetPosition(defaultPosition + defaultRotation *
                                                             Vector3.__new(0.37 * ((i - #useArray / 2 - 0.5) + randX),
                    0.07 * randZ, 0.25 * randZ))
            commentsCls.subitem[useArray[i]].SetLocalScale(Vector3.__new(1.5, 1.5, 1.5))
        end
    end
    return charArray, state, times
end

---文字列分解
---@param comment string @1行のコメント
---@return string[] @コメント配列
local function stringToCharArray(comment)
    local str = {}
    -- 文字を分割
    local count = 1
    while count <= string.len(comment) do
        local addCount = 0
        -- 1文字分抜き出し(本体)
        local splitComment = string.sub(comment, count, count)
        -- 次の文字あり
        while (count + addCount + 1) <= string.len(comment) do
            -- 1文字分抜き出し
            splitComment = string.sub(comment, count + addCount + 1, count + addCount + 1)
            if FALL_COMMENTS_DEFINE.LOW_SURROGATE_ARRAY[splitComment] then
                addCount = addCount + 1
                splitComment = string.sub(comment, count, count + addCount)
            elseif FALL_COMMENTS_DEFINE.ZWJ_ARRAY[splitComment] then
                addCount = addCount + 2
            elseif FALL_COMMENTS_DEFINE.VARIATION_SELECTOR_ARRAY[splitComment] then
                splitComment = string.sub(comment, count, count + addCount)
                addCount = addCount + 1
                break
            else
                splitComment = string.sub(comment, count, count + addCount)
                break
            end
        end
        if #splitComment > 2 then
            splitComment = "\u{26A0}"
        end

        -- 文字を配列に入力
        str[#str + 1] = splitComment
        -- 次の文字探索
        count = count + addCount + 1
    end
    return str
end

---コメント空白検索
---@param commentArray string[] @コメント配列
---@param state number[] @コメント状態配列
---@return number[] @コメントで使用する番号の配列
local function stateVoidCheck(commentArray, state)
    local useArray = {}
    for i = 1, #state do
        if state[i] == FALL_COMMENTS_DEFINE.NO_STATE then
            useArray[#useArray + 1] = i
            -- 最大文字数か、コメント数
            if (FALL_COMMENTS_DEFINE.STRING_MAX == #useArray) or (#commentArray == #useArray) then
                return useArray
            end
        end
    end
    return {}
end

---コメント時間経過による削除
---@param commentNumber number @コメント番号
---@param charArray string[] @コメント表記配列
---@param state number[] @コメント状態配列
---@param times number[] @コメント時間配列
---@return string[],number[],number[] @コメント表記配列,コメント状態配列,コメント時間配列更新
local function timeDelete(commentNumber, charArray, state, times)
    if times[commentNumber] >= FALL_COMMENTS_DEFINE.DELETE_TIME then
        charArray[commentNumber] = ""
        state[commentNumber] = FALL_COMMENTS_DEFINE.DELETE_STATE
        times[commentNumber] = 0
        commentShow(commentNumber, charArray[commentNumber])
    end
    return charArray, state, times
end

-- 装着等処理
---@param ownerName string @オーナー名
---@param commentNumber number @コメント番号
---@param state number[] @コメント状態配列
---@return number[] @コメント状態配列
local function attachDelete(ownerName, commentNumber, state)
    if not isGrab[commentNumber] then
        -- 所有権があり、削除中
        if commentsCls.subitem[commentNumber].IsMine and (state[commentNumber] == FALL_COMMENTS_DEFINE.DELETE_STATE) then
            -- 装着前(所有権移る前)ならば
            if not commentsCls.subitem[commentNumber].IsAttached then
                resetPysics(commentNumber)
                -- 追従ボーン情報(Local)
                local followBone = nil
                local avater = vci.studio.GetAvatars()
                for count = 1, #avater do
                    -- オーナーのアバター取得
                    if ownerName == avater[count].GetName() then
                        followBone = avater[count].GetBoneTransform("Head")
                        break
                    end
                end

                if followBone ~= nil then
                    commentsCls.subitem[commentNumber].SetPosition(followBone.position)
                    commentsCls.subitem[commentNumber].AttachToAvatar()
                end
            else
                resetPysics(commentNumber)
                state[commentNumber] = FALL_COMMENTS_DEFINE.WAIT_STATE
            end
        end
        if commentsCls.subitem[commentNumber].IsMine then
            if (not commentsCls.subitem[commentNumber].IsAttached) and
                (state[commentNumber] == FALL_COMMENTS_DEFINE.WAIT_STATE) then
                state[commentNumber] = FALL_COMMENTS_DEFINE.NO_STATE
            elseif (commentsCls.subitem[commentNumber].IsAttached) then
                resetPysics(commentNumber)
            elseif (state[commentNumber] == FALL_COMMENTS_DEFINE.NO_STATE) then
                resetPysics(commentNumber)
            end
        end
    end

    return state
end

---ここ自体初期化
local function initialize()
    commentsCls.subitem = {}
    commentsCls.textitem = {}
    commentsCls.garbTimes = {}
    -- サブアイテム情報追加
    for i = 1, 1000 do
        local subitem = vci.assets.GetTransform(FALL_COMMENTS_DEFINE.STR_CHAR .. i .. ")")
        if subitem == nil then
            break
        end
        commentsCls.subitem[i] = subitem
        commentsCls.textitem[i] = FALL_COMMENTS_DEFINE.STR_CHAR_TXT .. i .. ")"
        commentsCls.garbTimes[i] = 0
        resetPysics(i)
        if commentsCls.subitem[i].IsMine then
            commentsCls.subitem[i].SetPosition(Vector3.__new(i, -100000, 1))
            commentsCls.subitem[i].SetLocalScale(Vector3.__new(1.5, 1.5, 1.5))
        end
        isGrab[i] = false
    end

    for i = 1, #FALL_COMMENTS_DEFINE.RAND_ARRAY do
        randDate[i] = FALL_COMMENTS_DEFINE.RAND_ARRAY[i]
    end
end

---コメント落下処理
---@param comment string @1行のコメント
---@param charArray string[] @コメント表記配列
---@param state number[] @コメント状態配列
---@param times number[] @コメント時間配列
---@return boolean,string[],number[],number[] @コメント落下可否,コメント表記配列,コメント状態配列,コメント時間配列更新
function fallCommentsControlModule.fallComment(comment, charArray, state, times)
    local stringArray = stringToCharArray(comment)
    local useArray = stateVoidCheck(stringArray, state)
    -- コメント投下できる状態ならば
    if #useArray > 0 then
        if #stringArray > FALL_COMMENTS_DEFINE.STRING_MAX then
            local data = {}
            for count = #stringArray - FALL_COMMENTS_DEFINE.STRING_MAX + 1, #stringArray do
                data[#data + 1] = stringArray[count]
            end
            stringArray = data
        end
        charArray, state, times = fallComment(stringArray, useArray, charArray, state, times)
        return true, charArray, state, times
    end
    return false, charArray, state, times
end

-- コメント制御処理
---@param ownerName string @オーナー名
---@param charArray string[] @コメント表記配列
---@param state number[] @コメント状態配列
---@param times number[] @コメント時間配列
function fallCommentsControlModule.commentControl(ownerName, charArray, state, times)
    for count = 1, #state do
        -- 落下対象ならば
        if state[count] == FALL_COMMENTS_DEFINE.FALL_STATE then
            commentsCls.subitem[count].AddForce(Vector3.__new(0, -1, 0), vci.forceMode.Force)
            charArray, state, times = timeDelete(count, charArray, state, times)
        elseif state[count] == FALL_COMMENTS_DEFINE.FIX_STATE then
            -- 握ってないとき
            if not isGrab[count] then
                -- コメントの物理リセット
                commentsCls.subitem[count].AddForce(Vector3.zero)
                commentsCls.subitem[count].SetVelocity(Vector3.zero)
                commentsCls.subitem[count].SetAngularVelocity(Vector3.zero)
            end
        end
        -- 装着等処理
        state = attachDelete(ownerName, count, state)
    end
    return charArray, state, times
end

-- コメント時間経過処理
---@param state number[] @コメント状態配列
---@param times number[] @コメント時間配列
---@param addTime number @時間経過
---@return number[] @コメント時間配列更新
function fallCommentsControlModule.addTime(state, times, addTime)
    for count = 1, #times do
        -- 落下時のみ時間経過
        if state[count] == FALL_COMMENTS_DEFINE.FALL_STATE then
            times[count] = times[count] + addTime
        end
    end
    return times
end

-- コメント同期処理
---@param charArray string[] @コメント表記配列
function fallCommentsControlModule.commentSync(charArray)
    for count = 1, #charArray do
        commentShow(count, charArray[count])
    end
end

-- サブアイテム数返す
---@return number @サブアイテム数
function fallCommentsControlModule.getSubitemCount()
    return #commentsCls.subitem
end

-- use関係
---@param target string @名称
---@param state number[] @コメント状態配列
function fallCommentsControlModule.onUse(use, state)
    for count = 1, #commentsCls.subitem do
        if use == commentsCls.subitem[count].GetName() then
            -- 落下中のみ
            if ((state[count] == FALL_COMMENTS_DEFINE.FALL_STATE) or (state[count] == FALL_COMMENTS_DEFINE.GRAB_STATE)) then
                ---同期メッセージ(タスク追加)
                DEFINE.controlAddMessage(0, 0, count, FALL_COMMENTS_DEFINE.FIX_STATE, DEFINE.CONTROLKEY_USE)
            elseif state[count] == FALL_COMMENTS_DEFINE.FIX_STATE then
                ---同期メッセージ(タスク追加)
                DEFINE.controlAddMessage(0, 0, count, FALL_COMMENTS_DEFINE.DELETE_STATE, DEFINE.CONTROLKEY_USE)
            end
            commentsCls.garbTimes[count] = os.clock()
            break
        end
    end
end

-- unuse関係
---@param target string @名称
---@param state number[] @コメント状態配列
function fallCommentsControlModule.onUnuse(use, state)
    for count = 1, #commentsCls.subitem do
        if use == commentsCls.subitem[count].GetName() then
            -- 削除開始時間だったらば
            if (os.clock() - commentsCls.garbTimes[count]) >= FALL_COMMENTS_DEFINE.DELETE_USE_TIME then
                -- 落下中,固定中のみ
                if (state[count] == FALL_COMMENTS_DEFINE.FALL_STATE) or (state[count] == FALL_COMMENTS_DEFINE.FIX_STATE) or
                    (state[count] == FALL_COMMENTS_DEFINE.GRAB_STATE) then ---同期メッセージ(タスク追加)
                    DEFINE.controlAddMessage(0, 0, count, 0, DEFINE.CONTROLKEY_DELETE)
                end
            end
            break
        end
    end
end

-- grab関係
---@param target string @名称
---@param state number[] @コメント状態配列
function fallCommentsControlModule.onGrab(item, state)
    for count = 1, #commentsCls.subitem do
        if item == commentsCls.subitem[count].GetName() then
            -- 落下中のみ
            if state[count] == FALL_COMMENTS_DEFINE.FALL_STATE then
                ---同期メッセージ(タスク追加)
                DEFINE.controlAddMessage(0, 0, count, FALL_COMMENTS_DEFINE.GRAB_STATE, DEFINE.CONTROLKEY_GRAB)
            end
            isGrab[count] = true
            break
        end
    end
end

-- ungrab関係
---@param target string @名称
---@param state number[] @コメント状態配列
function fallCommentsControlModule.onUngrab(target, state)
    for count = 1, #commentsCls.subitem do
        if target == commentsCls.subitem[count].GetName() then
            -- 落下中のみ
            if state[count] == FALL_COMMENTS_DEFINE.GRAB_STATE then
                ---同期メッセージ(タスク追加)
                DEFINE.controlAddMessage(0, FALL_COMMENTS_DEFINE.DELETE_TIME - FALL_COMMENTS_DEFINE.DELETE_GRAB_TIME,
                    count, FALL_COMMENTS_DEFINE.FALL_STATE, DEFINE.CONTROLKEY_GRAB)
            end
            isGrab[count] = false
            break
        end
    end
end

initialize()

return fallCommentsControlModule
