# Step 1

From terminal:

npm init -y

# Step 2

From terminal:

node server.js

# Step 3

Open the server page. Then launch supercollider and test if the communication is working. You should evaluate the blocks: 
(Ndef(\oscControlled, {
    var freq = \freq.kr(440);
    var amp = \amp.kr(0.5);
    var sig = SinOsc.ar(freq) * amp;
    sig ! 2 // stereo output
});)


// Start playing the Ndef
Ndef(\oscControlled).play;

// Create an OSC responder that will update the Ndef parameters
(
OSCdef(\freqControl, {|msg, time, addr, recvPort|
    var freqValue = msg[1];
	var ampValue = msg[2].linlin(0, 1600, 0, 1);
    // Set the frequency parameter of the Ndef
    Ndef(\oscControlled).set(\freq, freqValue, \amp, ampValue);
	Ndef(\player).set(\bufnum, ~buffers[msg[3]].bufnum);
}, '/control');
)