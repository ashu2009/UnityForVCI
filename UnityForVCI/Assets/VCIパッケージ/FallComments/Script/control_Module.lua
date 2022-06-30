-- 全体制御用モジュール
---@class SyncCls @データ同期用クラス
---@field stackTasks ContorolTaskCls[] @制御情報積んである[個数]：タスク
---@field isNoTaskSkip boolean @一部積みタスクスキップ時使用
---@field comments string[] @未送信コメント配列
---@field commentsState number[] @subitem文字状態
---@field commentsTime number[] @文字生存している時間
---@field commentsChar string[] @表示文字
---@field ownerName string @オーナー名
local syncCls = {}

local controlModule = {}

local DEFINE = require("define_Module")
local fallCommentsControlModule = require("fallCommentsControl_Module")
local FALL_COMMENTS_DEFINE = require("fallCommentsControlDefine_Module")
local SYNC_TIME = 1
local syncTime = os.clock()

---スタジオのコメントを追加
---@param message string @コメント内容
local function addCommentArrayFromStadio(message)
    syncCls.comments[#syncCls.comments + 1] = message
end

---ルームでのコメントを追加
---@param message string @コメント内容
local function addCommentArrayFromRoom(message)
    syncCls.comments[#syncCls.comments + 1] = message
end

---スタジオのコメントor"comment"で送られたメッセージに反応
---@param sender any @-
---@param name any @-
---@param message string @コメント内容
local function handleGetCommentMessage(sender, name, message)
    -- 所有権ある人のみ
    if DEFINE.SYNC_ITEM.IsMine then
        -- スタジオのコメント
        if sender["type"] == "comment" then
            print("stadio:" .. message)
            ---スタジオのコメントを追加
            addCommentArrayFromStadio(message)

        elseif sender["type"] == "vci" then
            print("room:" .. message)
            ---ルームでのコメントを追加
            addCommentArrayFromRoom(message)
        end
    end
end
vci.message.On("comment", handleGetCommentMessage)

---使用タスク削除
---@param noSkip boolean @スキップなし有無
---@param stackTasks ContorolTaskCls @タスク保持情報
---@param taskCount number @タスク番号
---@return ContorolTaskCls[],number @タスク削除後情報,タスク番号
local function taskDelete(noSkip, stackTasks, taskCount)
    if noSkip then
        stackTasks = table.remove(stackTasks, taskCount)
        taskCount = taskCount - 1
    end
    return stackTasks, taskCount
end

---タスクを積む
---@param sender any @-
---@param name any @-
---@param message ContorolTaskCls @操作追加したい値
local function handleSetAddControl(sender, name, message)
    syncCls.stackTasks[#syncCls.stackTasks + 1] = message
end
vci.message.On(DEFINE.MESSAGEKEY_CONTROL_ADD, handleSetAddControl)

---ここ自体初期化
local function initialize()
    -- クラス
    syncCls.stackTasks = {}
    syncCls.isNoTaskSkip = true
    syncCls.comments = {}
    -- syncCls.comments[1] = "コメントブロックが落下してない　デバック中？"
    -- syncCls.comments[2] = "ながいこめんと""🧛🏻"
    -- syncCls.comments[3] = "みじかいこめんと"
    syncCls.commentsState = {}
    syncCls.commentsChar = {}
    syncCls.commentsTime = {}
    for i = 1, fallCommentsControlModule.getSubitemCount() do
        syncCls.commentsState[i] = FALL_COMMENTS_DEFINE.NO_STATE
        syncCls.commentsChar[i] = ""
        syncCls.commentsTime[i] = 0
    end
    syncCls.ownerName = ""

    -- モジュール
    controlModule.isSynced = false
end

---ここでの全同期メッセージ
local function allSyncMessage()
    syncCls.ownerName = vci.studio.GetLocalAvatar().GetName()
    -- 増減や変更を同期
    vci.message.EmitWithId(DEFINE.MESSAGEKEY_SYNC_ALL, syncCls, vci.assets.GetInstanceId())
end

---全同期
---@param sender any @-
---@param name any @-
---@param message SyncCls @同期したい値
local function handleSetCurrentAllData(sender, name, message)
    -- 同期
    syncCls = message

    -- 同期完了フラグ
    controlModule.isSynced = true
end
vci.message.On(DEFINE.MESSAGEKEY_SYNC_ALL, handleSetCurrentAllData)

-- 積まれているタスクの処理
vci.StartCoroutine(coroutine.create(function()
    local taskCount = 1
    local coltineTimer = os.clock()
    local coltineTimerCount = 1 / 85
    while true do
        -- 同期用所有権アイテム
        if DEFINE.SYNC_ITEM.IsMine then
            -- タスクがあれば
            while #syncCls.stackTasks ~= 0 do
                -- タスク長いので保持
                local task = syncCls.stackTasks[taskCount]
                -- タスクスキップあれば処理
                if task.controlNum == DEFINE.CONTROLKEY_TASK_SKIP then
                    syncCls.isNoTaskSkip = false
                    table.remove(task, taskCount)
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_TASK_SKIP_END then
                    syncCls.isNoTaskSkip = true
                    table.remove(task, taskCount)
                    allSyncMessage()
                    break
                end

                -- タスクメイン処理
                if task.controlNum == DEFINE.CONTROLKEY_ENTER_ROOM then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    -- コメント同期処理
                    fallCommentsControlModule.commentSync(syncCls.commentsChar)
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_TIME_SYNC then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_STATE_SYNC then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_GRAB then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    -- 落下中のみ
                    if (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.FALL_STATE) and
                        (task.toWhat == FALL_COMMENTS_DEFINE.GRAB_STATE) then
                        syncCls.commentsState[task.what] = task.toWhat
                    elseif (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.GRAB_STATE) and
                        (task.toWhat == FALL_COMMENTS_DEFINE.FALL_STATE) then
                        syncCls.commentsTime[task.what] = task.toWhom
                        syncCls.commentsState[task.what] = task.toWhat
                    end
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_USE then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    -- 落下中、grab中のみ
                    if ((syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.FALL_STATE) or
                        (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.GRAB_STATE)) and
                        (task.toWhat == FALL_COMMENTS_DEFINE.FIX_STATE) then
                        syncCls.commentsState[task.what] = task.toWhat
                    elseif (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.FIX_STATE) and
                        (task.toWhat == FALL_COMMENTS_DEFINE.DELETE_STATE) then
                        syncCls.commentsState[task.what] = task.toWhat
                        syncCls.commentsChar[task.what] = ""
                    end
                    allSyncMessage()
                    break
                elseif task.controlNum == DEFINE.CONTROLKEY_DELETE then
                    syncCls.stackTasks, taskCount = taskDelete(syncCls.isNoTaskSkip, syncCls.stackTasks, taskCount)
                    -- 固定中のみ
                    if ((syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.FALL_STATE) or
                        (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.FIX_STATE) or
                        (syncCls.commentsState[task.what] == FALL_COMMENTS_DEFINE.GRAB_STATE)) then
                        syncCls.commentsState[task.what] = FALL_COMMENTS_DEFINE.DELETE_STATE
                    end
                    allSyncMessage()
                    break
                end

                -- 次タスク
                taskCount = taskCount + 1
                -- タイミングでの同期
                if #syncCls.stackTasks == 0 or (os.clock() - coltineTimer) > coltineTimerCount then
                    allSyncMessage()
                    coroutine.yield()
                    coltineTimer = os.clock()
                end
            end
        end

        coroutine.yield()
        coltineTimer = os.clock()
        taskCount = 1
    end
end))

-- 通常処理
function updateAll()
    -- コメント制御処理
    fallCommentsControlModule.commentControl(syncCls.ownerName, syncCls.commentsChar, syncCls.commentsState,
        syncCls.commentsTime)

    -- 同期用所有権アイテム
    if DEFINE.SYNC_ITEM.IsMine then
        -- コメント有
        if #syncCls.comments > 0 then
            -- コメント落下出来たら落下コメント削除
            local enable = false
            enable, syncCls.commentsChar, syncCls.commentsState, syncCls.commentsTime =
                fallCommentsControlModule.fallComment(syncCls.comments[1], syncCls.commentsChar, syncCls.commentsState,
                    syncCls.commentsTime)
            if enable then
                table.remove(syncCls.comments, 1)
                ---同期メッセージ(タスク追加)
                DEFINE.controlAddMessage(0, 0, 0, 0, DEFINE.CONTROLKEY_STATE_SYNC)
            end
        end

        -- 時間同期
        local time = os.clock() - syncTime
        if time >= SYNC_TIME then
            syncTime = os.clock()
            syncCls.commentsTime = fallCommentsControlModule.addTime(syncCls.commentsState, syncCls.commentsTime, time)
            ---時間同期メッセージ(タスク追加)
            DEFINE.controlAddMessage(0, 0, 0, 0, DEFINE.CONTROLKEY_TIME_SYNC)
        end
    end
end

function controlModule.onUse(use)
    fallCommentsControlModule.onUse(use, syncCls.commentsState)
end

function controlModule.onUnuse(use)
    fallCommentsControlModule.onUnuse(use, syncCls.commentsState)
end

function controlModule.onTriggerEnter(item, hit)
end

function controlModule.onTriggerExit(item, hit)
end

function controlModule.onCollisionEnter(item, hit)
end

function controlModule.onCollisionExit(item, hit)
end

function controlModule.onGrab(target)
    fallCommentsControlModule.onGrab(target, syncCls.commentsState)
end

function controlModule.onUngrab(target)
    fallCommentsControlModule.onUngrab(target, syncCls.commentsState)
end

initialize()

return controlModule
