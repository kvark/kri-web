__author__ = ['Dzmitry Malyshau']
__bpydoc__ = 'Armature module of KRI exporter.'

import mathutils
from io_kri.common	import *
from io_kri.action	import *

def save_arm(filename,context):
	# ready...
	obj = None
	for ob in context.scene.objects:
		if (ob.type == 'ARMATURE' and ob.select):
			obj = ob
			break
	if obj == None:
		return
	skel = obj.data
	# steady...
	print('Exporting Armature.')
	out = Writer.inst = Writer(filename)
	out.begin('k3arm')
	nbon = len(skel.bones)
	out.logu(1,'%d bones' % (nbon))
	# go!
	out.pack('B', nbon)
	for bone in skel.bones:
		parid,par,mx = -1, bone.parent, bone.matrix_local.copy()
		if not (bone.use_inherit_scale and bone.use_deform):
			out.log(2,'w','weird bone: %s' % (bone.name))
		if par:
			parid = skel.bones.keys().index( par.name )
			mx = par.matrix_local.copy().inverted() * mx
		out.text( bone.name )
		out.pack('B', parid+1)
		save_matrix(mx)
	# animations
	save_actions(obj)
	# done
	out.end();	#k3arm
	out.conclude()
	print('Done.')
