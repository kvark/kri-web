#library('kri:draw');
#import('ani.dart',		prefix:'ani');
#import('mesh.dart',	prefix:'me');
#import('phys.dart',	prefix:'phys');
#import('rast.dart',	prefix:'rast');
#import('ren.dart',		prefix:'ren');
#import('shade.dart',	prefix:'shade');


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
	String codeVertex='', codeFragment='';
	
	Material( this.name ):
		data = new Map<String,Object>(),
		metas = new List<String>();
	
	void fillData(final Map<String,Object> block)	{
		for (String key in block.getKeys())
			data[key] = block[key];
	}
}


class Entity	{
	final me.Mesh		mesh		= null;
	final Material		material	= null;
	final phys.Body		body		= null;
	final List<IModifier>	modifiers;
	
	Entity(): modifiers = new List<IModifier>();
	
	bool isReady()	{
		for (final IModifier m in modifiers)	{
			if (m.getVertexCode() == null)
				return false;
		}
		return true;
	}
}


class Technique implements shade.IDataSource	{
	final List<String>				_usedMetas;
	final Map<Entity,shade.Effect>	_effectMap;
	String baseVertex = '', baseFragment = '';
	final String sMod = 'modify', sMeta = 'meta';

	Technique():
		_usedMetas = new List<String>(),
		_effectMap = new Map<Entity,shade.Effect>();
	
	int extractMetas()	{
		_usedMetas.clear();
		int metaStart	= baseFragment.indexOf("//%${sMeta}");
		int metaEnd		= baseFragment.indexOf("\n",metaStart);
		final List<String> split = baseFragment.substring(metaStart,metaEnd).split(' ');
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
		final int modStart = baseVertex.indexOf("//%${sMod}");
		buf.add( baseVertex.substring(0,modStart) );
		final int modEnd = baseVertex.indexOf("\n",modStart);
		// extract position and vector names
		final List<String> split = baseVertex.substring(modStart,modEnd).split(' ');
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
		buf.add( baseVertex.substring(modEnd) );
		return buf.toString();
	}
	
	String makeFragment( final Material mat ){
		final StringBuffer buf = new StringBuffer();
		buf.add("//--- Material: ${mat.name} ---//\n");
		buf.add( mat.codeFragment );
		buf.add("//--- Technique: ${toString()} ---//\n");
		buf.add( baseFragment );
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
		final ren.Target target = null;
		final rast.State state = null;
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
			final shade.IDataSource ds = new shade.SourceAdapter( [this,e.material] + e.modifiers );
			processor.draw( target, e.mesh, effect, state, ds );
			++num;
		}
		return num;
	}
}
