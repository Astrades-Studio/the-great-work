// AssetPersistentData.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable

using Godot;

namespace AssetPlacer;

[Tool]
public partial class AssetPersistentData : Resource
{
	[Export] public string path;
	[Export] public bool isMesh;
	[Export] public Asset3DData.PreviewPerspective previewPerspective;
	[Export] public Vector3 customPreview;

	
	public AssetPersistentData()
	{
	}

	public AssetPersistentData(string path, Asset3DData.PreviewPerspective previewPerspective, bool isMesh, Vector3 customPreview)
	{
		this.path = path;
		this.previewPerspective = previewPerspective;
		this.isMesh = isMesh;
		this.customPreview = customPreview;
	}

	public static Asset3DData GetAsset3DData(AssetPersistentData data)
	{
		return new Asset3DData(data.path, data.previewPerspective, data.customPreview, data.isMesh);
	}
}
#endif
