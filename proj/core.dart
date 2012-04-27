#library('kri:core');


class Handle<Type>	{
	final Type _handle;
	final Handle<Type> _fallback;

	static final int stateNone	=0;
	static final int stateAlloc	=1;
	static final int stateFull	=2;
	int _readyState = stateNone;
	
	Handle( this._handle, this._fallback );
	
	bool isAllocated()	=> _readyState >=stateAlloc;
	bool isFull()		=> _readyState >=stateFull;
	
	void setNone()		{ _readyState = stateNone;	}
	void setAllocated()	{ _readyState = stateAlloc;	}
	void setFull()		{ _readyState = stateFull;	}
	
	Type getInitHandle() => _handle;
	
	Type getLiveHandle()	{
		if (isFull())
			return _handle;
		assert (_fallback!=null);
		return _fallback.getLiveHandle();
	}
	
	String toString() => "Handle ready=${_readyState}";
}
