# <pep8 compliant>

bl_info = {
    'name': 'KRI Mesh format ',
    'author': 'Dzmitry Malyshau',
    'version': (0, 1, 0),
    'blender': (2, 6, 2),
    'api': 36079,
    'location': 'File > Export > Kri Mesh (.k3mesh)',
    'description': 'Export selected mesh into KRI.',
    'warning': '',
    'wiki_url': 'http://code.google.com/p/kri/wiki/Exporter',
    'tracker_url': '',
    'category': 'Import-Export'}

extension = '.k3mesh'

# To support reload properly, try to access a package var, if it's there, reload everything
if 'bpy' in locals():
	import imp
	if 'export_kri_mesh' in locals():
	        imp.reload(export_kri_mesh)


import bpy
from bpy.props			import *
from bpy_extras.io_utils	import ImportHelper, ExportHelper
from io_mesh_kri.common	import Settings
from io_mesh_kri.mesh	import save_mesh


class ExportMesh( bpy.types.Operator, ExportHelper ):
	'''Export mesh to KRI format'''
	bl_idname	= 'export_mesh.kri_mesh'
	bl_label	= '-= KRI Mesh=- (%s)' % extension
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
	put_normal	= BoolProperty( name='Put normals',
		description='Export vertex normals',
		default=Settings.putNormal )
	put_quat	= BoolProperty( name='Put quaternions',
		description='Export vertex quaternions',
		default=Settings.putQuat )
	put_uv		= BoolProperty( name='Put UV layers',
		description='Export vertex UVs',
		default=Settings.putUv )
	put_color	= BoolProperty( name='Put color layers',
		description='Export vertex colors',
		default=Settings.putColor )
	quat_int	= BoolProperty( name='Process quaternions',
		description='Prepare mesh quaternions for interpolation',
		default=Settings.doQuatInt )

	def execute(self, context):
		Settings.showInfo	= self.properties.show_info
		Settings.showWarning	= self.properties.show_warn
		Settings.breakError	= self.properties.break_err
		Settings.putNormal	= self.properties.put_normal
		Settings.putQuat	= self.properties.put_quat
		Settings.putUv		= self.properties.put_uv
		Settings.putColor	= self.properties.put_color
		Settings.doQuatInt	= self.properties.quat_int
		save_mesh(self.properties.filepath, context)
		return {'FINISHED'}


# Add to a menu
def menu_func(self, context):
	self.layout.operator( ExportMesh.bl_idname, text= ExportMesh.bl_label )

def register():
	bpy.utils.register_module(__name__)
	bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
	bpy.utils.unregister_module(__name__)
	bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == '__main__':
	register()
