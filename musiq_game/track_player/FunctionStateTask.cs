using Godot;
using System;
using System.Threading.Tasks;

public class GenericFunctionStateTask : Godot.Object
{
	[Signal] public delegate Variant completed();

	public GenericFunctionStateTask() {}

	public static GenericFunctionStateTask Create<T>(Func<Task<T>> task)
	{
		var instance = new GenericFunctionStateTask();
		try
		{
			task().ContinueWith(t =>
			{
				instance.CallDeferred("emit_signal", nameof(completed), t.Result);
			});
		}
		catch (System.Exception e)
		{
			GD.Print("exception: " + e.ToString());
		}
		return instance;
	}
}

public class FunctionStateTask : Godot.Object
{
	[Signal] public delegate void completed();

	public FunctionStateTask() {}

	public FunctionStateTask(Func<Task> task)
	{
		task().ContinueWith(t =>
		{
			CallDeferred("emit_signal", nameof(completed));
		});
	}
}
