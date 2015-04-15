/**
 * Created by awaln on 4/15/15.
 */
// converts drawing from an object with items to TikZ latex.

function compile(convert_to, drawing){
    // if LaTeX, make it
    if (convert_to == "LaTeX") {
        var headers = "\\usepackage{tikz}\n";
        var code = "\\begin{tikzpicture}\n";
        var node_counter = 0;

        for (i = 0; i < drawing.length; i++) {
            if (drawing[i].type == "circle") {
                code += "\\node[style=circle,draw, minimum size = " + drawing[i].radius + "pt] () at (" + drawing[i].center_x + "pt, -" + drawing[i].center_y + "pt) {};\n";
            }
        }

        // add necessary headers
        document.getElementById("tex_includes").value = headers;
        // add code
        code += "\\end{tikzpicture}\n";
        document.getElementById("tex_tex").value = code;
    }
}