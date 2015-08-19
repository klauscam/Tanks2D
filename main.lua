
local socket = require "socket"

-- the address and port of the server

local address, port = "localhost", 12555


--[[
  lines = {}
  for line in io.lines("server.ini") do 
    address = line
  end
--]]

--Android Version Only
local osString = love.system.getOS()
local touchx = 0
local touchy = 0
--

local myId = os.time()
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update
local absoluteupdaterate = 1
local fireRate = 0.3
local fireReload = 3
local lastDataFromServer = ""
local displayMessage=""
local fireTime = 0
local linearX = 0;
local linearY = 0;
local angularV = 0;
local angleS = 0;
local world = nil
local fixturesForDestruction = {}

function love.config(t)
  t.console = true
end

local touchIsPressed = false

function love.load()
  --love.window.setMode( 1000, 600, {} )
  if osString == "Android" then
    --love.window.setFullscreen(true)
  end
  love.physics.setMeter(10) --the height of a meter our worlds will be 64px
  world = love.physics.newWorld(0, 0, true) --create a world for the bodies to exist in with horizontal gravity of 0 and vertical gravity of 9.81
  world:setCallbacks(beginContact,nil,nil,nil)
  love.keyboard.setKeyRepeat( true)
  objects = {} -- table to hold all our physical objects
  objects.spaceship={}
  objects.spaceship.body = love.physics.newBody(world, 650/2, 650/2, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  objects.spaceship.body:setLinearDamping(2 )
  objects.spaceship.body:setAngularDamping(4 )
  objects.spaceship.body:setMass(1)
  objects.spaceship.shape = love.physics.newPolygonShape( 14, 0, -14,-10,-14,10) 
  objects.spaceship.fixture = love.physics.newFixture(objects.spaceship.body, objects.spaceship.shape, 1) -- Attach fixture to body and give it a density of 1.
  objects.spaceship.remainingBullets = 10
  objects.spaceship.life = 100
  objects.spaceship.score = 0

  objects.spaceship1={}
  objects.spaceship1.body = love.physics.newBody(world, 10, 10, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  objects.spaceship1.body:setLinearDamping(2 )
  objects.spaceship1.body:setAngularDamping(4)
  objects.spaceship1.body:setMass(1)
  objects.spaceship1.shape = love.physics.newPolygonShape( 14, 0, -14,-10,-14,10)  
  objects.spaceship1.fixture = love.physics.newFixture(objects.spaceship1.body, objects.spaceship1.shape, 1) -- Attach 
  objects.spaceship1.life = 100;
  objects.spaceship1.score = 0
  objects.bullets = {}

  objects.edges={}

  objects.edges[1] = {}
  objects.edges[1].body = love.physics.newBody(world, 0, 0, "static")
  objects.edges[1].body:setMass(0)
  objects.edges[1].shape = love.physics.newEdgeShape( 0, 0, 5, love.window.getHeight() )
  objects.edges[1].fixture = love.physics.newFixture(objects.edges[1].body, objects.edges[1].shape, 1) 

  objects.edges[2] = {}
  objects.edges[2].body = love.physics.newBody(world, love.window.getWidth()-5, 0, "static")
  objects.edges[2].body:setMass(0)
  objects.edges[2].shape = love.physics.newEdgeShape( 0, 0, 5, love.window.getHeight() )
  objects.edges[2].fixture = love.physics.newFixture(objects.edges[2].body, objects.edges[2].shape, 1) 

  objects.edges[3] = {}
  objects.edges[3].body = love.physics.newBody(world, 0, love.window.getHeight()-5, "static")
  objects.edges[3].body:setMass(0)
  objects.edges[3].shape = love.physics.newEdgeShape( 0, 0, love.window.getWidth(),5 )
  objects.edges[3].fixture = love.physics.newFixture(objects.edges[3].body, objects.edges[3].shape, 1) 

  objects.edges[4] = {}
  objects.edges[4].body = love.physics.newBody(world, 0, 0, "static")
  objects.edges[4].body:setMass(0)
  objects.edges[4].shape = love.physics.newEdgeShape( 0, 0, love.window.getWidth(),5 )
  objects.edges[4].fixture = love.physics.newFixture(objects.edges[4].body, objects.edges[4].shape, 1) 

  objects.buildings={}
  objects.buildings[1]={}
  objects.buildings[1].body = love.physics.newBody(world, 100, 75, "static") --place the body in the center of the world and make it dynamic, so it can move around
  objects.buildings[1].body:setMass(1)
  objects.buildings[1].shape = love.physics.newPolygonShape(0,0,200,0,200,100,50,100,50,200,0,200) 
  objects.buildings[1].fixture = love.physics.newFixture(objects.buildings[1].body, objects.buildings[1].shape, 1)

  objects.buildings[2]={}
  objects.buildings[2].body = love.physics.newBody(world, 75, 375, "static") --place the body in the center of the world and make it dynamic, so it can move around
  objects.buildings[2].body:setMass(1)
  objects.buildings[2].shape = love.physics.newPolygonShape(0,0,300,0,300,100,0,100) 
  objects.buildings[2].fixture = love.physics.newFixture(objects.buildings[2].body, objects.buildings[2].shape, 1)
  
    objects.buildings[3]={}
  objects.buildings[3].body = love.physics.newBody(world, 400, 130, "static") --place the body in the center of the world and make it dynamic, so it can move around
  objects.buildings[3].body:setMass(1)
  objects.buildings[3].shape = love.physics.newPolygonShape(0,0,0,150,150,150,150,0) 
  objects.buildings[3].fixture = love.physics.newFixture(objects.buildings[3].body, objects.buildings[3].shape, 1)
  
      objects.buildings[4]={}
  objects.buildings[4].body = love.physics.newBody(world, 600, 400, "static") --place the body in the center of the world and make it dynamic, so it can move around
  objects.buildings[4].body:setMass(1)
  objects.buildings[4].shape = love.physics.newPolygonShape(0,0,400,0,0,100) 
  objects.buildings[4].fixture = love.physics.newFixture(objects.buildings[4].body, objects.buildings[4].shape, 1)

  udp = socket.udp()
  udp:settimeout(0)
  udp:setpeername(address, port)
  udp:send(getCurrentShipStatus(objects.spaceship))
  time = 0
end



function love.update(dt)
  local forcex =0 
  local forcey = 0
  
  if (touchIsPressed) then
      forcex, forcey =  directionalForceTouch(touchx,touchy,1000)
    objects.spaceship.body:applyForce(forcex,forcey)
  end
  
  forcex=0
  forcey=0
  
  --local worldList = world:getBodyList()
  for i, bulletDestroy in ipairs(fixturesForDestruction) do
    --bulletDestroy:destroy()
    --if not(bulletDestroy.isDestroyed) then
      bulletDestroy:getBody():destroy()
    --end--bulletDestroy=nil
    table.remove(fixturesForDestruction,i)
    
  end
 -- for i, worldBody in ipairs(worldList) do
  --  if (worldBody:getFixtureList()) then
   --   table.remove(worldList,i)
   -- end
  --end
  
  if love.keyboard.isDown(" ") then
    if fireTime > fireRate then
      if (objects.spaceship.remainingBullets>0)then
        fireBullet(objects.spaceship)
        fireTime=0
        objects.spaceship.remainingBullets=objects.spaceship.remainingBullets-1
      elseif (objects.spaceship.remainingBullets<=0) then
        if fireTime > (fireRate+3) then
          objects.spaceship.remainingBullets=10
          fireBullet(objects.spaceship)
          displayMessage = ""
        else 
          displayMessage = "Reloading..."
        end
      end
    end
  end

  if love.keyboard.isDown("up") then
    forcex, forcey = directionalForce(objects.spaceship.body,1000)
    objects.spaceship.body:applyForce(forcex,forcey)
  end

  if love.keyboard.isDown("right") then
    objects.spaceship.body:applyAngularImpulse( 5 )
  elseif love.keyboard.isDown("left") then
    objects.spaceship.body:applyAngularImpulse( -5 )
  end

  fireTime = fireTime+dt



  if objects.spaceship.body:getAngle() <0 then
    objects.spaceship.body:setAngle(6.28318531+objects.spaceship.body:getAngle())
  elseif objects.spaceship.body:getAngle() >6.28318531 then
    objects.spaceship.body:setAngle(objects.spaceship.body:getAngle()-6.28318531)
  end



  time = time + dt
  if time > updaterate then
    if ((linearX > forcex+3)or(linearX < forcex-3) or (linearY > forcey+3)or(linearY < forcey-3) or (objects.spaceship.body:getAngularVelocity() > angularV+1) or (objects.spaceship.body:getAngularVelocity() < angularV-1) or (objects.spaceship.body:getAngle() > angleS+0.087266) or (objects.spaceship.body:getAngle() < angleS-0.087266))  then

      udp:send(getCurrentShipStatus(objects.spaceship))
      time=time-updaterate
      linearX = forcex
      linearY = forcey
      angularV = objects.spaceship.body:getAngularVelocity()
      angleS = objects.spaceship.body:getAngle()
    elseif (time > absoluteupdaterate) then
      udp:send(getCurrentShipStatus(objects.spaceship))
      time=time-absoluteupdaterate
    end

  end

  local lastData =""
  repeat
    data, msg = udp:receive()
    if data then
      if data ~= lastData then
        getDataFromServer(data)
        lastData=data
      end
    elseif msg ~= 'timeout' then
      --error("Network error: "..tostring(msg))
    end
  until not data




  world:update(dt)
end

id=0

function love.draw()
  love.graphics.scale(2,2)
  love.graphics.setColor(0, 255, 0) -- set the drawing color to green for the ground
  love.graphics.polygon("fill", objects.spaceship.body:getWorldPoints(objects.spaceship.shape:getPoints())) -- draw a "filled in" polygon using the ground's coordinates

  love.graphics.setColor(255, 0, 0) -- set the drawing color to green for the ground
  love.graphics.polygon("fill", objects.spaceship1.body:getWorldPoints(objects.spaceship1.shape:getPoints()))

  for i, bullet in ipairs(objects.bullets) do
    love.graphics.setColor(255, 255, 255) -- set the drawing color to green for the ground
    love.graphics.circle("fill", bullet.body:getX(), bullet.body:getY(), bullet.shape:getRadius())
     
  end

 for i, edge in ipairs(objects.edges) do
    love.graphics.setColor(255, 0, 0) -- set the drawing color to green for the ground
  love.graphics.rectangle("fill", edge.body:getWorldPoints(edge.shape:getPoints()))
  end

  local speedx, speedy = objects.spaceship.body:getLinearVelocity()
  love.graphics.print("You:"..objects.spaceship.score.." Opponent:"..objects.spaceship1.score..' '..displayMessage, 100,10)

  --buildings
  love.graphics.setColor(102, 51, 0) 
  love.graphics.polygon("fill", objects.buildings[1].body:getWorldPoints(objects.buildings[1].shape:getPoints()))
  love.graphics.polygon("fill", objects.buildings[2].body:getWorldPoints(objects.buildings[2].shape:getPoints()))
  love.graphics.polygon("fill", objects.buildings[3].body:getWorldPoints(objects.buildings[3].shape:getPoints()))
  love.graphics.polygon("fill", objects.buildings[4].body:getWorldPoints(objects.buildings[4].shape:getPoints()))
   
   love.graphics.setColor(255, 251, 250) 
   love.graphics.print( touchx..','..touchy, 10,100)
   love.graphics.circle("fill", touchx, touchy, 5)
end

--powerUp = false
--goingSide = "none"

--[[function love.keyreleased(key)
   if key == "up" then
     powerUp=false
   end
  if key == "left" then
     going="none"
     
   end
   
   if key == "right" then
     going="none"
     
   end
end


function love.keypressed(key)
   if key == "up" then
     powerUp=true
   end
   
   if key == "left" then
     going="left"
     
   end
   
   if key == "right" then
     going="right"
     
   end
   
   if (going=="right") then
     --IncAngle(objects.spaceship.body)
	 objects.spaceship.body:applyAngularImpulse( 500 )
   end
   
   
   if (going=="left") then
     --DecAngle(objects.spaceship.body)
     	 objects.spaceship.body:applyAngularImpulse( -500 )
   end
   
  if powerUp then
    local fx, fy = directionalForce(objects.spaceship.body)
    objects.spaceship.body:applyForce(fx,fy)
  end
end


function DecAngle(body)
  body:setAngle(math.rad(math.deg(body:getAngle())-5))
  local tmp = math.deg(body:getAngle())
  if tmp <= 0 then 
    body:setAngle(math.rad(math.abs(360-tmp)))
  end
end

function IncAngle(body)
  body:setAngle(math.rad(math.deg(body:getAngle())+5))
  local tmp = math.deg(body:getAngle())-360
  if tmp >=0 then 
    body:setAngle(math.rad(math.abs(tmp)))
  end
end
--]]


function fireBullet(spaceship)
  local body = spaceship.body
  local shape = spaceship.shape
  local bulletx,bullety = directionalForce(body,500)


  local pointx,pointy = body:getWorldPoints(shape:getPoints())
  pointx =pointx+ math.cos(body:getAngle())*10
 pointy = pointy+math.sin(body:getAngle())*10

  local bullet = { }
  bullet.body = love.physics.newBody(world, pointx, pointy, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  bullet.body:setMass(0.01)
  bullet.body:setBullet(true)
  bullet.shape = love.physics.newCircleShape(1) 
  bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape, 1) -- Attach fixture to body and give it a density of 1.

  --objects.bullets[#objects.bullets].body:applyForce(bulletx*5,bullety*5)
  bullet.body:setLinearVelocity(bulletx,bullety)
  table.insert(objects.bullets,bullet)
  udp:send('1,'..myId..','..bullet.body:getX()..','..bullet.body:getY()..','..bullet.body:getAngle()..','..bulletx..','..bullety..',0,0,0')
end

function addBulletFromServer(x,y,vx,vy)
  local bullet = { }
  bullet.body = love.physics.newBody(world, x, y, "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
  bullet.body:setMass(0.01)
  bullet.body:setBullet(true)
  bullet.shape = love.physics.newCircleShape(1) 
  bullet.fixture = love.physics.newFixture(bullet.body, bullet.shape, 1) -- Attach fixture to body and give it a density of 1.

  --objects.bullets[#objects.bullets].body:applyForce(bulletx*5,bullety*5)
  bullet.body:setLinearVelocity(vx,vy)
  table.insert(objects.bullets,bullet)
end

function directionalForce(body,force)
  local angle = body:getAngle()
  local totalforce = force
  local fx = 1
  local fy = 1

  -- if angle<0 then
  --   angle = 6.28318531+angle
  -- end
  --[[
  
  if angle == 0 then 
    fx = totalforce
    fy = 0
    return fx,fy

  elseif angle == 1.57079633 then --90
    fx = 0
    fy = totalforce
    return fx,fy
  elseif angle == 3.14159265 then --180
    fx = -totalforce
    fy = 0
    return fx,fy
  elseif angle == 4.71238898 then --270
    fx = 0
    fy = -totalforce
    return fx,fy
  end

  if angle >1.57079633 and angle<3.14159265 then 
    angle=angle-1.57079633
    fx=fx*-1 *(math.sin(angle)*totalforce)
    fy=fy*1*(math.cos(angle)*totalforce)



  elseif angle >3.14159265 and angle<4.71238898 then 
    angle=angle-1.57079633*2
    fy = fy*-1*(math.sin(angle)*totalforce)
	fx = fx*-1*(math.cos(angle)*totalforce)



  elseif angle >4.71238898 and angle<6.28318531 then 
    angle=angle-1.57079633*3
	fx=fx*1 *(math.sin(angle)*totalforce)
    fy=fy*-1*(math.cos(angle)*totalforce)
  
  
  else
   fy = fy*1*(math.sin(angle)*totalforce)
	fx = fx*1*(math.cos(angle)*totalforce)
  end
  

  --y = sin(rad) = opp/hyp
  --x = cos(rad) = adj/hyp
--]]
  fy = fy*(math.sin(angle)*totalforce)

  fx = fx*(math.cos(angle)*totalforce)

  return fx,fy
end

function getCurrentShipStatus(ship)
  local body = ship.body
  local fx, fy = body:getLinearVelocity()
  local av = body:getAngularVelocity()
  
  
  return '0,'..myId..','..body:getX()..','..body:getY()..','..body:getAngle()..','..fx..','..fy..','..av..','..ship.life..','..ship.score
end


function getDataFromServer(data)
  lastDataFromServer = data
  local objtype,id, x, y, angle,fx,fy,av,life,score = data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
  if tostring(id) ~= tostring(myId) then
    if (objtype=="0") then
      objects.spaceship1.body:setX(x)
      objects.spaceship1.body:setY(y)
      objects.spaceship1.body:setAngle(angle)
      objects.spaceship1.body:setLinearVelocity(fx,fy)
      objects.spaceship1.body:setAngularVelocity(av)
      objects.spaceship1.life = life
    elseif (objtype=="1") then
      addBulletFromServer(x,y,fx,fy)
	elseif (objtype=="2") then
		objects.spaceship1.score=1+objects.spaceship1.score
    end
  else 
    if (objtype=="0") and  tonumber(life)<=0 then

      udp:send('2,'..myId..',0,0,0,0,0,0,0,0')
    elseif (objtype == "2") then
      objects.spaceship.body:setX(x)
      objects.spaceship.body:setY(y)
      objects.spaceship.body:setAngle(angle)
      objects.spaceship.body:setLinearVelocity(fx,fy)
      objects.spaceship.body:setAngularVelocity(av)
      objects.spaceship.life = tonumber(life)
      objects.spaceship.score = tonumber(score)
    end
  end
end

function beginContact(a,b,coll)
  if (a:getShape():getRadius()==1) and (a:getShape():getType()=="circle") then
    for i, bullet in ipairs(objects.bullets) do
      if bullet.body:getX() == a:getBody():getX() and bullet.body:getY() == a:getBody():getY() then
        table.remove(objects.bullets,i)
        --print("hello")
        coll:setEnabled(false)
        table.insert(fixturesForDestruction,a)
        
      end
    end
    if (b:getBody():getX() == objects.spaceship.body:getX()) and (b:getBody():getY() == objects.spaceship.body:getY()) then
      objects.spaceship.life = objects.spaceship.life-25
      if (objects.spaceship.life == 0) then 
        displayMessage = displayMessage.."Game Over"
      end
    end
  elseif (b:getShape():getRadius()==1) and (b:getShape():getType()=="circle") then
     for i, bullet in ipairs(objects.bullets) do
      if bullet.body:getX() == b:getBody():getX() and bullet.body:getY() == b:getBody():getY() then
        table.remove(objects.bullets,i)
        coll:setEnabled(false)
        table.insert(fixturesForDestruction,b)
        --print("hello")
      end
    end
    
    if (a:getBody():getX() == objects.spaceship.body:getX()) and (a:getBody():getY() == objects.spaceship.body:getY()) then
      objects.spaceship.life = objects.spaceship.life-25
      if (objects.spaceship.life == 0) then 
        displayMessage = displayMessage.."Game Over"
      end
    end
  end
  
  
  
end



function love.touchpressed(id,x,y,pressure)
  local width,  height = love.window.getDesktopDimensions( 1 )
  local cx = x*(1000*(1+(1000/width)))
  local cy=y*(600*(1+(600/height)))
  
  touchx=cx
  touchy=cy
  


  forcex, forcey =  directionalForceTouch(touchx,touchy,1000)
    objects.spaceship.body:applyForce(forcex,forcey)
    touchIsPressed=true
end

function love.touchreleased(id,x,y,pressure)
  touchIsPressed=false
end

function directionalForceTouch(x,y,force)
  local angle = math.atan2(((y)-objects.spaceship.body:getY()), ((x)-objects.spaceship.body:getX()))
  local totalforce = force
  local fx = 1
  local fy = 1
  
  fy = fy*(math.sin(angle)*totalforce)

  fx = fx*(math.cos(angle)*totalforce)

  return fx,fy
end