#library('arm');
#import('space.dart');
#import('shade.dart',	prefix:'shade');
#import('load.dart',	prefix:'load');


class Bone extends Node implements Hashable  {
    final Space bindPose;
    Space transform;

    static int nextCreateId = 0;
	final int createdId;
	
	int hashCode()	{ return createdId; }

	Bone( final String str, this.bindPose ): super(str), createdId=++nextCreateId { reset(); }
	void reset()    {
		space = bindPose;
		transform = new Space.identity();
    }
}


class Armature extends Node implements shade.IDataSource	{
    final List<Bone> bones;
    static final int maxBones = 90;

    void fillData( final Map<String,Object> data ){
    	for(int i=0; i<maxBones; ++i)	{
	    	final Space space = i<bones.length ? bones[i].transform : new Space.identity();
    		data["bones[${i}].pos"]	= space.getMoveScale();
			data["bones[${i}].rot"]	= space.rotation;
    	}
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
			}else	{
				assert (b.parent != null);
				final Space parPose = mapPose[b.parent];
				final Space parBind = mapBind[b.parent];
				assert (parPose!=null && parBind!=null);
				final Space curPose = mapPose[b] = parPose * b.space;
				final Space curBind = mapBind[b] = b.bindPose.inverse() * parBind;
				b.transform = curPose * curBind;
			}
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
			//print('Bone ' +name + ', parent: '+parent.toString());
			final Space space = br.getSpace();
			print(space.toString());
			final Bone b = new Bone(name,space);
			b.parent = parent>=0 ? a.bones[parent] : a;
			a.bones.addLast(b);
		}
		assert (br.empty());
	}
}
