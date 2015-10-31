(function() {
  var DRAW_COLOR = 'black';
  var DATE = new Date;
  var strokes_x = [];
  var strokes_y = [];
  var times = [];
  var current_stroke_x = [];
  var current_stroke_y = [];
  var current_times = [];
  var canvas = void 0;
  var ctx = void 0;
  var flag = false;
  var prevX = 0;
  var currX = 0;
  var prevY = 0;
  var currY = 0;
  var curr_start_time = 0;
  var dot_flag = false;
  var x = 'black';
  var y = 2;

  // Main object for storing doodle info
  var drawing = {
    nodes: {},
    loners: [],
    edges: {},
    arrows: [],
    nodelabels: {},
    edgelabels: {}
  };

  /*_____    _____    _____   _____   _______   _____   ______  ______   _____  
   |  __ \  |_   _|  / ____| |_   _| |__   __| |_   _| |___  / |  ____| |  __ \ 
   | |  | |   | |   | |  __    | |      | |      | |      / /  | |__    | |__) |
   | |  | |   | |   | | |_ |   | |      | |      | |     / /   |  __|   |  _  / 
   | |__| |  _| |_  | |__| |  _| |_     | |     _| |_   / /__  | |____  | | \ \ 
   |_____/  |_____|  \_____| |_____|    |_|    |_____| /_____| |______| |_|  \_\                                                                         
   */

  /*
   * Initializes listeners for drawing with a mouse or touch
   * Called on page load
   */
  this.init = function() {
    var h, w;
    canvas = document.getElementById('can');
    ctx = canvas.getContext('2d');
    w = canvas.width;
    h = canvas.height;
    canvas.addEventListener('mousemove', (function(e) {
      findxy('move', e);
    }), false);
    canvas.addEventListener('mousedown', (function(e) {
      findxy('down', e);
    }), false);
    canvas.addEventListener('mouseup', (function(e) {
      findxy('up', e);
    }), false);
    canvas.addEventListener('mouseout', (function(e) {
      findxy('out', e);
    }), false);
    canvas.addEventListener('touchmove', (function(e) {
      findxy('move', e.changedTouches[0]);
    }), false);
    canvas.addEventListener('touchstart', (function(e) {
      findxy('down', e.changedTouches[0]);
      e.preventDefault();
    }), false);
    canvas.addEventListener('touchend', (function(e) {
      findxy('up', e.changedTouches[0]);
      e.preventDefault();
    }), false);
    canvas.addEventListener('touchleave', (function(e) {
      findxy('out', e.changedTouches[0]);
      e.preventDefault();
    }), false);
    canvas.addEventListener('touchcancel', (function(e) {
      findxy('out', e.changedTouches[0]);
      e.preventDefault();
    }), false);
  };

  /*
   * Draws a line from the last point to the current one
   * PrevX, PrevY ---- CurrX, CurrY
   */
  draw = function() {
    ctx.beginPath();
    ctx.moveTo(prevX, prevY);
    ctx.lineTo(currX, currY);
    ctx.strokeStyle = x;
    ctx.lineWidth = y;
    ctx.fillStyle = 'white';
    ctx.stroke();
    ctx.closePath();
    current_stroke_x.push(currX);
    current_stroke_y.push(currY);
    current_times.push(new Date().getTime() - curr_start_time);
  };

  /*
   * Takes one of the event listeners from init and gets the current location
   * of the drawing tool.
   */
  findxy = function(res, e) {
    if (res === 'down') {
      prevX = currX;
      prevY = currY;
      currX = e.clientX - canvas.offsetLeft;
      currY = e.clientY - canvas.offsetTop;
      curr_start_time = new Date().getTime();
      flag = true;
      dot_flag = true;
      if (dot_flag) {
        ctx.beginPath();
        ctx.fillStyle = x;
        ctx.fillRect(currX, currY, 2, 2);
        ctx.closePath();
        dot_flag = false;
      }
    }
    if (res === 'up' || res === 'out') {
      flag = false;
      if (current_stroke_x.length > 0) {
        strokes_x.push(current_stroke_x);
        strokes_y.push(current_stroke_y);
        times.push(current_times);
        current_stroke_x = [];
        current_stroke_y = [];
        current_times = [];
      }
    }
    if (res === 'move') {
      if (flag) {
        prevX = currX;
        prevY = currY;
        currX = e.clientX - canvas.offsetLeft;
        currY = e.clientY - canvas.offsetTop;
        draw();
      }
    }
  };

  /*            _____   _  __    _    _    _____   ______   _____  
       /\      / ____| | |/ /   | |  | |  / ____| |  ____| |  __ \ 
      /  \    | (___   | ' /    | |  | | | (___   | |__    | |__) |
     / /\ \    \___ \  |  <     | |  | |  \___ \  |  __|   |  _  / 
    / ____ \   ____) | | . \    | |__| |  ____) | | |____  | | \ \ 
   /_/    \_\ |_____/  |_|\_\    \____/  |_____/  |______| |_|  \_\                                                             
   */

  /*
   * Takes the current list of strokes and processes them with recognize()
   * one by one.
   */
  this.recognize_all = function() {
    for (var i = 0; i < strokes_x.length; i++) {
      drawing = recognize(strokes_x[i], strokes_y[i], times[i], ctx, canvas, 
        drawing);
    }
    drawing = relate(drawing);
    pretty_draw(ctx, canvas, drawing);
    ask_user();
  };

  var CONFIDENCE_THRESHOLD = .81;

  ask_user = function() {
    var answers, guess, j, len, node, ref, x_point, y_point;
    ref = Object.keys(drawing.nodes);
    for (j = 0, len = ref.length; j < len; j++) {
      node = ref[j];
      if (drawing.nodes[node].type["circle"] < CONFIDENCE_THRESHOLD && 
          drawing.nodes[node].type["polygon"] < CONFIDENCE_THRESHOLD) {
        console.log(drawing.nodes[node]);
        pretty_draw(ctx, canvas, drawing);
        x_point = drawing.nodes[node].center_x;
        y_point = drawing.nodes[node].center_y + drawing.nodes[node].radius;
        ctx.beginPath();
        ctx.moveTo(x_point, y_point);
        ctx.lineTo(x_point + 10, y_point + 50);
        ctx.lineTo(x_point - 10, y_point + 50);
        ctx.lineTo(x_point, y_point);
        ctx.closePath();
        ctx.fillStyle = 'red';
        ctx.fill();
        ctx.fillStyle = 'white';
        ctx.stroke();
        if (drawing.nodes[node].type["circle"] > 
            drawing.nodes[node].type["polygon"]) {
          guess = "<p>I'm not sure what you've drawn here. My best guess is a" +
            " circle. Is that right?</p>";
          answers = "<button onclick='answer(0)'>yes</button><button onclick=" +
            "'answer(1)'>no</button>";
        } else {
          guess = "<p>I'm not sure what you've drawn here. My best guess is a" + 
            " polygon. Is that right?</p>";
          answers = "<button onclick='answer(1)'>yes</button><button onclick=" +
            "'answer(0)'>no</button>";
        }
        document.getElementById("askbox").innerHTML = guess + answers;
        return;
      }
    }
    return document.getElementById("askbox").innerHTML = "";
  };

  var DRAWABLE_SHAPES = ["circle", "polygon"];

  this.answer = function(int) {
    var j, len, node, ref;
    ref = Object.keys(drawing.nodes);
    for (j = 0, len = ref.length; j < len; j++) {
      var node = ref[j];
      console.log(drawing.nodes[node]);
      if (drawing.nodes[node].type["circle"] < CONFIDENCE_THRESHOLD && 
          drawing.nodes[node].type["polygon"] < CONFIDENCE_THRESHOLD) {
        drawing.nodes[node].type[DRAWABLE_SHAPES[int]] = 1;
      }
    }
    pretty_draw(ctx, canvas, drawing);
    return ask_user();
  };

}).call(this);
