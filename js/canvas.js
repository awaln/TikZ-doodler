var DRAW_COLOR = "black";
var DATE = new Date();

var current_stroke_x = [];
var current_stroke_y = [];

var canvas, ctx, flag = false,
    prevX = 0,
    currX = 0,
    prevY = 0,
    currY = 0,
    dot_flag = false;

var x = "black",
    y = 2;

function init() {
    canvas = document.getElementById('can');
    ctx = canvas.getContext("2d");
    w = canvas.width;
    h = canvas.height;

    // mouse listeners
    canvas.addEventListener("mousemove", function (e) {
        findxy('move', e)
    }, false);
    canvas.addEventListener("mousedown", function (e) {
        findxy('down', e)
    }, false);
    canvas.addEventListener("mouseup", function (e) {
        findxy('up', e)
    }, false);
    canvas.addEventListener("mouseout", function (e) {
        findxy('out', e)
    }, false);

    // touch listeners
    canvas.addEventListener("touchmove", function (e) {
        findxy('move', e.changedTouches[0]);
        //e.preventDefault();
    }, false);
    canvas.addEventListener("touchstart", function (e) {
        findxy('down', e.changedTouches[0]);
        e.preventDefault();
    }, false);
    canvas.addEventListener("touchend", function (e) {
        findxy('up', e.changedTouches[0]);
        e.preventDefault();
    }, false);
    canvas.addEventListener("touchleave", function (e) {
        findxy('out', e.changedTouches[0]);
        e.preventDefault();
    }, false);
    canvas.addEventListener("touchcancel", function (e) {
        findxy('out', e.changedTouches[0]);
        e.preventDefault();
    }, false);
}

function draw() {
    ctx.beginPath();
    ctx.moveTo(prevX, prevY);
    ctx.lineTo(currX, currY);
    ctx.strokeStyle = x;
    ctx.lineWidth = y;
    ctx.stroke();
    ctx.closePath();

    current_stroke_x.push(currX);
    current_stroke_y.push(currY);
}

function findxy(res, e) {
    if (res == 'down') {
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
    if (res == 'up' || res == "out") {
        flag = false;
    }
    if (res == 'move') {
        if (flag) {
            prevX = currX;
            prevY = currY;
            currX = e.clientX - canvas.offsetLeft;
            currY = e.clientY - canvas.offsetTop;
            draw();
        }
    }
}