# <pep8 compliant>

bl_info = {
    'name': 'KRI Armature format ',
    'author': 'Dzmitry Malyshau',
    'version': (0, 1, 0),
    'blender': (2, 6, 2),
    'api': 36079,
    'location': 'File > Export > Kri Armature (.k3arm)',
    'description': 'Export selected armature into KRI.',
    'warning': '',
    'wiki_url': 'http://code.google.com/p/kri/wiki/Exporter',
    'tracker_url': '',
    'category': 'Import-Export'}

extension = '.k3arm'

# To support reload properly, try to access a package var, if it's there, reload everything
if 'bpy' in locals():
	import imp
	if 'export_kri_arm' in locals():
	        imp.reload(export_kri_arm)


import bpy
from bpy.props			import *
from bpy_extras.io_utils	import ImportHelper, ExportHelper
from io_kri.common		import Settings
from io_kri_arm.arm		import save_arm


class ExportArm( bpy.types.Operator, ExportHelper ):
	'''Export armature to KRI format'''
	bl_idname	= 'export_arm.kri_arm'
	bl_label	= '-= KRI Armature=- (%s)' % extension
	filename_ext	= extension

	filepath	= StringProperty( name='File Path',
		description='Filepath used for exporting the KRI mesh',
		maxlen=1024, default='')
	show_info	= BoolProperty( name='Show infos',
		description='Print information messages (i)',
		default=Settings.showInfo )
	show_warn	= BoolProperty( name='Show warnings',
		description='Print warning messages (w)',
		default=Settings.showWarning )
	break_err	= BoolProperty( name='Break on error',
		description='Stop the process on first error',
		default=Settings.breakError )
	frame_conv	= FloatProperty( name='Frames per second',
		description='Conversion rate from frames to seconds',
		default=Settings.kFrameSec, min=0.1, max=100000.0 )
	key_bezier	= BoolProperty( name='Include Bezier points',
		description='Store additional information for smoother interpolation',
		default=Settings.keyBezier )

	def execute(self, context):
		Settings.showInfo		= self.properties.show_info
		Settings.showWarning	= self.properties.show_warn
		Settings.breakError		= self.properties.break_err
		Settings.kFrameSec		= self.properties.frame_conv
		Settings.keyBezier		= self.properties.key_bezier
		save_arm(self.properties.filepath, context)
		return {'FINISHED'}


# Add to a menu
def menu_func(self, context):
	self.layout.operator( ExportArm.bl_idname, text= ExportArm.bl_label )

def register():
	bpy.utils.register_module(__name__)
	bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
	bpy.utils.unregister_module(__name__)
	bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == '__main__':
	register()
