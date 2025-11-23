------- GLOBALS -------
-- The model name when it can't detect a model name from the handset
local modelName = "Unknown"
local lowVoltage = 6.6
local currentVoltage = 8.4
local highVoltage = 8.4
-- Timer tracking
local timerLeft = 0
local maxTimerValue = 0
-- Global for current RSSI
local rssi = 0
-- Define the screen size
local screen_width = 128
local screen_height = 64

local function convertVoltageToPercentage(voltage)
  local curVolPercent = math.ceil(((((highVoltage - voltage) / (highVoltage - lowVoltage)) - 1) * -1) * 100)
  if curVolPercent < 0 then
    curVolPercent = 0
  end
  if curVolPercent > 100 then
    curVolPercent = 100
  end
  return curVolPercent
end

--Tx battery
local function drawTransmitterVoltage(start_x,start_y,voltage)
  local batteryWidth = 17
  -- Battery outline
  lcd.drawRectangle(start_x, start_y, batteryWidth + 2, 6, SOLID)
  lcd.drawLine(start_x + batteryWidth + 2, start_y + 1, start_x + batteryWidth + 2, start_y + 4, SOLID, FORCE) -- Positive Nub
  -- Battery percentage (after battery)
  local curVolPercent = convertVoltageToPercentage(voltage)
    if curVolPercent < 20 then
      lcd.drawText(start_x + batteryWidth + 5, start_y, curVolPercent.."%", SMLSIZE + BLINK)
  else
    if curVolPercent == 100 then
      lcd.drawText(start_x + batteryWidth + 5, start_y, "99%", SMLSIZE)
    else
      lcd.drawText(start_x + batteryWidth + 5, start_y, curVolPercent.."%", SMLSIZE)
    end
  end
  -- Filled in battery
  local pixels = math.ceil((curVolPercent / 100) * batteryWidth)
  if pixels == 1 then
    lcd.drawLine(start_x + pixels, start_y + 1, start_x + pixels, start_y + 4, SOLID, FORCE)
  end
  if pixels > 1 then
    lcd.drawRectangle(start_x + 1, start_y + 1, pixels, 4)
  end
  if pixels > 2 then
    lcd.drawRectangle(start_x + 2, start_y + 2, pixels - 1, 2)
    lcd.drawLine(start_x + pixels, start_y + 2, start_x + pixels, start_y + 3, SOLID, FORCE)
  end
end

--Clock, top right
local function drawTime()
  local datenow = getDateTime()
  local min = datenow.min .. ""
    if datenow.min < 10 then
      min = "0" .. min
    end
  local hour = datenow.hour .. ""
    if datenow.hour < 10 then
      hour = "0" .. hour
    end
    if math.ceil(math.fmod(getTime() / 100, 2)) == 1 then
      hour = hour .. ":"
    end
  lcd.drawText(107,0,hour, SMLSIZE)
  lcd.drawText(119,0,min, SMLSIZE)
end

--Rx battery guage
local function drawVoltageImage(start_x, start_y)
  local batteryWidth = 12
  --Draw battery outline
  lcd.drawLine(start_x + 2, start_y + 1, start_x + batteryWidth - 2, start_y + 1, SOLID, 0)
  lcd.drawLine(start_x, start_y + 2, start_x + batteryWidth - 1, start_y + 2, SOLID, 0)
  lcd.drawLine(start_x, start_y + 2, start_x, start_y + 50, SOLID, 0)
  lcd.drawLine(start_x, start_y + 50, start_x + batteryWidth - 1, start_y + 50, SOLID, 0)
  lcd.drawLine(start_x + batteryWidth, start_y + 3, start_x + batteryWidth, start_y + 49, SOLID, 0)
  --Top one eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 8, start_x + batteryWidth - 1, start_y + 8, SOLID, 0)
  --Top quarter line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 2), start_y + 14, start_x + batteryWidth - 1, start_y + 14, SOLID, 0)
  --Third eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 20, start_x + batteryWidth - 1, start_y + 20, SOLID, 0)
  --Middle line
  lcd.drawLine(start_x + 1, start_y + 26, start_x + batteryWidth - 1, start_y + 26, SOLID, 0)
  --Five eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 32, start_x + batteryWidth - 1, start_y + 32, SOLID, 0)
  --Bottom quarter line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 2), start_y + 38, start_x + batteryWidth - 1, start_y + 38, SOLID, 0)
  --Seven eighth line
  lcd.drawLine(start_x + batteryWidth - math.ceil(batteryWidth / 4), start_y + 44, start_x + batteryWidth - 1, start_y + 44, SOLID, 0)
  -- Voltage top
  --lcd.drawText(start_x + batteryWidth + 4, start_y + 0, "4.20v", SMLSIZE)
  -- Voltage middle
  --lcd.drawText(start_x + batteryWidth + 4, start_y + 24, "3.80v", SMLSIZE)
  -- Voltage bottom
  --lcd.drawText(start_x + batteryWidth + 4, start_y + 47, "3.40v", SMLSIZE)

  --Draw how full battery is
  local totalvoltage = getValue('RxBt')
  local voltage = totalvoltage/4 -- Divide by cell count
  voltageLow = 3.4
  voltageHigh = 4.2
  voltageIncrement = ((voltageHigh - voltageLow) / 47)
  local offset = 0  -- Start from the bottom up
  while offset < 47 do
    if ((offset * voltageIncrement) + voltageLow) < tonumber(voltage) then
      lcd.drawLine( start_x + 1, start_y + 49 - offset, start_x + batteryWidth - 1, start_y + 49 - offset, SOLID, 0)
    end
    offset = offset + 1
  end
end

local function drawtables()
--Left, top and bottom
lcd.drawFilledRectangle(23, 10, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(23, 23, 30, 13, GREY_DEFAULT)
lcd.drawFilledRectangle(23, 36, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(23, 49, 30, 13, GREY_DEFAULT)
lcd.drawText (27,13, "CELL", INVERS,SMLSIZE)
lcd.drawText (29,39, "THR", INVERS)
--Middle, top and bottom
lcd.drawFilledRectangle(56, 10, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(56, 23, 30, 13, GREY_DEFAULT)
lcd.drawFilledRectangle(56, 36, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(56, 49, 30, 13, GREY_DEFAULT)
lcd.drawText (62,13, "ESC", INVERS)
lcd.drawText (62,39, "BRK", INVERS)
--Right, top and bottom
lcd.drawFilledRectangle(89, 10, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(89, 23, 30, 13, GREY_DEFAULT)
lcd.drawFilledRectangle(89, 36, 30, 13, GREY_DEFAULT)
lcd.drawRectangle(89, 49, 30, 13, GREY_DEFAULT)
lcd.drawText (93,13, "TIME", INVERS)
lcd.drawText (95,39, "STR", INVERS)
end

--Cell voltage
local function celldraw()
  local totalvoltage = getValue('RxBt')
  local voltage = (totalvoltage / 4)*100
  lcd.drawNumber (27, 26, voltage, PREC2)
  lcd.drawText (44, 26, "v", 0)
end

--Throttle rate
local function thrValue()
local thrdr = getValue("gvar1")
if thrdr == 100 then
lcd.drawText (30,52, thrdr)
end
if thrdr < 100 then
lcd.drawText (33,52, thrdr)
end
end

--Disable throttle
local function esc()
local brkpos = getLogicalSwitchValue (0)
if brkpos == true then
lcd.drawText (62,26, "Dis")
end
if brkpos == false then
lcd.drawText (62,26, "ACT")
end
end

--Brake rate
local function brkValue()
local brkdr = getValue("gvar2")
if brkdr == 100 then
lcd.drawText (63,52, brkdr)
end
if brkdr < 100 then
lcd.drawText (66,52, brkdr)
end
end

--Race timer
local function TheFinalCountDown()
  local compTime = getValue ("timer1")
  lcd.drawTimer (93, 26, compTime)
end

--Steering rate
local function strValue()
local strdr = getValue("gvar3")
if strdr == 100 then
lcd.drawText (96,52, strdr)
end
if strdr < 100 then
lcd.drawText (99,52, strdr)
end
end

local function gatherInput(event)
  rssi = getRSSI()
  timerLeft = getValue ('timer1')
    if timerLeft > maxTimerValue then
    maxTimerValue = timerLeft
  end
  currentVoltage = getValue('tx-voltage')
end

local function run(event)

  lcd.clear()
  gatherInput(event)
  lcd.drawLine(0, 7, 128, 7, SOLID, FORCE)
  lcd.drawText( 64 - math.ceil((#modelName * 5) / 2),0, modelName, SMLSIZE)
  drawTransmitterVoltage(0,0, currentVoltage)
  drawTime()
  drawVoltageImage(3, 10)
  drawtables()
  celldraw()
  thrValue()
  esc()
  brkValue()
  TheFinalCountDown()
  strValue()
end

local function init_func()
  local modeldata = model.getInfo()
  if modeldata then
    modelName = modeldata['name']
  end
end

return { run=run, init=init_func  }
