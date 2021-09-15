using Godot;
using System;
using System.Threading.Tasks;


public class GenericFunctionStateTask : Godot.Object
{
	[Signal] public delegate Variant completed();

	public static GenericFunctionStateTask Create<T>(Func<Task<T>> task)
	{
		var instance = new GenericFunctionStateTask();
		task().ContinueWith(t =>
		{
			instance.CallDeferred("emit_signal", nameof(completed), t.Result);
		});
		return instance;
	}
}

public class FunctionStateTask : Godot.Object
{
	[Signal] public delegate void completed();

	public FunctionStateTask(Func<Task> task)
	{
		task().ContinueWith(t =>
		{
			CallDeferred("emit_signal", nameof(completed));
		});
	}
}