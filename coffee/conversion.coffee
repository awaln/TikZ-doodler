###*
# Created by awaln on 4/15/15.
###

# converts drawing from an object with items to TikZ latex.

@relate = (drawing) ->
  # look at the loners first, relate to nodes if possible
  #console.log JSON.stringify(drawing['loners']), drawing['loners'].length
  i = 0
  while i < drawing['loners'].length
    loner = drawing['loners'][i]
    relations = {start:[], end:[]}
    #console.log loner, i, drawing['loners'][i]
    for name in Object.keys(drawing['nodes'])
      node = drawing.nodes[name]
      # check for start node overlap
      if distance_formula(node.center_x, node.center_y, loner['start'][0], loner['start'][1]) < node.radius
        relations['start'].push(node.name)
      if distance_formula(node.center_x, node.center_y, loner['end'][0], loner['end'][1]) < node.radius
        relations['end'].push(node.name)
    if relations['start'].length > 0 and relations['end'].length > 0
      drawing.loners.splice(i, 1)
      for s in relations.start
        if not drawing.edges[s]
          drawing.edges[s] = []
        for t in relations.end
          if t not in drawing.edges[s]
            drawing.edges[s].push t
            if loner.type == "arrow"
              drawing.arrows.push (s + " " + t)
            drawing.edgelabels[s + " " + t] = "Edge " + Object.keys(drawing.edgelabels).length
    else
      i++

  # TODO: Study relations and decide on a template to use

  return drawing

@convert = (compile_to, drawing) ->
  # if LaTeX, make it
  if convert_to == 'LaTeX'
    headers = '\\usepackage{tikz}\n\\usetikzlibrary{arrows}'
    code = '\\begin{tikzpicture}[scale = 1]\n'
    arrow_path = "\\path[->]\n"

    # look at the loners first, relate to nodes if possible
    # console.log JSON.stringify(drawing['loners']), drawing['loners'].length
    i = 0
    while i < drawing['loners'].length
      loner = drawing['loners'][i]
      relations = {start:[], end:[]}
      # console.log loner, i, drawing['loners'][i]
      for name in Object.keys(drawing['nodes'])
        node = drawing.nodes[name]
        # check for start node overlap
        if node.type == 'circle' and distance_formula(node.center_x, node.center_y, loner['start'][0], loner['start'][1]) < node.radius
          relations['start'].push(node.name)
        if node.type == 'circle' and distance_formula(node.center_x, node.center_y, loner['end'][0], loner['end'][1]) < node.radius
          relations['end'].push(node.name)
      if relations['start'].length > 0 and relations['end'].length > 0
        drawing.loners.splice(i, 1)
        for s in relations.start
          if not drawing.edges[s]
            drawing.edges[s] = []
          for t in relations.end
            if t not in drawing.edges[s]
              drawing.edges[s].push t
              if loner.type == "arrow"
                drawing.arrows.push (s + " " + t)
              drawing.edgelabels[s + " " + t] = "Edge " + Object.keys(drawing.edgelabels).length
      else
        i++

    # TODO: Study relations and decide on a template to use

    # place nodes
    for name in Object.keys(drawing.nodes)
      node = drawing.nodes[name]
      code += '\\node[style=circle,draw, minimum size = ' + node.radius + 'pt] (' + node.name + ') at (' + node.center_x + 'pt, -' + node.center_y + 'pt) {' + drawing.nodelabels[node.name] + '};\n'

    # place edges
    code += "\\path\n"
    for s in Object.keys drawing.edges
      for e in drawing.edges[s]
        if (s + " " + e) in drawing.arrows
          arrow_path += '(' + s + ') edge node {'+ drawing.edgelabels[s + " " + e] + '} (' + e + ')\n'
        else
          code += '(' + s + ') edge node {'+ drawing.edgelabels[s + " " + e] + '} (' + e + ')\n'
    code += ";"

    code += arrow_path + ";"

    # add necessary headers
    document.getElementById('tex_includes').value = headers
    # add code
    code += '\\end{tikzpicture}\n'
    document.getElementById('tex_tex').value = code
  return