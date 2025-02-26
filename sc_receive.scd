// First testing system
(
OSCdef(\testReceiver, {|msg, time, addr, recvPort|
    msg.postln; // Print received message
    {
		/*SinOsc.ar(Rand(200,500) ! 2) * EnvGen.kr(Env.perc, doneAction: Done.freeSelf);*/
	/*	Pluck.ar(WhiteNoise.ar(0.1), EnvGen.kr(Env.perc, doneAction: Done.freeSelf), (Rand(200,500).reciprocal) ! 2 , Rand(200,500).reciprocal, 10);*/
		Pluck.ar(WhiteNoise.ar(0.1), EnvGen.kr(Env.perc, doneAction: Done.freeSelf), (msg[1].reciprocal) ! 2 , (msg[1].reciprocal) ! 2 , 10);
    }.play;
}, '/test');
)

OSCFunc({ |msg, time, addr, recvPort|
    msg.postln;
}, '/test');

OSCdef.all;

(
OSCdef(\testReceiver, {|msg, time, addr, recvPort|
    msg.postln; // Print received message
    {
		Pluck.ar(WhiteNoise.ar(0.1), EnvGen.kr(Env.perc, doneAction: Done.freeSelf), (msg[1].reciprocal) ! 2 , (msg[1].reciprocal) ! 2 , 10);
    }.play;
}, '/test');
)

(
// First, create a SynthDef that will be available on the server
SynthDef(\pluckOsc, { |freq=440|
    var snd = Pluck.ar(WhiteNoise.ar(0.1), EnvGen.kr(Env.perc, doneAction: Done.freeSelf), freq.reciprocal, freq.reciprocal, 10);
    Out.ar(0, snd ! 2);
}).add;

// Then set up an OSCFunc that creates a Synth when message is received
OSCFunc({ |msg, time, addr, recvPort|
    msg.postln; // Print received message
    Synth(\pluckOsc, [\freq, msg[1]]);
}, '/test');
)
n = NetAddr("127.0.0.1", 57110); // local machine

// OSC controlled sound synthesis

// Playback via OSC

~buff_gatti = []


//First create a synth with Ndef
(Ndef(\oscPlayerControlled, {
    var rate = \rate.kr(1);
    var amp = \amp.kr(0.5);
	var sig = PlayBuf.ar(2, ~buff_gatti, rate, trigger, 0, 1000, Done.freeself) * amp;
    sig ! 2 // stereo output
});)

(
OSCdef(\playerReceiver, {|msg, time, addr, recvPort|
    msg.postln; // Print received message
    {
		PlayBuf.ar(2)

    }.play;
}, '/player');
)


// Store a dict in your buffer so you can change  the sample easily


(
OSCdef(\testReceiver, {|msg, time, addr, recvPort|
    msg.postln; // Print received message
    {
		Pluck.ar(WhiteNoise.ar(0.1), EnvGen.kr(Env.perc, doneAction: Done.freeSelf), (msg[1].reciprocal) ! 2 , (msg[1].reciprocal) ! 2 , 10);
    }.play;
}, '/test');
)

// Can I have an OSCdef inside an Ndef?

// Create an Ndef with a synth that will be controlled via OSC
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


// Another OSC responder for amplitude
(
OSCdef(\ampControl, {|msg, time, addr, recvPort|
	// I use linlin to scale the value here, but you can work out something better on the p5 side of the message
    var ampValue = msg[1].linlin(0, 1600, 0, 1);
    // Set the amplitude parameter of the Ndef
    Ndef(\oscControlled).set(\amp, ampValue);
}, '/amp/control');
)

// To test it without actual OSC messages:
NetAddr.localAddr.sendMsg('/freq/control', 160);
NetAddr.localAddr.sendMsg('/amp/control', 1000);
~buffers


// Load files, manipulate, and create buffers in one step
(
~audioFolder = "/Users/maurizioberta/Documents/Max 8/Packages/MuBu For Max/examples/mubu-pipo/overview/corpus/";
// SoundFile.collect(~audioFolder ++ "*").do { |f| f.path.postln };
// ~buffers = SoundFile.collect(~audioFolder ++ "*.wav").collect ;
~buffers = SoundFile.collect(~audioFolder ++ "*.wav").collect { |sf|
	var data = FloatArray.newClear(sf.numFrames * sf.numChannels);
	sf.openRead;
	sf.readData(data);
	sf.close;
// 	// Optional data manipulation can go here: data = data.normalize;
	Buffer.loadCollection(s, data);
	};
)

// The rest is the same as above
Ndef(\player, { |bufnum=0, rate=2, amp=0.5| PlayBuf.ar(1, bufnum, rate, loop: 1) * amp ! 2 }).play;
Ndef(\player).set(\bufnum, ~buffers[2].bufnum);
~switch = { |idx| Ndef(\player).set(\+bufnum, ~buffers[idx].bufnum) };

(
OSCdef(\bufControl, {|msg, time, addr, recvPort|
    var bufnmr = msg[1];
	Ndef(\player).fadeTime = 5;
    Ndef(\player).set(\bufnum, ~buffers[bufnmr].bufnum);
}, '/buf/nmr');
)

Ndef(\player).fadeTime = 20;

Ndef.clear(3); // clear all after 3 seconds