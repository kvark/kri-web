#library('kri:draw');
#import('ani.dart',		prefix:'ani');
#import('math.dart',	prefix:'math');		// for Entity.getModelMatrix()
#import('mesh.dart',	prefix:'me');
#import('phys.dart',	prefix:'phys');
#import('rast.dart',	prefix:'rast');
#import('ren.dart',		prefix:'ren');
#import('shade.dart',	prefix:'shade');
#import('space.dart',	prefix:'space');	// for Entity.node
#import('view.dart',	prefix:'view');		// for Technique.camera


interface IModifier extends shade.IDataSource, ani.IPlayer	{
	String getName();
	String getVertexCode();
}

class ModDummy implements IModifier	{
	String getName()	=> 'Dummy';
	String getVertexCode()	=>
			'vec3 modifyPosition(vec3 pos)	{ return pos; }'"\n"
			'vec3 modifyVector	(vec3 vec)	{ return vec; }'"\n";

	void fillData( final Map<String,Object> block ){}
}


class EntityBase extends shade.DataHolder	{
	me.Mesh mesh		= null;
	shade.Effect effect	= null;
	rast.State state	= null;
}


class Material extends shade.DataHolder	{
	final String name;
	final List<String> metas = [];
	String codeVertex='', codeFragment='';
	
	Material( this.name );
}


class Entity implements shade.IDataSource, Hashable	{
	space.Node			node		= null;
	final me.Mesh		mesh		= null;
	final Material		material	= null;
	final phys.Body		body		= null;
	final List<IModifier>	modifiers;
	
	Entity( this.mesh, this.material, this.body ):
		modifiers = new List<IModifier>();
	
	int hashCode() => mesh.nVert ^ material.name.length;
	
	bool isReady()	{
		for (final IModifier m in modifiers)	{
			if (m.getVertexCode() == null)
				return false;
		}
		return mesh != null;
	}
	
	math.Matrix getModelMatrix() => (node==null ?
	    	new math.Matrix.identity() : node.getWorldSpace().getMatrix() );
	
	void fillData( final Map<String,Object> data ){
		data['mx_Model']	= getModelMatrix();
	}
}


class Technique implements shade.IDataSource	{
	final List<String>				_usedMetas;
	final Map<Entity,shade.Effect>	_effectMap;
	view.Camera	_camera = null;
	ren.Target	_target = null;
	rast.State	_state = null;
	String _baseVertex = null, _baseFragment = null;
	final String sMod = 'modify', sMeta = 'meta';

	Technique():
		_usedMetas = new List<String>(),
		_effectMap = new Map<Entity,shade.Effect>();
	
	bool isReady()	=> _target!=null && _state!=null
		&& _baseVertex!=null && _baseFragment!=null;
	
	void fillData(data)	{}
	
	void setTargetState( view.Camera cam, ren.Target tg, rast.State st ){
		_camera = cam; _target = tg; _state = st;
	}
	
	ren.Target getTarget()	=> _target;
	
	int setShaders( final String sVert, final String sFrag ){
		_baseVertex = sVert; _baseFragment = sFrag;
		return _extractMetas();
	}
	
	int _extractMetas()	{
		_usedMetas.clear();
		int metaStart	= _baseFragment.indexOf("//%${sMeta}");
		int metaEnd		= _baseFragment.indexOf("\n",metaStart);
		final List<String> split = _baseFragment.substring(metaStart,metaEnd).split(' ');
		int count = 0;
		for (final String s in split)	{
			if (count++ > 0)
				_usedMetas.add(s);
		}
		return count;
	}
	
	String makeVertex( final String codeMaterial, final Collection<IModifier> mods ){
		final StringBuffer buf = new StringBuffer();
		buf.add("//--- Material ---//\n");
		buf.add( codeMaterial );
		// add modifier bases
		for (final IModifier m in mods)	{
			final String target = "${sMod}${m.getName()}";
			buf.add("//--- Modifier: ${m.getName()} ---//\n");
			buf.add( m.getVertexCode().replaceAll(sMod,target) );
		}
		// add technique start code
		buf.add("//--- Technique: ${toString()} ---//\n");
		final int modStart = _baseVertex.indexOf("//%${sMod}");
		buf.add( _baseVertex.substring(0,modStart) );
		final int modEnd = _baseVertex.indexOf("\n",modStart);
		// extract position and vector names
		final List<String> split = _baseVertex.substring(modStart,modEnd).split(' ');
		// add modifier calls
		for (final IModifier m in mods)	{
			int count = 0;
			for (final String s in split)	{
				String type = count>1 ? 'Vector' : 'Position';
				if (count++ == 0)
					continue;
				buf.add("\t${s} = ${sMod}${m.getName()}${type}(${s});\n");
			}
		}
		// return
		buf.add( _baseVertex.substring(modEnd) );
		return buf.toString();
	}
	
	String makeFragment( final Material mat ){
		final StringBuffer buf = new StringBuffer();
		buf.add("//--- Material: ${mat.name} ---//\n");
		buf.add( mat.codeFragment );
		buf.add("//--- Technique: ${toString()} ---//\n");
		buf.add( _baseFragment );
		return buf.toString();
	}
	
	shade.Effect link( final shade.LinkHelp help, final Entity e ){
		for (String meta in _usedMetas)	{
			if (e.material.metas.indexOf(meta) < 0)
				return null;
		}
		String sv = makeVertex( e.material.codeVertex, e.modifiers );
		String sf = makeFragment( e.material );
		return help.link(sv,sf);
	}

	int draw( final shade.LinkHelp help, final Iterable<Entity> entities, final ren.Process processor ){
		if (!isReady())
			return 0;
		int num = 0;
		for (final Entity e in entities)	{
			if (!e.isReady())
				continue;
			shade.Effect effect = null;
			if (_effectMap.containsKey(e))
				effect = _effectMap[e];
			else
				_effectMap[e] = effect = link(help,e);
			if (effect == null)
				continue;
			final List<shade.IDataSource> sources = [this,_camera,e,e.material];
			sources.addAll( e.modifiers );
			final shade.IDataSource ds = new shade.SourceAdapter(sources);
			processor.draw( _target, e.mesh, effect, _state, ds );
			++num;
		}
		return num;
	}
}
