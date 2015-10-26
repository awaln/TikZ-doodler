DRAW_COLOR = 'black'
DATE = new Date
strokes_x = []
strokes_y = []
times = []
current_stroke_x = []
current_stroke_y = []
current_times = []
canvas = undefined
ctx = undefined
flag = false
prevX = 0
currX = 0
prevY = 0
currY = 0
curr_start_time = 0
dot_flag = false
x = 'black'
y = 2
drawing = {nodes:{},loners:[],edges:{},arrows:[],nodelabels:{},edgelabels:{}}

@init = ->
  canvas = document.getElementById('can')
  ctx = canvas.getContext('2d')
  w = canvas.width
  h = canvas.height
  # mouse listeners
  canvas.addEventListener 'mousemove', ((e) ->
    findxy 'move', e
    return
  ), false
  canvas.addEventListener 'mousedown', ((e) ->
    findxy 'down', e
    return
  ), false
  canvas.addEventListener 'mouseup', ((e) ->
    findxy 'up', e
    return
  ), false
  canvas.addEventListener 'mouseout', ((e) ->
    findxy 'out', e
    return
  ), false
  # touch listeners
  canvas.addEventListener 'touchmove', ((e) ->
    findxy 'move', e.changedTouches[0]
    #e.preventDefault();
    return
  ), false
  canvas.addEventListener 'touchstart', ((e) ->
    findxy 'down', e.changedTouches[0]
    e.preventDefault()
    return
  ), false
  canvas.addEventListener 'touchend', ((e) ->
    findxy 'up', e.changedTouches[0]
    e.preventDefault()
    return
  ), false
  canvas.addEventListener 'touchleave', ((e) ->
    findxy 'out', e.changedTouches[0]
    e.preventDefault()
    return
  ), false
  canvas.addEventListener 'touchcancel', ((e) ->
    findxy 'out', e.changedTouches[0]
    e.preventDefault()
    return
  ), false
  return

draw = ->
  ctx.beginPath()
  ctx.moveTo prevX, prevY
  ctx.lineTo currX, currY
  ctx.strokeStyle = x
  ctx.lineWidth = y
  ctx.fillStyle = 'white'
  ctx.stroke()
  ctx.closePath()
  current_stroke_x.push currX
  current_stroke_y.push currY
  current_times.push (new Date().getTime()-curr_start_time)
  return

findxy = (res, e) ->
  if res == 'down'
    prevX = currX
    prevY = currY
    currX = e.clientX - canvas.offsetLeft
    currY = e.clientY - canvas.offsetTop
    curr_start_time = new Date().getTime();
    flag = true
    dot_flag = true
    if dot_flag
      ctx.beginPath()
      ctx.fillStyle = x
      ctx.fillRect currX, currY, 2, 2
      ctx.closePath()
      dot_flag = false
  if res == 'up' or res == 'out'
    flag = false
    if current_stroke_x.length > 0
      strokes_x.push current_stroke_x
      strokes_y.push current_stroke_y
      times.push current_times
      current_stroke_x = []
      current_stroke_y = []
      current_times = []
  if res == 'move'
    if flag
      prevX = currX
      prevY = currY
      currX = e.clientX - canvas.offsetLeft
      currY = e.clientY - canvas.offsetTop
      draw()
  return

@recognize_all = ->
  for i in [0...strokes_x.length]
    # recognize shapes
    drawing = recognize(strokes_x[i], strokes_y[i], times[i], ctx, canvas, drawing)
    #console.log strokes_x[i], strokes_y[i], times[i]
  drawing = relate(drawing)
  pretty_draw(ctx, canvas, drawing)
  ask_user()
  return

CONFIDENCE_THRESHOLD = .81
ask_user = ->
  for node in Object.keys drawing.nodes
    if drawing.nodes[node].type["circle"] < CONFIDENCE_THRESHOLD and drawing.nodes[node].type["polygon"] < CONFIDENCE_THRESHOLD
      console.log drawing.nodes[node]
      pretty_draw(ctx, canvas, drawing)
      # Draw an enormous red pointy bit.
      x_point = drawing.nodes[node].center_x
      y_point = drawing.nodes[node].center_y + drawing.nodes[node].radius
      ctx.beginPath()
      ctx.moveTo x_point, y_point
      ctx.lineTo x_point + 10, y_point + 50
      ctx.lineTo x_point - 10, y_point + 50
      ctx.lineTo x_point, y_point
      ctx.closePath()
      ctx.fillStyle = 'red'
      ctx.fill()
      ctx.fillStyle = 'white'
      ctx.stroke()
      if drawing.nodes[node].type["circle"] > drawing.nodes[node].type["polygon"]
        guess = "<p>I'm not sure what you've drawn here. My best guess is a circle. Is that right?</p>"
        answers = "<button onclick='answer(0)'>yes</button><button onclick='answer(1)'>no</button>"
      else
        guess = "<p>I'm not sure what you've drawn here. My best guess is a polygon. Is that right?</p>"
        answers = "<button onclick='answer(1)'>yes</button><button onclick='answer(0)'>no</button>"
      document.getElementById("askbox").innerHTML = guess + answers
      return
  document.getElementById("askbox").innerHTML = ""

DRAWABLE_SHAPES = ["circle", "polygon"]
@answer = (int) ->
  for node in Object.keys drawing.nodes
    console.log drawing.nodes[node]
    if drawing.nodes[node].type["circle"] < CONFIDENCE_THRESHOLD and drawing.nodes[node].type["polygon"] < CONFIDENCE_THRESHOLD
      drawing.nodes[node].type[DRAWABLE_SHAPES[int]] = 1
  pretty_draw(ctx, canvas, drawing)
  ask_user()