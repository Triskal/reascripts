-- Loops through stretch markers in selected media item. When it counters more than one stretch markers
-- at the same position, the latter stretch marker is snapped to the next grid position. This is my first
-- Reaper script and I used ChatGPT to get me started.

-- Author: Simon J. Kok, simon.j.kok@gmail.com with help from ChatGPT
-- Version: 1.0

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

-- Get the number of stretch markers
local marker_count = reaper.GetTakeNumStretchMarkers(take)
if marker_count < 2 then
  reaper.ShowMessageBox("Not enough stretch markers", "Error", 0)
  return
end

-- Tolerance for comparing marker positions
local tolerance = 0.0001

-- Begin an undo block
reaper.Undo_BeginBlock()

local _, pos_first, _ = reaper.GetTakeStretchMarker(take, 0)
local _, pos_second, _ = reaper.GetTakeStretchMarker(take, 1)
local space = pos_second - pos_first

-- Loop through stretch markers
for i = 0, marker_count - 2 do
  -- Get positions of current and next markers
  local _, pos_i, srcpos_i = reaper.GetTakeStretchMarker(take, i)
  local _, pos_next, _ = reaper.GetTakeStretchMarker(take, i + 1)

  -- Check if positions are effectively equal within the tolerance
  if math.abs(pos_i - pos_next) < tolerance then
    -- Snap the current marker to the next grid position
    reaper.SetTakeStretchMarker(take, i + 1, pos_next + space)
  end
end

-- End the undo block and update the item
reaper.UpdateItemInProject(item)
reaper.Undo_EndBlock("Resolve duplicate stretch markers", -1)

