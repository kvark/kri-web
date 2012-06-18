#library('kri:draw');
#import('arm.dart',		prefix:'arm');
#import('mesh.dart',	prefix:'me');
#import('phys.dart',	prefix:'phys');
#import('ren.dart',		prefix:'ren');
#import('shade.dart',	prefix:'shade');


class EntityBase implements shade.IDataSource	{
	me.Mesh mesh		= null;
	shade.Effect effect	= null;
	rast.State state	= null;
	final Map<String,Object> data;
	
	EntityBase():
		data = new Map<String,Object>();

	void fillData( final Map<String,Object> block ){
		for (String key in data.getKeys())
			block[key] = data[key];
	}
}


class Material implements shade.IDataSource	{
	final String name;
	final Map<String,Object> data;
	final List<String> metas;
	final Map<int,String> code;
	
	Material( this.name ):
		data = new Map<String,Object>(),
		metas = new List<String>(),
		code = new Map<int,String>();
	
	void fillData(final Map<String,Object> block)	{
		for (String key in block.getKeys())
			data[key] = block[key];
	}
}


class Entity	{
	final me.Mesh		mesh		= null;
	final Material		material	= null;
	final arm.Armature	skel		= null;
	final phys.Body		body		= null;
}


class Technique implements shade.IDataSource	{
	final Collection<String> _usedMetas;
	final Map<Entity,shade.Effect> _effectMap;

	Technique( this._usedMetas ):
		_effectMap = new Map<Entity,shade.Effect>();

	int draw( final Iterable<Entity> entities, final ren.Process processor ){
		final ren.Target target = null;
		final ren.State state = null;
		int num = 0;
		for (final Entity e in entities)	{
			shade.Effect effect = _effectMap[e];
			if (effect == null)	{
				// create effect
				_effectMap[e] = effect;
			}
			final shade.IDataSource ds = new shade.SourceAdapter( [this,e.material,e.skel] );
			processor.draw( target, e.mesh, effect, state, ds );
			++num;
		}
		return num;
	}
}
