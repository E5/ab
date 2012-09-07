(
// init
SynthDef(\ab_PlayBuf, {| out=0, bufnum=0, rate=1, trigger=0, startPos=0, loop=0, amp=1 |
	Out.ar(out,
		PlayBuf.ar(2, bufnum, rate, trigger, startPos, loop, doneAction: 2) * amp;
	)
}).add;

q= ();

q.buffers= [
	Buffer.read(s,
//		"/Volumes/Bombe/\ SC/A-B\ simpler/audio/Two_Face.aif",
		Document.current.dir ++ "/audio/Two_Face.aif",
		action: {"Buffer 2 loaded".postln;}
	),
	Buffer.read(s,
//		"/Volumes/Bombe/\ SC/A-B\ simpler/audio/Two_Face_Flt.aif",
		Document.current.dir ++ "/audio/Two_Face_Flt.aif",
		action: {"Buffer 1 loaded".postln;}
	),
];
)

//s.boot;

/**************************************************************************************************/
(
var layout;

q.currentFile= 0;
q.playing= false;
q.amp= [-6, -6].dbamp;

GUI.qt;
//GUI.cocoa;

w = Window.new("A-B", Rect(520, 241, 400, 400)).front;

layout= w.addFlowLayout;

~task= Task({
	var startTime;
	startTime= Main.elapsedTime;
	inf.do{
		var string;
		string= (Main.elapsedTime - startTime).asTimeString;
		string= string[0..10];
		{~playPosTxt.string_(string)}.defer;
		0.01.wait
	};
});

~playPoSld= Slider(w, 392@20)
	.action_({
	});

~playPosTxt= StaticText(w, 124@40)
	.string_(0.asTimeString[0..10])
//	.font_(Font("Monaco", 24))
	.background_(Color.black)
	.stringColor_(Color.yellow)
	.align_(\center);

~play= Button(w, 106@40)
	.states_([
		["play", Color.black, Color.white],
		["stop", Color.black, Color.white],
	])
	.action_({|me|
		if (me.value == 0, {
				~task.pause;
				~player.do{|player| player.free};
				q.playing= false;
			},{
				~task.start;
				~player= [
					Synth(\ab_PlayBuf, [
						\bufnum, q.buffers[0], 
						\amp, ~chooseSnd[0].value * q.amp[0]
					]),
					Synth(\ab_PlayBuf, [
						\bufnum, q.buffers[1],
						\amp, ~chooseSnd[1].value * q.amp[1]
					]),
				];
				q.playing= true;
		})
	})
	.value_(0);

~stop= Button(w, 106@40)
	.states_([
		["stop", Color.black, Color.white],
	])
	.action_({|me|
		if (me.value == 0, {~task.stop;}, {~task.reset;})
	})
	.value_(0)
	.enabled_(false);

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
			[i+1, Color.black, Color.white],
			[i+1, Color.white, Color.black],
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

	~sndLabel[i]= StaticText(c, 215@40)
		.string_(" file name: "
			++ q.buffers[i].path.basename
			++ "\n Peak: 0.0 dB  |  Vol: "
			++ q.amp[i].ampdb.round(0.1).asString
			++" dB"
		)
		.background_(Color.white);

	~sndVol= Knob(c, 30@30)
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
	.states_([
		["+", Color.black, Color.white],
	])
	.action_({|me|
	})
	.value_(0);
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

