-- This script converts all stretch markers to splits in a selected item. 
-- After that I recommend using SWS/AW fill gaps action. This should process nicely edited
-- program material (intended mainly for drums) with no transient smearing while being able
-- to utilize stretch markers in editing workflow.

-- Author: Simon J. Kok, simon.j.kok@gmail.com
-- Version: 1.0

function trimMediaItem(item, pos, pad)
  local delete_this = reaper.SplitMediaItem(item, pos - pad)
  
  if delete_this ~= nil then
    reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(delete_this), delete_this)
  end
  
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0)
end

function convertStretchMarkersToSplits(item, pad)
  local take = reaper.GetActiveTake(item)
  local num_markers = reaper.GetTakeNumStretchMarkers(take)
  
  offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS");
  
  for i = num_markers, 1, -1 do
    local idx, pos, srcpos = reaper.GetTakeStretchMarker(take, i + 1)
    
    reaper.SetTakeStretchMarker( take, idx, pos + pad, srcpos)
    right = reaper.SplitMediaItem(item, pos + offset)
    if right ~= nil then
      reaper.SetMediaItemInfo_Value(right, "D_FADEINLEN", 0)
      reaper.SetMediaItemInfo_Value(right, "D_FADEOUTLEN", 0)
      local rightpos = reaper.GetMediaItemInfo_Value(right, "D_POSITION")
      
      reaper.SetMediaItemInfo_Value(right, "D_POSITION", rightpos - pad)
      
      -- After splitting, remove all other stretch markers from the new take
      splittake = reaper.GetActiveTake(right);
      end_srcpos = 0
      end_pos = 0
      for j = reaper.GetTakeNumStretchMarkers(splittake), 0, -1 do
        local idx_j, pos_j, srcpos_j = reaper.GetTakeStretchMarker(splittake, j)
        if(idx_j ~= idx) then
          reaper.DeleteTakeStretchMarkers(splittake, idx_j)
        end
        if(idx_j == idx + 1) then
          end_srcpos = srcpos_j
          end_pos = pos_j
        end
      end
      
      trimMediaItem(right, end_srcpos, pad)
      reaper.DeleteTakeStretchMarkers(splittake, idx + 1)
    end
  end
  
  reaper.DeleteTakeStretchMarkers(take, 0)
  idx, pos, srcpos = reaper.GetTakeStretchMarker(take, 1)
  reaper.DeleteTakeStretchMarkers(take, 1, num_markers)
  trimMediaItem(item, srcpos, pad)
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

selectedItem = reaper.GetSelectedMediaItem(0, 0)
convertStretchMarkersToSplits(selectedItem, 0.03)

-- Following are attempts to process multiple selected items at once,
-- either by group or by selection. Neither work and I don't know why.
for i = 0, reaper.CountMediaItems(0) do
  local item = reaper.GetMediaItem(0, i)
  if item ~= nil then
    if(reaper.IsMediaItemSelected(item)) then
      --reaper.ShowConsoleMsg(i .. "\n")  
      --convertStretchMarkersToSplits(item, 0.03)
    end
    if matchGroup(selectedItem, item) then
      --reaper.ShowConsoleMsg(selectedItemGroup .. "\n")
      --convertStretchMarkersToSplits(item, 0.03)
    end
  end
end

reaper.Undo_EndBlock("Convert stretch markers to splits", -1);

