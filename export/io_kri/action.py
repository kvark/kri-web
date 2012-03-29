__author__ = ['Dzmitry Malyshau']
__bpydoc__ = 'Action module of KRI exporter.'

from io_kri.common	import *


###  ANIMATION CURVES   ###

def gather_anim(ob):
	ad = ob.animation_data
	if not ad: return []
	all = [ns.action for nt in ad.nla_tracks for ns in nt.strips]
	if ad.action not in ([None]+all):
		Writer.inst.log(1,'w','current action (%s) is not finalized' % (ad.action.name))
		all.append( ad.action )
	return all


def save_actions(ob):
	import re
	out = Writer.inst
	if not ob: return
	for act in gather_anim(ob):
		offset,nf = act.frame_range
		rnas,curves = {},set() # [attrib_name][sub_id]
		indexator,n_empty = None,0
		# gather all
		for f in act.fcurves:
			attrib = f.data_path
			if not len(attrib):
				n_empty += 1
				continue
			#out.logu(2, 'passed [%d].%s.%d' %(bid,attrib,f.array_index) )
			if not attrib in rnas:
				rnas[attrib] = []
			lis = rnas[attrib]
			if len(lis)<=f.array_index:
				while len(lis)<f.array_index:
					lis.append(None)
				lis.append(f)
			else:	lis[f.array_index] = f	
		# write header or exit
		if not len(rnas): continue
		out.begin( 'action' )
		out.text( act.name )
		out.pack('f', nf * Settings.kFrameSec )
		out.logu(1,'+anim: %s, %d frames, %d groups' % ( act.name,nf,len(act.groups) ))
		if n_empty:
			out.log(2,'w','%d empty curves detected' % (n_empty))
		# write in packs
		for attrib,sub in rnas.items():
			curves.add( '%s[%d]' % (attrib,len(sub)) )
			out.begin('curve')
			out.text( attrib )
			out.pack('B', len(sub) )
			save_curve_pack( sub, offset )
			out.end()
		out.logu(2, ', '.join(curves))
		out.end()	#action

		

###  ACTION:CURVES   ###

def save_curve_pack(curves,offset):
	out = Writer.inst
	if not len(curves):
		out.log(2,'w','zero length curve pack')
		out.pack('H',0)
		return
	num = len( curves[0].keyframe_points )
	extra = curves[0].extrapolation
	#out.log(2,'i', '%s, keys %d' %(curves,num))
	for c in curves:
		assert len(c.keyframe_points) == num
		assert c.extrapolation == extra
	out.pack('HB', num, (extra == 'LINEAR'))
	for i in range(num):
		def h0(k): return k.co
		def h1(k): return k.handle_left
		def h2(k): return k.handle_right
		kp = tuple(c.keyframe_points[i] for c in curves)
		frame = kp[0].co[0]
		out.pack('f', (frame-offset) * Settings.kFrameSec)
		#print ('Time', x, i, data)
		for fun in (h0,h1,h2): # ignoring handlers time
			out.array('f', (fun(k)[1] for k in kp) )
