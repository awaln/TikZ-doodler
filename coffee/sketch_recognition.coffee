#drawing = {nodes:{},loners:[],edges:{},arrows:[],nodelabels:{},edgelabels:{}}
node_name_count = 0
loner_name_count = 0
PRETTY_DRAW_COLOR = 'black'
PRETTY_DRAW_SIZE = 2
COMPILE_TO = 'LaTeX'
CLOSED_THRESHOLD = .05
@pretty_draw = (ctx, canvas, drawing) ->
  ctx.clearRect 0, 0, canvas.width, canvas.height
  for start in Object.keys drawing.edges
    for end in drawing.edges[start]
      ctx.beginPath()
      ctx.moveTo drawing.nodes[start].center_x, drawing.nodes[start].center_y
      ctx.lineTo drawing.nodes[end].center_x, drawing.nodes[end].center_y
      ctx.stroke()
      ctx.closePath()
      # add arrowhead if it is an arrow
      if start + " " + end in drawing.arrows
        point1 = [drawing.nodes[start].center_x, drawing.nodes[start].center_y]
        # move back like 20%
        rise = drawing.nodes[end].center_y - drawing.nodes[start].center_y
        run = drawing.nodes[end].center_x - drawing.nodes[start].center_x
        midpoint = [point1[0] - run*.2, point1[1] - rise*.2]

  for node in Object.keys drawing.nodes
    if drawing.nodes[node].type.circle >= drawing.nodes[node].type.polygon
      ctx.beginPath()
      ctx.arc drawing.nodes[node].center_x, drawing.nodes[node].center_y, drawing.nodes[node].radius, 0, 2 * Math.PI
      ctx.fill()
      ctx.stroke()
      ctx.closePath()
    else
      ctx.beginPath()
      ctx.moveTo drawing.nodes[node].corners[0].x, drawing.nodes[node].corners[0].y
      for corner in drawing.nodes[node].corners
        ctx.lineTo corner.x, corner.y
      ctx.lineTo drawing.nodes[node].corners[0].x, drawing.nodes[node].corners[0].y
      ctx.closePath()
      ctx.fill()
      ctx.stroke()

  for loner in drawing.loners
    ctx.beginPath()
    ctx.moveTo loner.start[0], loner.start[1]
    ctx.lineTo loner.end[0], loner.end[1]
    ctx.strokeStyle = "red"
    ctx.stroke()
    ctx.strokeStyle = "black"
    ctx.closePath()

  return

@distance_formula = (x1, y1, x2, y2) -> Math.sqrt(Math.pow((x1 - x2),2) + Math.pow(y1 - y2,2))

@recognize = (current_stroke_x, current_stroke_y, current_times, ctx, canvas, drawing) ->
  # recognize complete stroke and say what you drew
  sketch_size = current_stroke_x.length
  closed = false
  corners = count_corners(current_stroke_x, current_stroke_y, current_times)
  console.log "Corners: " + corners
  # get how long the stroke is, for math later
  # I might not need this? Keeping it to be safe
  total_stroke_length = 0
  for i in [1...sketch_size]
    total_stroke_length += distance_formula(current_stroke_x[i], current_stroke_y[i], current_stroke_x[i-1], current_stroke_y[i-1])

  # Same as Paleo: "We begin by computing the distance between the endpoints and dividing it by the stroke length.
  # In order for a stroke to be closed this ratio must be less than some threshold.
  end_distance = distance_formula(current_stroke_x[0], current_stroke_y[0], current_stroke_x[current_stroke_x.length-1], current_stroke_y[current_stroke_y.length-1])
  closeness = end_distance/total_stroke_length
  if closeness < CLOSED_THRESHOLD
    closed = true

  # handle closed shapes
  if closed

    # Corners is doing well, but can't find circles.
    # If corners have really, really bad R values, it is more likely to be a circle
    corner_guess =
      "circle": 1*corners.length
    circle_sum = 0
    for i in [0...corners.length]
      circle_sum += corners[i].r
    corner_guess["circle"] = 1 - (circle_sum/corners.length)

    # CIRCLE CALCULATIONS
    average_x = current_stroke_x.reduce((total, num) ->
        total + num
      ) / sketch_size
    average_y = current_stroke_y.reduce((total, num) ->
       total + num
      ) / sketch_size
    # radius is average distance to center
    distance = 0
    i = 0
    while i < sketch_size
      distance += Math.sqrt((current_stroke_x[i] - average_x) ** 2 + (current_stroke_y[i] - average_y) ** 2)
      i++
    radius = distance / sketch_size

    # NOT A CIRCLE
    if corners.length > 2
      corner_guess["polygon"] = .8
    else
      corner_guess["polygon"] = 0
    console.log "Corner Guess: " + corner_guess
    drawing['nodes'][node_name_count] =
      name: node_name_count
      type: corner_guess
      center_x: Math.floor average_x
      center_y: Math.floor average_y
      radius: Math.floor radius
      corners: corners
    drawing.nodelabels[node_name_count] = "Node " + node_name_count
    node_name_count++

  # handle open shapes (lines)
  else
    # if we saw a corner, make it an arrow
    if corners
      drawing['loners'].push
        name: 'Loner ' + loner_name_count
        type: 'arrow'
        start: [current_stroke_x[0], current_stroke_y[0]]
        end: [current_stroke_x[sketch_size - 1], current_stroke_y[sketch_size - 1]]

    # assume straight lines otherwise for now
    # type, and two lists of nodes it connects
    drawing['loners'].push
      name: 'Loner ' + loner_name_count
      type: 'line'
      start: [current_stroke_x[0], current_stroke_y[0]]
      end: [current_stroke_x[sketch_size - 1], current_stroke_y[sketch_size - 1]]
    loner_name_count++

  snap_to drawing, 10
  # Removing TEX compiler for now because it is not as interesting.
  #convert COMPILE_TO, drawing
  # relate(drawing)
  # pretty_draw(ctx, canvas)
  return drawing


@snap_to = (drawing, grid) ->
  # snaps to specified grid (10 = round to nearest 10 pixels)
  # really only applies to nodes, don't really care about loners
  for name in Object.keys drawing.nodes
    node = drawing.nodes[name]
    if node.type == "circle"
      node.center_x = Math.round(node.center_x/grid) * grid
      node.center_y = Math.round(node.center_y/grid) * grid
      node.radius = Math.round(node.radius/grid) * grid

# TODO: Count corners currently is only accurate about whether it has corners or not.
count_corners = (list_x, list_y, times) ->
  # should return the number of "corners" it sees, as a list of locations and "confidences."
  # ex. a list of lists, inner list [x, y, time, confidence]
  # confidence is the
  WINDOW = 10
  ARCTAN_THRESHOLD = 1
  number_of_points = list_x.length
  corners = []
  console.log list_x, list_y, times
  # handles slopes and cum_arc_length
  slopes = [0]
  cum_arc_length = [0]
  total_stroke_length = 0
  speeds = [0]
  for i in [1...number_of_points-1]
    top = Math.min(i + WINDOW, number_of_points - 1)
    bottom = Math.max(0, i - WINDOW)
    slope = (list_y[top] - list_y[bottom])/(list_x[top] - list_y[bottom])
    radians = Math.atan(slope)
    slopes.push radians
    curr_distance = distance_formula(list_x[i-1], list_y[i-1], list_x[i], list_y[i])
    total_stroke_length += curr_distance
    cum_arc_length.push total_stroke_length
    speeds.push curr_distance/(times[i]-times[i-1])
  slopes[0] = slopes[1]
  speeds[0] = speeds[1]
  slopes[number_of_points - 1] = slopes[number_of_points - 2]
  speeds[number_of_points - 1] = speeds[number_of_points - 2]
  cum_arc_length.push (total_stroke_length + distance_formula(list_x[number_of_points-2], list_y[number_of_points-2], list_x[number_of_points-1], list_y[number_of_points-i]))

  # fix the cosine issue of jumps
  current_wrap = 0
  corrected_slopes = [slopes[0]]
  for j in [1...number_of_points]
    #if the previous raw value is near + pi/2 and the current value is near - pi/2, it needs to increase instead of wrap
    if slopes[j-1] > ARCTAN_THRESHOLD and slopes[j] < -ARCTAN_THRESHOLD
      current_wrap++
    #if the previous raw value is near - pi/2 and the current value is near + pi/2, it needs to decrease instead of wrap
    else if slopes[j-1] < -ARCTAN_THRESHOLD and slopes[j] > ARCTAN_THRESHOLD
      current_wrap--
    # multiply value by current_wrap*pi to increase or decrease instead of wrap
    corrected_slopes.push slopes[j] + current_wrap*Math.PI

  # get curvature, derivative of slopes/pixels
  curvatures = [0]
  for k in [1...number_of_points-1]
    top = Math.min(k + 1, number_of_points - 1)
    bottom = Math.max(0, k - 1)
    curvatures.push (corrected_slopes[top]- corrected_slopes[bottom])/(cum_arc_length[top] - cum_arc_length[bottom])
  curvatures[0] = curvatures[1]
  curvatures[number_of_points - 1] = curvatures[number_of_points - 2]
  #console.log curvatures

  # find local maxima of curvature, if above a threshold, consider it a corner
  last_found = 0
  STRAIGHTNESS = 1
  SEPARATION = .1*total_stroke_length
  CURVATURE_THRESHOLD = .06
  SPEED_THRESHOLD = .25*(total_stroke_length/(times[times.length-1]-times[0]))
  SPEED_THRESHOLD_2 = .8*(total_stroke_length/(times[times.length-1]-times[0]))
  # why did this start at Math.round(number_of_points/2)?
  for l in [1...number_of_points-1]
    lr = regression(list_x[last_found...l+1], list_y[last_found...l+1])
    if speeds[l-1] > speeds[l] and speeds[l+1] > speeds[l] and speeds[l] < SPEED_THRESHOLD and lr["r2"] < STRAIGHTNESS
      # only add the corner if it's far enough away, otherwise consider it the old corner and move on
      if distance_formula(list_x[last_found], list_y[last_found], list_x[l], list_y[l]) > SEPARATION
        corners.push({"x":list_x[l], "y":list_y[l], "t":times[l], "r":lr["r2"]})
      last_found = l
    #console.log curvatures[l-1], curvatures[l], curvatures[l+1]
    else if curvatures[l-1] < curvatures[l] and curvatures[l+1] < curvatures[l] and curvatures[l] > CURVATURE_THRESHOLD and speeds[l] < SPEED_THRESHOLD_2 and lr["r2"] < STRAIGHTNESS
      # only add the corner if it's far enough away, otherwise consider it the old corner and move on
      if distance_formula(list_x[last_found], list_y[last_found], list_x[l], list_y[l]) > SEPARATION
        corners.push({"x":list_x[l], "y":list_y[l], "t":times[l], "r":lr["r2"]})
      last_found = l
  return corners

regression = (x, y) ->
  # linear regression
  # The value r2 is a fraction between 0.0 and 1.0.
  # An r2 value of 0.0 means there is no linear relationship between X and Y
  # When r2 equals 1.0, all points lie exactly on a straight line with no scatter.
  lr = {}
  n = y.length
  sum_x = 0
  sum_y = 0
  sum_xy = 0
  sum_xx = 0
  sum_yy = 0

  for q in [1...y.length]
    sum_x += x[q]
    sum_y += y[q]
    sum_xy += (x[q]*y[q])
    sum_xx += (x[q]*x[q])
    sum_yy += (y[q]*y[q])

  lr["slope"] = (n * sum_xy - sum_x * sum_y) / (n*sum_xx - sum_x * sum_x)
  lr["intercept"] = (sum_y - lr.slope * sum_x)/n
  lr["r2"] = Math.pow((n*sum_xy - sum_x*sum_y)/Math.sqrt((n*sum_xx-sum_x*sum_x)*(n*sum_yy-sum_y*sum_y)),2)
  return lr

ask_paleo = (stroke_x, stroke_y, times) ->
  URL = "http://srl-mechanix.appspot.com/requests"
  ALLOWED_SHAPES = ["Line","Circle","Arrow"]
  template =
    "stroke":
      "points":
        []
    "style":
      "stroke":
        "red":128
        "green":0
        "blue":0
        "@type":"Color"
    "strokeWidth":3
    "@type":"Style"
    "@type":"Stroke"
    "options":ALLOWED_SHAPES
    "@type":"srl.distributed.messages.RecognizeStrokeRequest"

  # add points point-by-point
  # {"x":194,"y":54,"time":1445214087709,"@type":"Point"}
  for i in stroke_x.length
    stroke =
      "x": stroke_x[i]
      "y": stroke_y[i]
      "time": times[i]
      "@type": "Point"
    template["stroke"]["points"].push stroke

  # post it!
  response = null
  $.ajax
    type: 'POST'
    url: URL
    data: template
    async:false
    success: (data) ->
      response = data

  console.log response