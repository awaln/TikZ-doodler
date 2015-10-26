// Generated by CoffeeScript 1.9.1

/**
 * Created by awaln on 4/15/15.
 */

(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  this.relate = function(drawing) {
    var i, j, k, l, len, len1, len2, loner, name, node, ref, ref1, ref2, relations, s, t;
    i = 0;
    while (i < drawing['loners'].length) {
      loner = drawing['loners'][i];
      relations = {
        start: [],
        end: []
      };
      ref = Object.keys(drawing['nodes']);
      for (j = 0, len = ref.length; j < len; j++) {
        name = ref[j];
        node = drawing.nodes[name];
        if (distance_formula(node.center_x, node.center_y, loner['start'][0], loner['start'][1]) < node.radius) {
          relations['start'].push(node.name);
        }
        if (distance_formula(node.center_x, node.center_y, loner['end'][0], loner['end'][1]) < node.radius) {
          relations['end'].push(node.name);
        }
      }
      if (relations['start'].length > 0 && relations['end'].length > 0) {
        drawing.loners.splice(i, 1);
        ref1 = relations.start;
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          s = ref1[k];
          if (!drawing.edges[s]) {
            drawing.edges[s] = [];
          }
          ref2 = relations.end;
          for (l = 0, len2 = ref2.length; l < len2; l++) {
            t = ref2[l];
            if (indexOf.call(drawing.edges[s], t) < 0) {
              drawing.edges[s].push(t);
              if (loner.type === "arrow") {
                drawing.arrows.push(s + " " + t);
              }
              drawing.edgelabels[s + " " + t] = "Edge " + Object.keys(drawing.edgelabels).length;
            }
          }
        }
      } else {
        i++;
      }
    }
    return drawing;
  };

  this.convert = function(compile_to, drawing) {
    var arrow_path, code, e, headers, i, j, k, l, len, len1, len2, len3, len4, len5, loner, m, n, name, node, o, ref, ref1, ref2, ref3, ref4, ref5, ref6, relations, s, t;
    if (convert_to === 'LaTeX') {
      headers = '\\usepackage{tikz}\n\\usetikzlibrary{arrows}';
      code = '\\begin{tikzpicture}[scale = 1]\n';
      arrow_path = "\\path[->]\n";
      i = 0;
      while (i < drawing['loners'].length) {
        loner = drawing['loners'][i];
        relations = {
          start: [],
          end: []
        };
        ref = Object.keys(drawing['nodes']);
        for (j = 0, len = ref.length; j < len; j++) {
          name = ref[j];
          node = drawing.nodes[name];
          if (node.type === 'circle' && distance_formula(node.center_x, node.center_y, loner['start'][0], loner['start'][1]) < node.radius) {
            relations['start'].push(node.name);
          }
          if (node.type === 'circle' && distance_formula(node.center_x, node.center_y, loner['end'][0], loner['end'][1]) < node.radius) {
            relations['end'].push(node.name);
          }
        }
        if (relations['start'].length > 0 && relations['end'].length > 0) {
          drawing.loners.splice(i, 1);
          ref1 = relations.start;
          for (k = 0, len1 = ref1.length; k < len1; k++) {
            s = ref1[k];
            if (!drawing.edges[s]) {
              drawing.edges[s] = [];
            }
            ref2 = relations.end;
            for (l = 0, len2 = ref2.length; l < len2; l++) {
              t = ref2[l];
              if (indexOf.call(drawing.edges[s], t) < 0) {
                drawing.edges[s].push(t);
                if (loner.type === "arrow") {
                  drawing.arrows.push(s + " " + t);
                }
                drawing.edgelabels[s + " " + t] = "Edge " + Object.keys(drawing.edgelabels).length;
              }
            }
          }
        } else {
          i++;
        }
      }
      ref3 = Object.keys(drawing.nodes);
      for (m = 0, len3 = ref3.length; m < len3; m++) {
        name = ref3[m];
        node = drawing.nodes[name];
        code += '\\node[style=circle,draw, minimum size = ' + node.radius + 'pt] (' + node.name + ') at (' + node.center_x + 'pt, -' + node.center_y + 'pt) {' + drawing.nodelabels[node.name] + '};\n';
      }
      code += "\\path\n";
      ref4 = Object.keys(drawing.edges);
      for (n = 0, len4 = ref4.length; n < len4; n++) {
        s = ref4[n];
        ref5 = drawing.edges[s];
        for (o = 0, len5 = ref5.length; o < len5; o++) {
          e = ref5[o];
          if (ref6 = s + " " + e, indexOf.call(drawing.arrows, ref6) >= 0) {
            arrow_path += '(' + s + ') edge node {' + drawing.edgelabels[s + " " + e] + '} (' + e + ')\n';
          } else {
            code += '(' + s + ') edge node {' + drawing.edgelabels[s + " " + e] + '} (' + e + ')\n';
          }
        }
      }
      code += ";";
      code += arrow_path + ";";
      document.getElementById('tex_includes').value = headers;
      code += '\\end{tikzpicture}\n';
      document.getElementById('tex_tex').value = code;
    }
  };

}).call(this);
