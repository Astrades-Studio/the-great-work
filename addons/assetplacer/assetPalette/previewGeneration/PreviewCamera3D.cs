// PreviewCamera3D.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable

using Godot;

namespace AssetPlacer;

[Tool]
public partial class PreviewCamera3D : Camera3D
{
	private const int UpdatesBeforeReady = 1;
	private int _updates = 0;
	
	[Signal]
	public  delegate void PreviewReadyEventHandler();
	public override void _Process(double delta)
	{
		if (_updates == UpdatesBeforeReady)
		{
			EmitSignal(SignalName.PreviewReady);
		}

		_updates++;
	}

	public void StartPreview(Transform3D transform)
	{
		Current = true;
		Transform = transform;
		_updates = 0;
	}
}

#endif
