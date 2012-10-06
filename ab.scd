(
// init

s.boot; // start server

// synth
SynthDef(\ab_PlayBuf, {| out=0, bufnum=0, rate=1, trigger=0, startPos=0, loop=0, amp=1 |
	Out.ar(out,
		PlayBuf.ar(2, bufnum, rate, trigger, startPos, loop, doneAction: 2) * amp;
	)
}).add;
)

/**************************************************************************************************/

(
// data
q= ();

// q.buffers= [nil, nil];
q.buffers= [
	Buffer.read(s,
		thisProcess.nowExecutingPath.dirname ++ "/audio/Two_Face.aif",
		action: {"Buffer A loaded".postln;}
	),
	Buffer.read(s,
		thisProcess.nowExecutingPath.dirname ++ "/audio/Two_Face_Flt.aif",
		action: {"Buffer B loaded".postln;}
	),
];

GUI.qt;
//GUI.cocoa;

)

/**************************************************************************************************/

(
var layout;

q.currentFile= 0;
q.playing= false;
q.amp= [-6, -6].dbamp;
q.currentFrame= 0;
q.spec= [0, q.buffers[0].numFrames, \lin,].asSpec;

w = Window.new("A-B", Rect(520, 241, 420, 400)).front;
w.onClose= {
	// free buffers
	// q.buffers.do{|i| i.free};
	// q.buffers= [nil, nil];
};

layout= w.addFlowLayout;

~task= Task({
	var startTime;
	startTime= Main.elapsedTime;
	inf.do{| i |
		var string, spec;
		q.currentFrame= ((i/100) * (q.buffers[0].sampleRate));
		string= (Main.elapsedTime - startTime).asTimeString;
		string= string[0..10];
		{
			~playPoSld.value_(q.spec.unmap(q.currentFrame));
			~playPosTxt.string_(string);
		}.defer;
		0.01.wait;
	};
});

~playPoSld= Slider(w, 412@20)
.action_({|me|
	q.currentFrame= q.spec.map(me.value);
	if (q.playing, {
		~task.pause;
		~player.do{|player| player.free};
		q.playing= false;
	});
	~task.start;
	~player= [
		Synth(\ab_PlayBuf, [
			\bufnum, q.buffers[0],
			\amp, ~chooseSnd[0].value * q.amp[0],
			\startPos, q.currentFrame
		]),
		Synth(\ab_PlayBuf, [
			\bufnum, q.buffers[1],
			\amp, ~chooseSnd[1].value * q.amp[1],
			\startPos, q.currentFrame

		]),
	];
	q.playing= true;
});

~playPosTxt= StaticText(w, 124@40)
.string_(0.asTimeString[0..10])
//	.font_(Font("Monaco", 24))
.background_(Color.black)
.stringColor_(Color.yellow)
.align_(\center);

~play= Button(w, 111@40)
.states_([
	["play", Color.black, Color.white],
	["stop", Color.black, Color.white],
])
.action_({|me|
	if (me.value == 0, {
		~task.pause;
		~player.do{|player| player.free};
		q.playing= false;
		q.currentFrame= 0;
		{
			~playPoSld.value_(q.spec.unmap(q.currentFrame));
			~playPosTxt.string_(0.asTimeString[0..10]);
		}.defer;
		},{
			~task.start;
			~player= [
				Synth(\ab_PlayBuf, [
					\bufnum, q.buffers[0],
					\amp, ~chooseSnd[0].value * q.amp[0],
					\startPos, q.currentFrame
				]),
				Synth(\ab_PlayBuf, [
					\bufnum, q.buffers[1],
					\amp, ~chooseSnd[1].value * q.amp[1],
					\startPos, q.currentFrame

				]),
			];
			q.playing= true;
	})
})
.value_(0);

~stop= Button(w, 111@40)
.states_([
	["stop", Color.black, Color.white],
])
.action_({|me|
	if (me.value == 0, {~task.stop;}, {~task.reset;})
})
.value_(0)
.enabled_(false);

c= CompositeView(w, 54@40);
c.addFlowLayout(0@0, 0@0);

~loadSoundfile= [
	(Button(c, 54@20)
		.states_([ ["load a", Color.black, Color.white], ])
		.action_({|me|
			Dialog.openPanel({|path|
				path.postln;
				if (path.isSoundFile, {
					q.buffers[0]= Buffer.read(s,
						path,
						action: {{
							~sndLabel[0].string_(" file name: "
								++ q.buffers[0].path.basename
								++ "\n Peak: 0.0 dB  |  Vol: "
								++ q.amp[0].ampdb.round(0.1).asString
								++" dB"
							);
							"Buffer A loaded".postln;
					}.defer});
					},{
						SCAlert("Sorry, that doesn't seem to be a soundfile.", ["Ok"])
				})
				},{
					"cancelled".postln;
				},
				false
	)})),
	(Button(c, 54@20)
		.states_([ ["load b", Color.black, Color.white], ])
		.action_({|me|
			Dialog.openPanel({|path|
				path.postln;
				if (path.isSoundFile, {
					q.buffers[1]= Buffer.read(s,
						path,
						action: {
							{~sndLabel[1].string_(" file name: "
								++ q.buffers[1].path.basename
								++ "\n Peak: 0.0 dB  |  Vol: "
								++ q.amp[1].ampdb.round(0.1).asString
								++" dB"
								);
								"Buffer B loaded".postln;}.defer});
					},{
						SCAlert("Sorry, that doesn't seem to be a soundfile.", ["Ok"])
				})
				},{
					"cancelled".postln;
				},
				false
	)})),
];

layout.nextLine;

c= CompositeView(w, w.bounds.width-8@140)
.background_(Color.grey.alpha_(0.3));
c.addFlowLayout;

~chooseSnd= Array.fill(2);
~sndLabel= Array.fill(2);
~sndVol= Array.fill(2);

2.do{|i|
	~chooseSnd[i]= Button(c, 120@40)
	.states_([
		[(i+65).asAscii.asString, Color.black, Color.white],
		[(i+65).asAscii.asString, Color.white, Color.black],
	])
	.action_({|me|
		if (me.value == 1, {
			~chooseSnd.do{|j| j.value=0;};
			me.value= 1;
			q.currentFile = i;
		});
		~player.do{|item, j| item.set(\amp, ~chooseSnd[j].value * q.amp[j]);};
	})
	.value_(if (i == q.currentFile, {1}, {0}));

	if (q.buffers[i].notNil, {x= q.buffers[i].path.basename.postln}, {x= "no file loaded".postln});

	~sndLabel[i]= StaticText(c, 225@40)
	.string_(" file name: "
		++ x
		++ "\n Peak: 0.0 dB  |  Vol: "
		++ q.amp[i].ampdb.round(0.1).asString
		++" dB"
	)
	.background_(Color.white);

	c.decorator.shift(7, 0);

	~sndVol= Knob(c, 40@40)
	.action_({|me|
		q.amp[i]= me.value;
		~sndLabel[i].string_(" file name: "
			++ q.buffers[i].path.basename
			++ "\n Peak: 0.0 dB  |  Vol: "
			++ q.amp[i].ampdb.round(0.1).asString
			++" dB"
		);
		if (q.playing, {
			~player[i].set(\amp, q.amp[i] * ~chooseSnd[i].value);
		});
	})
	.value_(q.amp[i]);
};

layout.nextLine;

~addSnd= Button(c, 30@30)
.states_([ ["+", Color.black, Color.white] ])
.action_({|me|
})
.value_(0)
.enabled_(false);
)

/**************************************************************************************************/

(
// clean up
q.buffers.do{|i| i.free}
)

/**************************************************************************************************/

//~task.start;
//~task.pause;
//~task.resume;
//~task.reset;
//~task.stop;
/*0.09*44100

q.buffers[0].numFrames.reciprocal
q.buffers[0].sampleRate*/