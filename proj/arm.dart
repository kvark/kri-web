#library('arm');
#import('space.dart');
#import('shade.dart',	prefix:'shade');
#import('load.dart',	prefix:'load');


class Bone extends Node  {
    final Space bindPose;
    Space transform;

    Bone( final String str, this.bindPose ): super(str) { reset(); }
    void reset()    {
    	space = bindPose;
    	transform = null;
    }
}


class Armature extends Node implements shade.IDataSource	{
    final List<Bone> bones;

    Object askData(final String name)	{
    	final List<String> elems = name.split("\[|\]");
    	if (elems.length != 3 || elems[0]!='bones')
	    	return null;
    	final int id = Math.parseInt(elems[1]);
    	final Space space = bones[id].transform;
    	if (elems[2]=='.pos')	{
    		return space.getMoveScale();
    	}else if (elems[2]=='.rot')	{
    		return space.rotation;
		}else
			return null;
    }
    
    Armature(String name): super(name), bones = new List<Bone>();
    
    void update()	{
    	final Map<Bone,Space> mapPose = new Map<Bone,Space>();
    	final Map<Bone,Space> mapBind = new Map<Bone,Space>();
		for (final Bone b in bones)	{
			if (b.parent == this)	{
				final Space inv = b.bindPose.inverse();
				mapPose[b] = b.space;
				mapBind[b] = inv;
				b.transform = b.space * inv;
			}
			final Space parPose = mapPose[b.parent];
			final Space parBind = mapBind[b.parent];
			assert (parPose!=null && parBind!=null);
			final Space curPose = mapPose[b] = parPose * b.space;
			final Space curBind = mapBind[b] = b.bindPose.inverse() * parBind;
			b.transform = curPose * curBind;
		}
    }
}


// Armature (k3arm) loader
class Manager extends load.Manager<Armature>	{
	Manager( String path ): super.buffer(path);
	
	Armature spawn(Armature fallback) => new Armature('');
	
	void fill( final Armature a, final load.IntReader br ){
		if (br.getString() != 'k3a')	{
			print('Armature signature is bad, skipping');
			return;
		}
		final int num = br.getByte();
		print('Skeleton of ' + num.toString() + ' bones');
		for (int i=0; i<num; ++i)	{
			final String name = br.getString();
			final int parent = br.getByte()-1;
			print('Bone ' +name + ', parent: '+parent.toString());
			final Space space = br.getSpace();
			print(space.toString());
			final Bone b = new Bone(name,space);
			if (parent>=0)
				b.parent = a.bones[parent];
			a.bones.addLast(b);
		}
		assert (br.empty());
	}
}
