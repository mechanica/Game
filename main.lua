----------------------------------------------------------------
-- Copyright (c) 2010-2011 Zipline Games, Inc. 
-- All Rights Reserved. 
-- http://getmoai.com
----------------------------------------------------------------

local inspect = require("inspect")

local sprites = {
  male = {
    src = "male.png",
    width = 55,
    height = 32,
    origin = {
      x = 39,
      y = 16
    },
    speed = 150,
    getRect = function (self)
      return self.origin.x, self.origin.y - self.height, self.origin.x - self.width, self.origin.y
    end
  },
  target = {
    src = "target.png",
    width = 32,
    height = 32,
    origin = {
      x = 16,
      y = 16
    },
    getRect = function (self)
      return self.origin.x, self.origin.y - self.height, self.origin.x - self.width, self.origin.y
    end
  }
}

local Object = {}

function Object:new ( sprite )
  o = {}
  
  for k, v in pairs( sprite ) do o[k] = v end
  
  o.gfxQuad = MOAIGfxQuad2D.new ()
  o.gfxQuad:setTexture ( sprite.src )
  o.gfxQuad:setRect ( sprite:getRect() )

  o.prop = MOAIProp2D.new ()
  o.prop:setDeck ( o.gfxQuad )
  
  o.transformation = {}
  o.waypoints = {}

  function o:addToLayer ( layer )
    layer:insertProp ( self.prop )
  end
  
  function o:addWaypoint ( target )
    local waypoint = Object:new ( sprites.target )
    waypoint.prop:setLoc ( target.prop:getLoc() )
    table.insert ( self.waypoints, waypoint )
  end
  
  function o:clearWaypoints ()
    o.waypoints = {}
  end
  
  function o:go ()    
    self.thread = MOAICoroutine.new ()
    
    self.thread:run(function ()
      while ( #self.waypoints ~= 0 ) do
        local target = table.remove(self.waypoints, 1)
        
        local cx, cy = self.prop:getLoc ()
        local tx, ty = target.prop:getLoc ()
    
        -- rotation --
    
        local rot = math.deg( math.atan2( ty - cy, tx - cx ) )
        local cr = self.prop:getRot()
    
        if (rot - cr) < -180 then
          rot = rot + 360
        end
    
        if (rot - cr) > 180 then
          rot = rot - 360
        end
    
        -- move --
    
        local dx, dy = tx - cx, ty - cy

        local distance = math.sqrt( dx*dx + dy*dy )
          
        local moveTime = distance / self.speed
    
        -- trigger --
    
        if ( self.transformation.rot ) then self.transformation.rot:stop() end
        if ( self.transformation.move ) then self.transformation.move:stop() end

        if math.abs ( rot - cr ) < 90 then
          self.prop:setRot( rot )
        else
          self.transformation.rot = self.prop:seekRot( rot, .5, MOAIEaseType.LINEAR )
      
          -- local ease = MOAIEaseDriver.new ()
          -- 
          -- ease:reserveLinks ( 1 )
          -- ease:setLink ( 1, self.prop, MOAIProp2D.ATTR_Z_ROT, rot - cr )
          -- ease:setSpan ( .5 )
          -- ease:start ()
          -- 
          -- self.transformation.rot = ease
      
          MOAICoroutine.blockOnAction ( self.transformation.rot )
        end
        self.transformation.move = self.prop:moveLoc( dx, dy, moveTime, MOAIEaseType.LINEAR )
        MOAICoroutine.blockOnAction ( self.transformation.move )
      end
    end)
  end
  
  return o
end

MOAISim.openWindow ( "test", 640, 480 )

viewport = MOAIViewport.new ()
viewport:setSize ( 640, 480 )
viewport:setScale ( 640, 480 )

local layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )

local male = Object:new ( sprites.male )
male:addToLayer ( layer )

local target = Object:new ( sprites.target )
target:addToLayer ( layer )

function pointerCallback ( x, y )
  target.prop:setLoc(layer:wndToWorld ( x, y ))
end

function leftClickCallback ( down )
  if not down then
    male:clearWaypoints ()
    male:addWaypoint ( target )
    male:go ()
  end
end

function rightClickCallback ( down )
  if not down then
    male:addWaypoint ( target )
    if not ( male.thread and male.thread:isActive () ) then male:go () end
  end
end

MOAIInputMgr.device.pointer:setCallback ( pointerCallback )
MOAIInputMgr.device.mouseLeft:setCallback ( leftClickCallback )
MOAIInputMgr.device.mouseRight:setCallback ( rightClickCallback )