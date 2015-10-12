drawing = {nodes:{},loners:[],edges:{},arrows:[],nodelabels:{},edgelabels:{}}
node_name_count = 0
loner_name_count = 0
PRETTY_DRAW_COLOR = 'black'
PRETTY_DRAW_SIZE = 2
COMPILE_TO = 'LaTeX'
CLOSED_THRESHOLD = .05
pretty_draw = (ctx, canvas) ->
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
    ctx.beginPath()
    ctx.arc drawing.nodes[node].center_x, drawing.nodes[node].center_y, drawing.nodes[node].radius, 0, 2 * Math.PI
    ctx.fill()
    ctx.stroke()
    ctx.closePath()

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

@recognize = (current_stroke_x, current_stroke_y, ctx, canvas) ->
  # recognize complete stroke and say what you drew
  sketch_size = current_stroke_x.length
  closed = false
  corners = count_corners(current_stroke_x, current_stroke_y)
  console.log corners
  # get how long the stroke is, for math later
  # I might not need this? Keeping it to be safe
  total_stroke_length = 0
  for i in [1...sketch_size]
    total_stroke_length += distance_formula(current_stroke_x[i], current_stroke_y[i], current_stroke_x[i-1], current_stroke_y[i-1])

  # see if it's an open or closed shape
  # call it a closed shape if there is an intersection between [something in 1st quarter] and [something in 4nd quarter]
  for first in [0...Math.floor(sketch_size/4)]
    for last in [Math.floor(sketch_size*3/4)...sketch_size]
      # an intersection is points with euclidean distance within CLOSED_THRESHOLD of the stroke length of each other
      if distance_formula(current_stroke_x[first], current_stroke_y[first], current_stroke_x[last], current_stroke_y[last]) < CLOSED_THRESHOLD * total_stroke_length
        closed = true

  # handle closed shapes
  if closed
    # assume circle center at mean of X and Y
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
    drawing['nodes'][node_name_count] =
      name: node_name_count
      type: 'circle'
      center_x: Math.floor average_x
      center_y: Math.floor average_y
      radius: Math.floor radius
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
  compile COMPILE_TO, drawing
  pretty_draw(ctx, canvas)


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
count_corners = (list_x, list_y) ->
  # should return the number of "corners" it sees
  WINDOW = 10
  ARCTAN_THRESHOLD = 1
  CURVATURE_THRESHOLD = .05
  number_of_points = list_x.length
  corners = 0

  # handles slopes and cum_arc_length
  slopes = [0]
  cum_arc_length = [0]
  total_stroke_length = 0
  for i in [1...number_of_points-1]
    top = Math.min(i + WINDOW, number_of_points - 1)
    bottom = Math.max(0, i - WINDOW)
    slope = (list_y[top] - list_y[bottom])/(list_x[top] - list_y[bottom])
    radians = Math.atan(slope)
    slopes.push radians

    total_stroke_length += distance_formula(list_x[i-1], list_y[i-1], list_x[i], list_y[i])
    cum_arc_length.push total_stroke_length
  slopes[0] = slopes[1]
  slopes[number_of_points - 1] = slopes[number_of_points - 2]
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
  for l in [Math.round(number_of_points/2)...number_of_points-1]
    #console.log curvatures[l-1], curvatures[l], curvatures[l+1]
    if curvatures[l-1] < curvatures[l] and curvatures[l+1] < curvatures[l] and curvatures[l] > CURVATURE_THRESHOLD
      corners++

  return corners

# ---
# generated by js2coffee 2.0.3