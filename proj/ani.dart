#library('kri:ani');


class Key<T>	{
	final double t;
	final T co,hl,hr;
	Key( this.t, this.co, this.hl, this.hr );
}


interface IPlayer	{
	bool setMoment( String animation, double time );
}

interface IChannel	{
	void update( final IPlayer pl, double time );
}


class Channel<T> implements IChannel	{
	final List<Key<T>> keys;
	bool bezier	= true;
	bool extrapolate = true;

	abstract void deploy( final IPlayer pl, final T value );
	abstract T interpolate( final T a, final T b, final double ratio );

	Channel():
		keys = new List<Key<T>>();
	
	void update( final IPlayer pl, double time ){
		deploy( pl, sample(time) );
	}
	
	T sample( final double time ){
		int i = keys.length;
		while (i>0 && keys[i-1].t > time)
			--i;
		if (i==0 || i==keys.length)	{
			final Key<T> a = keys[i>0 ? i-1 : 0];
			if (extrapolate && a.hl!=null && a.hl!=null)	{
				return interpolate( a.co,
					i>0 ? a.hr : a.hl,
					i>0 ? (time-a.t) : (a.t-time) );
			}else
				return a.co;
		}
		final Key<T> a = keys[i-1], b = keys[i];
		assert (a.t != b.t);
		final double t = (time - a.t) / (b.t - a.t);
		if (bezier && a.hr!=null && b.hl!=null)	{
			final T va = interpolate( a.co, a.hr, t );
			final T vb = interpolate( b.hl, b.co, t );
			return interpolate( va, vb, t );
		}else
			return interpolate( a.co, b.co, t );
	}
}


class Record	{
	double length = 0.0;
	final List<IChannel> channels;

	Record():
		channels = new List<IChannel>();
}


class Player implements IPlayer	{
	final Map<String,Record> records;
	Player(): records = new Map<String,Record>();
	
	bool setMoment( String animation, double time ){
		final Record rec = records[animation];
		if (rec == null)
			return false;
		assert( time>=0.0 && time<=rec.length );
		for (IChannel chan in rec.channels)	{
			chan.update( this, time );
		}
		return true;
	}
}
