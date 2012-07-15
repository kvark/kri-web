#library('kri:draw');
#import('ani.dart',		prefix:'ani');
#import('arm.dart',		prefix:'arm');
#import('mesh.dart',	prefix:'me');
#import('phys.dart',	prefix:'phys');
#import('ren.dart',		prefix:'ren');
#import('shade.dart',	prefix:'shade');


abstract class Modifier extends ani.Player implements shade.IDataSource	{
	final String name;
	String codeVertex	= '';
	
	Modifier( this.name );
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
	final phys.Body		body		= null;
	final List<Modifier>	modifiers;
	
	Entity(): modifiers = new List<Modifier>();
}


class Technique implements shade.IDataSource	{
	final Collection<String>		_usedMetas;
	final Map<Entity,shade.Effect>	_effectMap;
	String baseVertex = '', baseFragment = '';
	final String sMod = 'modify'; 

	Technique( this._usedMetas ):
		_effectMap = new Map<Entity,shade.Effect>();
	
	String makeVertex( final ICollection<Modifier> mods ){
		final StringBuffer buf = new StringBuffer();
		// add modifier bases
		for (Modifier m in mods)	{
			final String target = "${sMod}${m.name}";
			buf.add( m.codeVertex.replace(sMod,target) );
		}
		// add technique start code
		final int modStart = baseVertex.indexOf("%${sMod}");
		buf.add( baseVertex.substring(0,modStart) );
		final int modEnd = baseVertex.indexOf("\n",modStart);
		// extract position and vector names
		// %modify posName v1name v2name ...
		int begin = baseVertex.indexOf(' ',modStart)+1;
		int end = baseVertex.indexOf(' ',begin);
		final String posName = baseVertex.substring(begin,end);
		final List<String> vecNames = new List<String>();
		while(end>=0 && end<modEnd)	{
			begin = end+1;
			end = baseVertex.indexOf(' ',begin);
			vecNames += baseVertex.substring( begin,
				end<0 || end>modEnd ? modEnd : end );
		}
		// add modifier calls
		for (final Modifier m in mods)	{
			buf.add("\t${posName} = ${sMod}${m.name}Position(${posName});\n");
			for (final String vec in vecNames)
				buf.add("\t${vec} = ${sMod}${m.name}Vector(${vec});\n");
		}
		// return
		buf.add( baseVertex.substring(modEnd) );
		return buf.toString();
	}
	
	String makeFragment( final Material mat ){
		return '';
	}
	
	shade.Effect link( final shade.Helper help, final Entity e ){
		String sv = makeVertex( e.modifiers );
		String sf = makeFragment( e.material );
		return help.link(sv,sf);
	}

	int draw( final shade.Helper help, final Iterable<Entity> entities, final ren.Process processor ){
		final ren.Target target = null;
		final ren.State state = null;
		int num = 0;
		for (final Entity e in entities)	{
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
