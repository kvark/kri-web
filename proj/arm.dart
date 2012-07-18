#library('kri:arm');
#import('ani.dart',		prefix:'ani');
#import('draw.dart',	prefix:'draw');
#import('math.dart',	prefix:'math');
#import('load.dart',	prefix:'load');
#import('shade.dart',	prefix:'shade');
#import('space.dart');


class Bone extends Node implements Hashable  {
    final Space bindPose;
    Space transform;

    static int nextCreateId = 0;
	final int createdId;
	
	int hashCode() => createdId;

	Bone( final String str, this.bindPose ):
		super(str), createdId=++nextCreateId { reset(); }
	
	void reset()    {
		space = bindPose;
		transform = new Space.identity();
    }
}


class Armature extends Node implements draw.IModifier	{
    final List<Bone> bones;
    static final int maxBones = 100;
    String _code = null;

	Armature( final String str ): super(str), bones = new List<Bone>();
	
	void loadShaders( final load.Loader loader, final bool doNow, final bool useDualQuat ){
		final String path = useDualQuat ? "mod/arm_dualquat.glslv" : "mod/arm.glslv";
		if (doNow)
			_code = loader.getNowText(path);
		else
			loader.getFutureText(path).then((str) { _code=str; });
	}

	void fillData( final Map<String,Object> data ){
    	for(int i=0; i<maxBones; ++i)	{
	    	final Space space = i>0 && i<=bones.length ?
	    		bones[i-1].transform : new Space.identity();
    		data["bones[${i}].pos"]	= data["bones[${i}].pos[0]"] = space.getMoveScale();
			data["bones[${i}].rot"]	= data["bones[${i}].rot[0]"] = space.rotation;
    	}
	}
	
	String getName()		=> name;
	String getVertexCode()	=> _code;
   
	bool setMoment( String animation, double time ){
		bool rez = super.setMoment( animation, time );
		for (final Bone b in bones)	{
			rez = b.setMoment( animation, time ) || rez;	//Note: keep order!
		}
		return rez;
	}
    
    void update()	{
   		final Map<Bone,Space> mapPose = new Map<Bone,Space>();
   		final Map<Bone,Space> mapBind = new Map<Bone,Space>();
    	final Space invArm = getWorldSpace().inverse();
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
				//final Space curPose = mapPose[b] = invArm * b.getWorldSpace();
				final Space curBind = mapBind[b] = b.bindPose.inverse() * parBind;
				//final Bone bpar = p;
				//final Space curBind = mapBind[b] = bp.transform b.bindPose.inverse() * parBind;
				b.transform = curPose * curBind;
			}
		}
    }
}


class ChanReader<T>	{
	abstract T readPoint( load.IntReader br );
	abstract ani.IChannel readNew( load.IntReader br );
	
	ani.IChannel readInto( load.IntReader br, final ani.Channel<T> chan ){
		final int num = br.getLarge(2);
		if (num == 0)
			return chan;
		chan.extrapolate	= br.getByte()>0;
		chan.bezier			= br.getByte()>0;
		for(int i=0; i<num; ++i)	{
			double t = br.getReal();
			T co = readPoint(br);
			T hl = chan.bezier ? readPoint(br) : null;
			T hr = chan.bezier ? readPoint(br) : null;
			chan.keys.addLast(new ani.Key<T>( t, co, hl, hr ));
		}
		return chan;
	}
}


class ChannelMove extends ani.Channel<math.Vector>   {
    void deploy( final Bone n, final math.Vector v ){
        n.space = new Space( n.bindPose.transform(v), n.space.rotation, n.space.scale );
    }
    math.Vector interpolate( final math.Vector a, final math.Vector b, final double t )    {
        return a.scale(1.0-t) + b.scale(t);
    }
}

class ChannelRotate extends ani.Channel<math.Quaternion> {
    void deploy( final Bone n, final math.Quaternion q ){
        n.space = new Space( n.space.movement, n.bindPose.rotation * q, n.space.scale );
	}
    math.Quaternion interpolate( final math.Quaternion a, final math.Quaternion b, final double t )    {
        return math.Quaternion.slerp(a,b,t);
    }
}

class ChannelScale extends ani.Channel<double>  {
    void deploy( final Bone n, final double s ){
        n.space = new Space( n.space.movement, n.space.rotation, n.bindPose.scale * s );
    }
    double interpolate( final double a, final double b, final double t )    {
        return (1.0-t)*a + t*b;
    }
}

class ChanReadPos extends ChanReader<math.Vector>	{
	math.Vector readPoint(load.IntReader br) => br.getVector3();
	ani.IChannel readNew(load.IntReader br) => readInto( br, new ChannelMove() );
}
class ChanReadRot extends ChanReader<math.Quaternion>	{
	math.Quaternion readPoint(load.IntReader br) => br.getQuaternion();
	ani.IChannel readNew(load.IntReader br) => readInto( br, new ChannelRotate() );
}
class ChanReadScale extends ChanReader<double>	{
	double readPoint(load.IntReader br)	{
		final math.Vector scale = br.getVector3();
		return scale.dot( new math.Vector.mono(1.0/3.0) );
	}
	ani.IChannel readNew(load.IntReader br) => readInto( br, new ChannelScale() );
}


// Armature (k3arm) loader
class Manager extends load.Manager<Armature>	{
	Manager( String path ): super.buffer(path);
	
	Armature spawn(Armature fallback) => new Armature('');
	
	void fill( final Armature a, final load.ChunkReader br ){
		final String signature = br.enter();
		if (signature != 'k3arm')	{
			print("Armature signature is bad: ${signature}");
			return;
		}
		// read bones
		final int numBones = br.getByte();
		print("Skeleton of ${numBones} bones");
		for (int i=0; i<numBones; ++i)	{
			final String name = br.getString();
			final int parent = br.getByte()-1;
			//print("Bone ${name}, parent: ${parent}");
			final Space space = br.getSpace();
			//print(space.toString());
			final Bone b = new Bone(name,space);
			b.parent = parent>=0 ? a.bones[parent] : a;
			a.bones.addLast(b);
		}
		// prepare channels
		final ChanReadPos chanPos = new ChanReadPos();
		final ChanReadRot chanRot = new ChanReadRot();
		final ChanReadScale chanScale = new ChanReadScale();
		final Map<String,Bone> boneMap = new Map<String,Bone>();
		for(final Bone b in a.bones)
			boneMap[b.name] = b;
		// read actions
		for (; br.hasMore(); br.leave())	{
			assert( br.enter() == 'action' );
			final String actName = br.getString();
			final ani.Record rec = a.records[actName] = new ani.Record();
			rec.length = br.getReal();
			print("Anim ${actName} of length ${rec.length}");
			for (; br.hasMore(); br.leave())	{
				assert( br.enter() == 'curve' );
				final String curveName = br.getString();
				final int nSub = br.getByte();
				final List<String> split = curveName.split('"');
				//print("Curve ${curveName}[${nSub}]");
				if (split.length==3)	{
					assert( split[0]=='pose.bones[' );
					final Bone b = boneMap[split[1]];
					ani.Record rb = b.records[actName];
					if (rb==null)	{
						rb = b.records[actName] = new ani.Record();
						rb.length = rec.length;
					}
					if (split[2]=='].location')	{
						assert( nSub == 3 );
						rb.channels.add( chanPos.readNew(br) );
						continue;
					}else if (split[2]=='].rotation_quaternion')	{
						assert( nSub == 4 );
						rb.channels.add( chanRot.readNew(br) );
						continue;
					}else if (split[2]=='].scale')	{
						assert( nSub == 3 );	//averaging
						rb.channels.add( chanScale.readNew(br) );
						continue;
					}else
						print("Unkown bone curve: ${split[2]}");
				}
				print("Unknown curve channel: ${curveName}");
			}
		}
		br.finish();
	}
}
