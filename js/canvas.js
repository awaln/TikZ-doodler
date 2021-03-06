// Generated by CoffeeScript 1.9.1
(function() {
  var DATE, DRAW_COLOR, canvas, ctx, currX, currY, current_stroke_x, current_stroke_y, dot_flag, draw, findxy, flag, prevX, prevY, x, y;

  DRAW_COLOR = 'black';

  DATE = new Date;

  current_stroke_x = [];

  current_stroke_y = [];

  canvas = void 0;

  ctx = void 0;

  flag = false;

  prevX = 0;

  currX = 0;

  prevY = 0;

  currY = 0;

  dot_flag = false;

  x = 'black';

  y = 2;

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
  };

  findxy = function(res, e) {
    if (res === 'down') {
      prevX = currX;
      prevY = currY;
      currX = e.clientX - canvas.offsetLeft;
      currY = e.clientY - canvas.offsetTop;
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
        recognize(current_stroke_x, current_stroke_y, ctx, canvas);
        current_stroke_x = [];
        current_stroke_y = [];
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

}).call(this);
