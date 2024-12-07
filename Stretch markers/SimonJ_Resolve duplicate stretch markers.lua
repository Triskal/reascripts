-- Loops through stretch markers in selected media items and/or items in the same group. 
-- When more than one stretch markers are encountered at the same position, the later stretch 
-- marker is snapped to the next grid position. The process is repeated until no conflicts exist. 
-- This is my first Reaper script and I used ChatGPT to get me started.

-- Author: Simon J. Kok, simon.j.kok@gmail.com with help from ChatGPT
-- Version: 1.2

-- Changelog --
-- 1.0: initial release
-- 1.1: now calculates distance from project tempo and grid; also resolves all conflicts 
--      at once, no longer requiring running the sript multiple times
-- 1.2: now supports multiselect and resolves all items in a group when grouping is on

function GetGridSpaceInSeconds()
  local tempo = reaper.Master_GetTempo()
  local retval, gridDivision = reaper.GetSetProjectGrid(0, false)
  local space = (60 / tempo) *  (gridDivision * 4)
  return space
end

function ResolveDuplicateStretchMarkers(item)
  if not item then
    return
  end
  
  local take = reaper.GetActiveTake(item)
  
  if not take then
    return
  end
  
  -- Tolerance for comparing marker positions
  local tolerance = 0.0001
  local space = GetGridSpaceInSeconds()
  local duplicates = 0
  
  local marker_count = reaper.GetTakeNumStretchMarkers(take)
  if marker_count < 2 then
    reaper.ShowMessageBox("Not enough stretch markers", "Error", 0)
    return
  end
  
  for i = 0, marker_count - 2 do
    -- Get positions of current and next markers
    local _, pos_i, srcpos_i = reaper.GetTakeStretchMarker(take, i)
    local _, pos_next, _ = reaper.GetTakeStretchMarker(take, i + 1)
  
    -- Check if positions are effectively equal within the tolerance
    if math.abs(pos_i - pos_next) < tolerance then
      -- Snap the current marker to the next grid position
      reaper.SetTakeStretchMarker(take, i + 1, pos_next + space)
      duplicates = duplicates + 1
    end
  end
  if(duplicates > 0) then
    ResolveDuplicateStretchMarkers(item)
  end
end

function MatchGroup(itemA, itemB)
  if reaper.GetToggleCommandState(1156) == 0 or itemA == nil or itemB == nil then
    return false
  end
    
  groupA = reaper.GetMediaItemInfo_Value(itemA, "I_GROUPID")
  groupB = reaper.GetMediaItemInfo_Value(itemB, "I_GROUPID")
  
  if(groupA ~= groupB) then 
    return false
  end
  
  posA = reaper.GetMediaItemInfo_Value(itemA, "D_POSITION")
  posB = reaper.GetMediaItemInfo_Value(itemB, "D_POSITION")
  if posA == posB then
    return true
  end
  
  return false
end

local selectedItem = reaper.GetSelectedMediaItem(0, 0)
local itemList = {}

for i = 0, reaper.CountMediaItems(0) do
  local item = reaper.GetMediaItem(0, i)
  
  if item ~= nil then
    if reaper.IsMediaItemSelected(item) or MatchGroup(selectedItem, item) then
      table.insert(itemList, item)
    end
  end
end

reaper.Undo_BeginBlock()

for i = 1, #itemList do
  ResolveDuplicateStretchMarkers(itemList[i])
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Resolve duplicate stretch markers", -1)

