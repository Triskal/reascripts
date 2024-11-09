-- This script converts all stretch markers to splits in a selected item. 
-- After that I recommend using SWS/AW fill gaps action. This should produce nicely edited
-- program material (intended mainly for drums) with no transient smearing while being able
-- to utilize stretch markers in editing workflow.

-- Author: Simon J. Kok, simon.j.kok@gmail.com
-- Version: 2.0

-- Changelog --
-- 1.0: initial release
-- 2.0: largely rewritten, now supports multiselection

function trimMediaItem(item, pos, pad)
  local delete_this = reaper.SplitMediaItem(item, pos - pad)
  
  if delete_this ~= nil then
    reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(delete_this), delete_this)
  end
  
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0)
end

function convertStretchMarkersToSplits(item, pad)
  items = {}
  itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  take = reaper.GetActiveTake(item)
  markerCount = reaper.GetTakeNumStretchMarkers(take)
  for i = markerCount, 1, -1 do
    id, pos, srcpos = reaper.GetTakeStretchMarker(take, i)
    right = reaper.SplitMediaItem(item, itemPos + pos - pad)
    
    if(right ~= nil) then
      splitTake = reaper.GetActiveTake(right)
      reaper.SetMediaItemInfo_Value(right, "D_SNAPOFFSET", pad)
      if(i < markerCount) then
        id_n, pos_n, srcpos_n = reaper.GetTakeStretchMarker(splitTake, i + 1)
        trimLen = srcpos_n - srcpos
        reaper.SetMediaItemLength(right, trimLen, false)
        
        -- Delete all markers except at index 1
        reaper.DeleteTakeStretchMarkers(splitTake, i + 1, markerCount)
        reaper.DeleteTakeStretchMarkers(splitTake, 1, i - 1)
        reaper.DeleteTakeStretchMarkers(splitTake, 0)
        
        table.insert(items, 1, right)
      end
    end
  end
  
  reaper.DeleteTakeStretchMarkers(take, 1, markerCount)
  table.insert(items, 1, item)
  
  -- Trim overlaps and remove fades
  for i = 1, #items do
    if i < #items then
      itemPos = reaper.GetMediaItemInfo_Value(items[i], "D_POSITION")
      itemLen = reaper.GetMediaItemInfo_Value(items[i], "D_LENGTH")
      rightPos = reaper.GetMediaItemInfo_Value(items[i + 1], "D_POSITION")
      
      if(itemPos + itemLen > rightPos) then
        overlap = itemPos + itemLen - rightPos
        newLen = itemLen - overlap
        reaper.SetMediaItemLength(items[i], newLen, true)
      end
    end
    
    reaper.SetMediaItemInfo_Value(items[i], "D_FADEINLEN", 0)
    reaper.SetMediaItemInfo_Value(items[i], "D_FADEOUTLEN", 0)
  end
end

function matchGroup(itemA, itemB)
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

reaper.ClearConsole();
reaper.Undo_BeginBlock();

-- In order to process multiple items at once, they must first
-- be collected into an array, because the item index list gets
-- regenerated every time an item is added
local itemList = {}

for i = 0, reaper.CountMediaItems(0) do
  local item = reaper.GetMediaItem(0, i)
  
  if item ~= nil then
    if reaper.IsMediaItemSelected(item) then
      table.insert(itemList, item)
    end
    --if matchGroup(selectedItem, item) then
      --reaper.ShowConsoleMsg(selectedItemGroup .. "\n")
      --convertStretchMarkersToSplits(item, 0.03)
    --end
  end
end

for i = 1, #itemList do
  convertStretchMarkersToSplits(itemList[i], 0.03)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Convert stretch markers to splits", -1);

