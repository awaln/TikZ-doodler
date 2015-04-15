var sketch_size = 0;
var drawing = [];
var PRETTY_DRAW_COLOR = "black";
var PRETTY_DRAW_SIZE = 2;

setInterval(function(){
    // recognize complete stroke and say what you drew
    if (current_stroke_x.length > 0 && current_stroke_x.length == sketch_size) {
        // draw circles
        // assume circle center at mean of X and Y
        var average_x = current_stroke_x.reduce(function(total, num){ return total + num })/current_stroke_x.length;
        var average_y = current_stroke_y.reduce(function(total, num){ return total + num })/current_stroke_y.length;
        document.getElementById("tex").value += ("(" + average_x.toString() + ", " + average_y.toString() + ")");
        // radius is average distance to center
        var distance = 0;
        for (i = 0; i < current_stroke_x.length; i++) {
            distance += Math.sqrt(Math.pow(current_stroke_x[i] - average_x, 2) + Math.pow(current_stroke_y[i] - average_y, 2));
        }
        var radius = distance/current_stroke_x.length;
        drawing.push({type:"circle", center_x:average_x, center_y:average_y, radius:radius});

        current_stroke_x = [];
        current_stroke_y = [];

        pretty_draw();
    }
    else {
        sketch_size = current_stroke_x.length;
    }
}, 500);

function pretty_draw(){
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (i = 0; i < drawing.length; i++) {
        if (drawing[i].type == "circle") {
            ctx.beginPath();
            ctx.arc(drawing[i].center_x, drawing[i].center_y, drawing[i].radius, 0, 2*Math.PI);
            ctx.stroke();
            ctx.closePath();
        }
    }
}