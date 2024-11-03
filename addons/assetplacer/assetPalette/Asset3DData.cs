// Asset3DData.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using Godot;

namespace AssetPlacer;

public partial class Asset3DData : GodotObject
{
    public Transform3D defaultTransform = Transform3D.Identity;
    public Transform3D lastTransform = Transform3D.Identity;
    public bool hologramInstantiated = false; // true when the asset has been instantiated at least once
    public bool isMesh;
    public string path;
    public PreviewPerspective previewPerspective = PreviewPerspective.Default;
    public Vector3 customPreview = new Vector3(1.0f, Mathf.Pi/2f, 0f); // default: straight front view at 1m distance
    public Vector3 prevCustomPreview = -Vector3.One; // negative: invalid

    // Perspective Setting
    public enum PreviewPerspective
    {
        Default, Front, Back, Top, Bottom, Left, Right, Custom
    }
    public Asset3DData()
    {
    }

    public Asset3DData(string path, PreviewPerspective perspective, Vector3 customPreview, bool isMesh = false)
    {
        this.path = path;
        this.previewPerspective = perspective;
        this.isMesh = isMesh;
        this.customPreview = customPreview;
    }
}
#endif