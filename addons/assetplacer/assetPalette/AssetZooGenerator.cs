// AssetZooGenerator.cs
// Copyright (c) 2024 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using System.Linq;
using Godot;

namespace AssetPlacer;

[Tool]
public partial class AssetZooGenerator : Node
{
	private SubViewport _tempVp;
	private PackedScene _scene;
	private Node3D _rootNode;
	private AssetLibraryData _library;
	private EditorInterface _editorInterface;
	private const string TempZooFolderPath = $"{AssetPlacerPlugin.PluginFolderPath}/zoo";
	private const string TempZooPath = $"{TempZooFolderPath}/temp_asset_zoo.tscn";

	private bool _used = false;
	
	[Signal]
	public delegate void FinishedEventHandler();
	public void Generate(AssetPalette palette, string libraryName, AssetLibraryData library,  EditorInterface editorInterface)
	{
		if (_used)
		{
			GD.PushWarning("AssetZooGenerator should not be reused");
			return;
		}
		_used = true;
		
		_editorInterface = editorInterface;
		_library = library;
        // Open new scene
		_scene = null;
		AssetPlacerPersistence.CheckFolderExists(TempZooFolderPath);
		
		GD.PrintRich($"{nameof(AssetPlacerPlugin)}: [b]Generating AssetZoo for '{libraryName}' ...[/b]");
		GD.PrintRich($"{nameof(AssetPlacerPlugin)}: [b]The zoo will be saved at a temporary location. If you want it to be persisted, make sure to save the scene at a different location in your project. {(ResourceLoader.Exists(TempZooPath) ? "A previously generated zoo was was overwritten." : "")}[/b]");
		_scene = new PackedScene();
		_rootNode = new Node3D();
		_rootNode.Name = $"{libraryName}_zoo";
		
		// temporarily add the root node, so we can evaluate AABBs
		_tempVp = new SubViewport();
		AddChild(_tempVp); 
		
		
		// instantiate all assets
		foreach (var asset in library.assetData)
		{
			var node = palette.InstantiateAsset(asset, library);
			if (node != null)
			{
				_rootNode.AddChild(node);
				node.Owner = _rootNode;
			}
		}

		_rootNode.Ready += FinishGeneration;
		_tempVp.CallDeferred("add_child", _rootNode);
    }

    private void FinishGeneration()
    {
	    SpatialUtils.OrganizeSpatialChildren(_rootNode);

	    // remove tempVp
		_tempVp.RemoveChild(_rootNode);
		_tempVp.QueueFree();

		// pack, store and open scene
		_scene.Pack(_rootNode);
		ResourceSaver.Save(_scene, TempZooPath);
		if (_editorInterface.GetOpenScenes().ToList().Contains(TempZooPath))
		{
			_editorInterface.ReloadSceneFromPath(TempZooPath);
		}
		
		_editorInterface.OpenSceneFromPath(TempZooPath);
		_editorInterface.CallDeferred("open_scene_from_path", TempZooPath); // for some reason we need this to make the editor switch scenes if the zoo scene is open, but selected scene is leftmost tab

		EmitSignal(SignalName.Finished);
    }
}
#endif