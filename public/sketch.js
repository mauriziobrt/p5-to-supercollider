//======================================================================
// VIDEO PART
//======================================================================

// The video
let video;
// For displaying the label
let label = "waiting...";
// The classifier
let classifier;
let modelURL = 'https://teachablemachine.withgoogle.com/models/bXy2kDNi/';

function preload() {
  classifier = ml5.imageClassifier(modelURL + 'model.json');
}

//======================================================================
// Server Part
//======================================================================

let ws;

const statusDiv = document.getElementById('status');

function updateStatus(message, isError = false) {
    statusDiv.textContent = message;
    statusDiv.style.color = isError ? 'red' : 'black';
}

function connectWebSocket() {
    ws = new WebSocket('ws://localhost:7700');
    
    ws.onopen = () => {
        console.log('Connected to WebSocket server');
        updateStatus('Connected to WebSocket server');
    };
    
    ws.onclose = () => {
        console.log('Disconnected from WebSocket server');
        updateStatus('Disconnected from WebSocket server - Retrying...', true);
        // Try to reconnect in 5 seconds
        setTimeout(connectWebSocket, 5000);
    };
    
    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        updateStatus('WebSocket error occurred', true);
    };
}

function sendOSCMessage(frequency, address) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        const message = {
            address: address,
            args: frequency  // Send frequency as a number
        };
        ws.send(JSON.stringify(message));
        console.log('Sent message:', message);
        updateStatus(`Sent frequency: ${frequency}Hz`);
    } else {
        updateStatus('WebSocket not connected', true);
    }
}

// Connect when the page loads
connectWebSocket();

//======================================================================
// MAIN Part
//======================================================================

function setup() {
  createCanvas(windowWidth, windowHeight);
  // Create the video
  video = createCapture(VIDEO);
  video.hide();
  // STEP 2: Start classifying
  classifyVideo();
}

// STEP 2 classify the videeo!
function classifyVideo() {
  classifier.classify(video, gotResults);
}

function draw() {
  background(220);
  
  //circle in the center with a width of 100
  //when mouse button is pressed, circles turn black
  if (mouseIsPressed === true) {
    fill(0);
  } else {
    fill(255); 
  }
  // Draw the video
  image(video,0, 0, windowWidth, windowHeight);
  //white circles drawn at mouse position
  circle(mouseX, mouseY, 100);
  // STEP 4: Draw the label
  textSize(32);
  textAlign(CENTER, CENTER);
  fill(255);
  text(label, width / 2, height - 16);

  // Pick an emoji, the "default" is train
  let emoji = "🚂";
  if (label == "Rainbow") {
    emoji = "🌈";
  } else if (label == "Unicorn") {
    emoji = "🦄";
  } else if (label == "Ukulele") {
    emoji = "🎸";
  }

  // Draw the emoji
  textSize(256);
  text(emoji, width / 2, height / 2);
}

// STEP 3: Get the classification!
function gotResults(error, results) {
  // Something went wrong!
  if (error) {
    console.error(error);
    return;
  }
  // Store the label and classify again!
  label = results[0].label;
  classifyVideo();
}

function mouseDragged() {
  // console.log("ciao")
  bufplaying = 0;
  if (mouseX < (screen.width/ 4)) {
    bufplaying = 0;
  }
  else if (mouseX > (screen.width/ 4) && mouseX < (screen.width/ 2)) {
    bufplaying = 1;
  } 
  else if (mouseX > (screen.width/ 2) && mouseX < (screen.width/4 *3)) {
    bufplaying = 2;
  }
  else {
    bufplaying = 3;
  }
  sendOSCMessage([mouseY, mouseX, bufplaying], '/control');
}

