-- Loops through stretch markers in selected media item. When it counters more than one stretch markers
-- at the same position, the latter stretch marker is snapped to the next grid position. This is my first
-- Reaper script and I used ChatGPT to get me started.

-- Author: Simon J. Kok, simon.j.kok@gmail.com with help from ChatGPT
-- Version: 1.1

-- Function to calculate grid space in seconds
function GetGridSpaceInSeconds()
  -- Get the current project tempo (in BPM)
  local tempo = reaper.Master_GetTempo()

    -- Get the grid division (in beats)
  local retval, gridDivision = reaper.GetSetProjectGrid(0, false)

  -- Calculate the grid space in seconds
  local gridSpaceInSeconds = (60 / tempo) *  (gridDivision * 4)
  return gridSpaceInSeconds
end

function ResolveDuplicateStretchMarkers(take)
  -- Tolerance for comparing marker positions
  local tolerance = 0.0001
  local space = GetGridSpaceInSeconds()
  local duplicates = 0
  -- Get the number of stretch markers
  local marker_count = reaper.GetTakeNumStretchMarkers(take)
  if marker_count < 2 then
    reaper.ShowMessageBox("Not enough stretch markers", "Error", 0)
    return
  end
  
  -- Loop through stretch markers
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
    ResolveDuplicateStretchMarkers(take)
  end
end

-- Ensure an item is selected
local item = reaper.GetSelectedMediaItem(0, 0)
if not item then
  reaper.ShowMessageBox("No item selected", "Error", 0)
  return
end

-- Get the active take of the selected media item
local take = reaper.GetActiveTake(item)
if not take then
  reaper.ShowMessageBox("No active take found", "Error", 0)
  return
end

-- Begin an undo block
reaper.Undo_BeginBlock()

ResolveDuplicateStretchMarkers(take)

-- End the undo block and update the item
reaper.UpdateItemInProject(item)
reaper.Undo_EndBlock("Resolve duplicate stretch markers", -1)

