// AssetPalette.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using Godot;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Godot.Collections;

namespace AssetPlacer;

using Array = System.Array;


[Tool]
public partial class AssetPalette : Node
{
	private const string OpenedLibrariesSaveKey = "opened_libraries";
	private const string LastSelectedLibrarySaveKey = "selected_library";
	
	private EditorInterface _editorInterface;
	private AssetPaletteUi _assetPaletteUi;
	public Node3D Hologram { get; private set; }
	public Node3D LastPlacedAsset { get; private set; }
	private Asset3DData _selectedAsset;
	private string _lastSelectedAssetPath;
	public string SelectedAssetName { get; private set; }
	private Godot.Collections.Dictionary<string, AssetLibraryData> _libraryDataDict = new();
	private string _currentLibrary = null;
	private const string NewLibraryName = "Unnamed Library";
	private AssetPreviewGenerator _previewGenerator;
	private bool _isShowingDynamicPreview;
	private DynamicPreviewController _dynamicPreviewController;
	private AssetPreviewGenerator PreviewGenerator
	{
		get
		{
			if (_previewGenerator == null)
			{
				_previewRenderingViewports = new();
				_previewGenerator = new AssetPreviewGenerator();
				const int previewVpCount = 3;
				for (int i = 0; i <= previewVpCount; i++)
				{
					var previewVpScene = ResourceLoader.Load<PackedScene>("res://addons/assetplacer/assetPalette/previewGeneration/PreviewRenderingViewport.tscn");
					var previewRenderingViewport = previewVpScene.Instantiate<PreviewRenderingViewport>();
					_previewGenerator.AddChild(previewRenderingViewport);
					if (i == 0)
					{
						_dynamicPreviewRenderingViewport = previewRenderingViewport;
					}
					else
					{
						_previewRenderingViewports.Add(previewRenderingViewport);
					}
				}
				_previewGenerator.Init(_previewRenderingViewports);
				AddChild(_previewGenerator);
			}
			return _previewGenerator;
		}
	}

	private Array<PreviewRenderingViewport> _previewRenderingViewports = new();
	private PreviewRenderingViewport _dynamicPreviewRenderingViewport;
	private TextureRect _viewportTextureRect;

	private AssetLibraryData CurrentLibraryData => _libraryDataDict[_currentLibrary];
	private AssetLibraryData CurrentLibraryDataOrNull => _libraryDataDict.ContainsKey(_currentLibrary) ? _libraryDataDict[_currentLibrary] : null;
	public void Init(EditorInterface editorInterface)
	{
		var _ = PreviewGenerator; // Force Initialization

		_editorInterface = editorInterface;
		_dynamicPreviewController = new DynamicPreviewController();
	}

	public void PostInit()
	{
		var openedLibraries = AssetPlacerPersistence.LoadGlobalData(OpenedLibrariesSaveKey,Array.Empty<string>(), Variant.Type.PackedStringArray);
		var lastSelectedLibrary =
			AssetPlacerPersistence.LoadGlobalData(LastSelectedLibrarySaveKey, "", Variant.Type.String);
		InitLibraries(openedLibraries.AsStringArray(), lastSelectedLibrary.AsString());
		OnSelectionChanged();
	}
	
	public void Cleanup()
	{
		foreach (var vp in _previewRenderingViewports)
		{
			vp.QueueFree();
		}

		_assetPaletteUi.Cleanup();
		_dynamicPreviewRenderingViewport.QueueFree();
	}

	public const string AssetLibrarySaveFolder = ".assetPlacerLibraries";
	public void SetUi(AssetPaletteUi assetPaletteUi)
	{
		_assetPaletteUi = assetPaletteUi;
		_assetPaletteUi.AssetsAdded += OnAddNewAsset;
		_assetPaletteUi.AssetSelected += OnSelectAsset;
		_assetPaletteUi.AssetsRemoved += OnRemoveAsset;
		_assetPaletteUi.AssetTransformReset += OnResetAssetTransform;
		_assetPaletteUi.AssetsOpened += OnOpenAsset;
		_assetPaletteUi.AssetShownInFileSystem += OnShowAssetInFileSystem;
		_assetPaletteUi.AssetLibrarySelected += path => OnLibraryLoad(path, true);
		_assetPaletteUi.AssetTabSelected += OnAssetLibrarySelect;
		_assetPaletteUi.TabsRearranged += StoreOpenedLibraries;
		_assetPaletteUi.NewTabPressed += () => OnNewAssetLibrary();
		_assetPaletteUi.SaveButtonPressed += OnSaveCurrentAssetLibrary;
		_assetPaletteUi.AssetLibrarySaved += SaveLibraryAt;
		_assetPaletteUi.AssetLibraryRemoved += OnRemoveAssetLibrary;
		_assetPaletteUi.ReloadLibraryPreviews += OnReloadLibraryPreviews;
		_assetPaletteUi.DefaultLibraryPreviews += OnDefaultLibraryPreviews;
		_assetPaletteUi.GenerateZoo += GenerateZoo;
		_assetPaletteUi.ReloadAssetPreview += ReloadAssetPreview;
		_assetPaletteUi.AssetPreviewPerspectiveChanged += OnAssetPreviewPerspectiveChanged;
		_assetPaletteUi.MatchSelectedPressed += OnMatchSelectedPressed;

		_assetPaletteUi.AssetLibraryShownInFileManager += OnShowAssetLibraryInFileManager;
		_assetPaletteUi.LibraryPreviewPerspectiveChanged += OnLibraryPreviewPerspectiveChanged;
		_assetPaletteUi.AssetButtonRightClicked += OnAssetButtonRightClicked;
		_assetPaletteUi.TabRightClicked += OnAssetTabRightClicked;
		_assetPaletteUi.DynamicPreviewShown += OnShowDynamicPreview;
		_assetPaletteUi.DynamicPreviewHidden += OnHideDynamicPreview;
		_assetPaletteUi.SetAssetLibrarySaveDisabled(true);
		_assetPaletteUi.InitDynamicPreview(_dynamicPreviewRenderingViewport.GetTexture(), _dynamicPreviewController);
		_dynamicPreviewRenderingViewport.SetupFinished += OnDynamicPreviewSetup;
	}
	
	public void OnSelectionChanged()
	{
		_assetPaletteUi.MatchSelectedButtonDisabled(!CanMatchSelection());
	}

	private bool CanMatchSelection()
	{
		var nodes = _editorInterface.GetSelection().GetSelectedNodes();
		return nodes.Count == 1 && nodes[0].Owner == _editorInterface.GetEditedSceneRoot();
	}

	public void OnMatchSelectedPressed()
	{
		Debug.Assert(CanMatchSelection());
		var selected = _editorInterface.GetSelection().GetSelectedNodes()[0];
		_editorInterface.GetSelection().GetSelectedNodes();
		if (!string.IsNullOrEmpty(selected.SceneFilePath))
		{
			if (_currentLibrary != null && CurrentLibraryData.ContainsAsset(selected.SceneFilePath))
			{
				_assetPaletteUi.SelectAssetButtonFromPath(selected.SceneFilePath);
			}
			else
			{
				OnAddNewAsset(new []{selected.SceneFilePath});
				_assetPaletteUi.SelectAssetButtonFromPath(selected.SceneFilePath);
			}
		}
		else if (selected is MeshInstance3D meshInstance)
		{
			var resourcePath = meshInstance.Mesh.ResourcePath;
			if (resourcePath.StartsWith("res://") &&
			    (new[] { ".res", ".tres", ".obj" }).Any(s => resourcePath.EndsWith(s)))
			{
				if (_currentLibrary != null && CurrentLibraryData.ContainsAsset(resourcePath))
				{
					_assetPaletteUi.SelectAssetButtonFromPath(resourcePath);
				}
				else
				{
					OnAddNewAsset(new []{resourcePath});
					_assetPaletteUi.SelectAssetButtonFromPath(resourcePath);
				}
			}
			else
			{
				GD.PrintErr($"To add {selected.Name} as an asset, either save as a scene, or save its Mesh as a Resource");
			}
		}
		else
		{
			GD.PrintErr($"To add {selected.Name} as an asset, save it as a scene first (needs to be an instanced scene).");
		}
	}

	private void OnAssetButtonRightClicked(string assetPath, Vector2 pos)
	{
		Debug.Assert(CurrentLibraryData.assetData.Any(a=>a.path == assetPath), $"AssetPath {assetPath} does not exist in current library");
		int prevPerspective = (int) CurrentLibraryData.assetData.First(a => a.path == assetPath).previewPerspective;
		_assetPaletteUi.DisplayAssetRightClickPopup(assetPath, prevPerspective, pos);
	}
	private void OnAssetTabRightClicked(string library, Vector2 pos)
	{
		Debug.Assert(_libraryDataDict.ContainsKey(library), $"Data of library {library} not found");
		int prevPerspective = (int) _libraryDataDict[library].previewPerspective;
		_assetPaletteUi.DisplayTabRightClickPopup(library, prevPerspective, pos);
	}

	private void OnShowDynamicPreview(string assetPath)
	{
		var asset = CurrentLibraryData.assetData.First(a => a.path == assetPath);
		var resource = ResourceLoader.Exists(asset.path) ? ResourceLoader.Load(asset.path) : null;
			
		_dynamicPreviewRenderingViewport.SetPreviewNode(resource, GetPreviewPerspective(asset), asset.customPreview, true);
		const int dynamicPreviewSize = 512;
		_dynamicPreviewRenderingViewport.Size = Vector2I.One*dynamicPreviewSize;
		_dynamicPreviewController.Deactivate(); // sanity
	}

	private void OnHideDynamicPreview(string assetPath, bool updateAssetThumbnail)
	{
		var asset = CurrentLibraryDataOrNull?.assetData.FirstOrDefault(a => a.path == assetPath);
		if (_dynamicPreviewController.HasChanged && updateAssetThumbnail && asset != null)
		{
			SaveDynamicPreview(asset);
		}
		_dynamicPreviewRenderingViewport.FreePreviewNode();
		_isShowingDynamicPreview = false;
		_dynamicPreviewController.Deactivate();
	}

	private void OnDynamicPreviewSetup(Vector3 sphericalCameraCoordinates)
	{
		_isShowingDynamicPreview = true;
		_dynamicPreviewController.Activate(sphericalCameraCoordinates, _editorInterface.GetEditorSettings());
	}

	private void SaveDynamicPreview(Asset3DData asset)
	{
		// store preview parameters in asset
		CurrentLibraryData.dirty = true;
		UpdateSaveDisabled();
		asset.previewPerspective = Asset3DData.PreviewPerspective.Custom;
		asset.customPreview = _dynamicPreviewController.SphericalCameraCoordinates;
		
		// make a preview viewport reload this asset's preview with these parameters
		ReloadAssetPreview(asset.path, asset.prevCustomPreview);
		asset.prevCustomPreview = _dynamicPreviewController.SphericalCameraCoordinates;
	}
	
	private void OnDefaultLibraryPreviews(string library)
	{
		Debug.Assert(_libraryDataDict.ContainsKey(library), $"Data of library {library} not found");
		var lib = _libraryDataDict[library];
		foreach (var asset3DData in lib.assetData)
		{
			asset3DData.previewPerspective = Asset3DData.PreviewPerspective.Default;
			
		}
		OnReloadLibraryPreviews(library);
		lib.dirty = true;
		UpdateSaveDisabled();
	}

	private void GenerateZoo(string library)
	{
		Debug.Assert(_libraryDataDict.ContainsKey(library), $"Data of library {library} not found");
		
		var libraryData = _libraryDataDict[library];

		var generator = new AssetZooGenerator();
		AddChild(generator);

		generator.Generate(this, library, libraryData, _editorInterface);
		generator.Finished += () => generator.QueueFree();
	}
	
	private void OnReloadLibraryPreviews(string library)
	{
		Debug.Assert(_libraryDataDict.ContainsKey(library), $"Data of library {library} not found");
		_assetPaletteUi.SelectAssetTab(library);
		GeneratePreviews(_libraryDataDict[library].assetData, true);
	}

	private void ReloadAssetPreview(string path)
	{
		ReloadAssetPreview(path, -Vector3.One);
	}
	
	private void ReloadAssetPreview(string path, Vector3 prevCustomPreview)
	{
		Debug.Assert(CurrentLibraryData.GetAssetPaths().Contains(path), $"Asset {path} is not part of current library");
		var asset = CurrentLibraryData.assetData.Where(a => a.path == path);
		GeneratePreviews(asset, true, prevCustomPreview);
	}

	private void OnAssetPreviewPerspectiveChanged(string path, Asset3DData.PreviewPerspective perspective)
	{
		Debug.Assert(CurrentLibraryData.GetAssetPaths().Contains(path), $"Asset {path} is not part of current library");
		var asset = CurrentLibraryData.assetData.Where(a => a.path == path).ToList();
		CurrentLibraryData.dirty = true;
		UpdateSaveDisabled();
		asset.ForEach(a=>a.previewPerspective = perspective); // change perspective
		GeneratePreviews(asset, true);
	}
	private void OnLibraryPreviewPerspectiveChanged(string library, Asset3DData.PreviewPerspective perspective)
	{
		Debug.Assert(_libraryDataDict.ContainsKey(library), $"Data of library {library} not found");
		_libraryDataDict[library].previewPerspective = perspective;
		_libraryDataDict[library].dirty = true;
		UpdateSaveDisabled();
		GeneratePreviews(_libraryDataDict[library].assetData, true);
	}

	private void OnRemoveAssetLibrary(string libraryName)
	{
		if (_libraryDataDict.ContainsKey(libraryName))
		{
			_libraryDataDict.Remove(libraryName);
			if(libraryName == _currentLibrary) _currentLibrary = null;
			
			StoreOpenedLibraries();
			_assetPaletteUi.CallDeferred(nameof(_assetPaletteUi.RemoveAssetLibrary), libraryName); // deferred to avoid out of bounds error
		}
	}

	private void StoreOpenedLibraries()
	{
		// Store libraries in the order they are opened in the tab bar, excluding any that have not been saved yet
		AssetPlacerPersistence.StoreGlobalData(OpenedLibrariesSaveKey, 
			_libraryDataDict.Values.Select(l=>l.savePath).Where(p=>!string.IsNullOrEmpty(p)).OrderBy((p)=>_assetPaletteUi.GetTabIdx(GetLibraryNameFromPath(p))).ToArray());
	}

	public override void _Process(double delta)
	{
		if (!Engine.IsEditorHint()) return;
		PreviewGenerator.Process();
		if (_isShowingDynamicPreview)
		{
			_dynamicPreviewController.Process(delta);
			_dynamicPreviewRenderingViewport.UpdateCameraPosition(_dynamicPreviewController.SphericalCameraCoordinates);
		}
	}

	private void OnShowAssetLibraryInFileManager(string libraryName)
	{
		if (!string.IsNullOrEmpty(_libraryDataDict[libraryName].savePath))
		{
			OS.ShellOpen($"{ProjectSettings.GlobalizePath(GetFolderPathFromFilePath(_libraryDataDict[libraryName].savePath))}");
		}
		else GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Can't open library in file manager. Library is not saved.");
	}

	public static string GetAssetLibraryDirPath(FileDialog.AccessEnum access)
	{
		return $"{(access == FileDialog.AccessEnum.Userdata ? "user://" : "res://")}{AssetLibrarySaveFolder}";
	}

	private void OnSaveCurrentAssetLibrary()
	{
		if(_currentLibrary != null && !string.IsNullOrEmpty(CurrentLibraryData.savePath)) {
			SaveLibraryAt(_currentLibrary, CurrentLibraryData.savePath, false);
		}
		else
		{
			_assetPaletteUi.ShowSaveDialog(_currentLibrary, true);
		}
	}

	private string OnNewAssetLibrary(string name = NewLibraryName, bool selectLibrary = true)
	{
		var libraryName = GetAvailableLibraryName(name);
		_libraryDataDict.Add(libraryName, new AssetLibraryData());
		
		if(selectLibrary) _assetPaletteUi.AddAndSelectAssetTab(libraryName);
		else _assetPaletteUi.AddAssetTab(libraryName);
		
		return libraryName;
	}

	private void InitLibraries(string[] openedLibraries, string selectLibraryPath)
	{
		if (openedLibraries.Length == 0) return;
		foreach (var libraryPath in openedLibraries.Where(s=>!string.IsNullOrEmpty(s)))
		{
			OnLibraryLoad(libraryPath, false);
		}

		var library = GetLibraryNameFromPath(selectLibraryPath) ?? GetLibraryNameFromPath(openedLibraries[0]);
		_assetPaletteUi.SelectAssetTab(library);
	}

	// Returns the name with which the library can be selected in the UI (tab title).
	// Not to be confused with the library file name.
	private string GetLibraryNameFromPath(string selectLibraryPath)
	{
		return _libraryDataDict.Keys.FirstOrDefault(a => _libraryDataDict[a].savePath == selectLibraryPath);
	}

	private void OnAssetLibrarySelect(string tabTitle, int scrollPosition)
	{
		if (tabTitle == _currentLibrary) return;
		_currentLibrary = tabTitle;
		if (_currentLibrary != null)
		{
			var perspective = _libraryDataDict.ContainsKey(_currentLibrary)
				? _libraryDataDict[_currentLibrary].previewPerspective
				: Asset3DData.PreviewPerspective.Default;
			OnLibraryChange(scrollPosition);
		}
		UpdateSaveDisabled();
	}

	private void OnLibraryLoad(string path, bool selectLibrary)
	{
		var assetLibraryResource = ResourceLoader.Load<Resource>(path, null, ResourceLoader.CacheMode.Ignore);
		if (assetLibraryResource is AssetLibrary assetLibrary) // path must be up-to-date
		{
			var existingLibrary = GetLibraryNameFromPath(path);
			if (existingLibrary == null)
			{
				string libraryName = OnNewAssetLibrary(GetFileNameFromFilePath(path), selectLibrary);
				
				// load library settings
				var libraryData = _libraryDataDict[libraryName];
				libraryData.previewPerspective = assetLibrary.previewPerspective;
				var asset3DData = assetLibrary.assetData.Select(AssetPersistentData.GetAsset3DData);
				asset3DData.ToList().ForEach(asset=>libraryData.assetData.Add(asset));
				if (selectLibrary)
				{
					_currentLibrary = libraryName;
					OnLibraryChange();
				}
				libraryData.dirty = false;
				libraryData.savePath = path;
				UpdateSaveDisabled();
				StoreOpenedLibraries();
			}
			else
			{
				GD.Print($"{nameof(AssetPlacerPlugin)}: {path} is already loaded");
				if(selectLibrary) _assetPaletteUi.SelectAssetTab(existingLibrary);
			}
		}
		else
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Resource found at {path} is not a scene library");
		}
		
	}

	private void SaveLibraryAt(string libraryKey, string path, bool changeName)
	{
		if (!_libraryDataDict.ContainsKey(libraryKey))
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Error saving asset library '{libraryKey}': Library not found in loaded libraries.");
			return;
		}

		if (_libraryDataDict.Keys.Any(lib=>lib != libraryKey && _libraryDataDict[lib].savePath == path)) // different library with same file location loaded
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Error saving asset library at {path}: A library saved to {path} is currently open.");
			return;
		}

		// create a SceneLibrary resource and copy the assetPaths into it
		var assetLibraryData = _libraryDataDict[libraryKey];
		var assetLibrary = AssetLibrary.BuildAssetLibary(assetLibraryData);
		var folder = GetFolderPathFromFilePath(path);
		if (!string.IsNullOrEmpty(folder) && !DirAccess.DirExistsAbsolute(folder))
		{
			DirAccess.MakeDirRecursiveAbsolute(folder);
		}
		
		var error = ResourceSaver.Save(assetLibrary, path);
		if (error == Error.Ok)
		{
			GD.PrintRich($"{nameof(AssetPlacerPlugin)}: [b]Asset selection saved to: {path}[/b]");
			_libraryDataDict[libraryKey].dirty = false;
			_libraryDataDict[libraryKey].savePath = path;
			UpdateSaveDisabled();
			if(changeName) ChangeLibraryName(libraryKey, GetFileNameFromFilePath(path));
			StoreOpenedLibraries();
		}
		else
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Error saving asset library: {error}");
		}
	}

	private void UpdateSaveDisabled()
	{
		if (!_libraryDataDict.ContainsKey(_currentLibrary))
		{
			_assetPaletteUi.SetAssetLibrarySaveDisabled(true);
		}
		else
		{
			var hasChanges = CurrentLibraryData.savePath == null || CurrentLibraryData.dirty;
			_assetPaletteUi.SetAssetLibrarySaveDisabled(!hasChanges);
		}
	}
	
	private void ChangeLibraryName(string oldName, string newName)
	{
		if (oldName == newName) return;
		var data = _libraryDataDict[oldName];
		_libraryDataDict.Remove(oldName);
		var availableNewName = GetAvailableLibraryName(newName);
		_assetPaletteUi.ChangeTabTitle(oldName, availableNewName);
		_libraryDataDict.Add(availableNewName, data);
		
		if(oldName == _currentLibrary) _currentLibrary = availableNewName;
	}

	private void OnShowAssetInFileSystem(string assetPath)
	{
		_editorInterface.GetFileSystemDock().NavigateToPath(assetPath);
	}

	private void OnOpenAsset(string assetPath)
	{
		_editorInterface.OpenSceneFromPath(assetPath);
	}

	private void OnSelectAsset(string path, string name)
	{
		if (path == _selectedAsset?.path) return;
		var pathNull = string.IsNullOrEmpty(path);
		_selectedAsset = pathNull ? null : CurrentLibraryData.GetAsset(path);
		SelectedAssetName = name;
		ClearHologram();
		
		if (!pathNull)
		{
			Hologram = InstantiateAsset(_selectedAsset, CurrentLibraryData);
			if (Hologram == null)
			{
				DeselectAsset();
			}
			else
			{
				_lastSelectedAssetPath = _selectedAsset.path;
			}
		}
	}

	private void OnResetAssetTransform(string path)
	{
		var data = _libraryDataDict[_currentLibrary].GetAsset(path);
		data.lastTransform = data.defaultTransform;
		UpdateResetTransformButton(data);
	}
	
	public const string resFileEnding = ".res";
	public const string tresFileEnding = ".tres";

	private bool IsValidFile(string filePath)
	{
		const string sceneFileEnding = ".tscn";
		const string compressedSceneFileEnding = ".scn";
		const string objFileEnding = ".obj";
		const string gltfFileEnding = ".gltf";
		const string glbFileEnding = ".glb";
		const string fbxFileEnding = ".fbx";
		const string colladaFileEnding = ".dae";
		const string blendFileEnding = ".blend";
		const string meshFileEnding = ".mesh";


		string[] validEndings =
		{
			sceneFileEnding, compressedSceneFileEnding, objFileEnding, gltfFileEnding, glbFileEnding, fbxFileEnding, colladaFileEnding, blendFileEnding, resFileEnding, tresFileEnding, meshFileEnding
		};

		// Check File Ending, and if file exists and is a Scene or Mesh
		if (validEndings.Any(filePath.EndsWith))
		{
			if(ResourceLoader.Exists(filePath)) return true;
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: {filePath} not found. It might have been moved or deleted");
		}
		else
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: {filePath} has an unsupported file ending. Are you sure it is a 3D file?");
		}
		return false;
	}

	private void OnAddNewAsset(string[] assetPaths)
	{
		List<Asset3DData> assets = new();
		foreach (var assetPath in assetPaths)
		{
			assets.Add(new Asset3DData(assetPath, Asset3DData.PreviewPerspective.Default, -Vector3.One));
		}
		OnAddAssetData(assets);
	}
	
	private void OnAddAssetData(IEnumerable<Asset3DData> assets)
	{
		List<Asset3DData> validAssets = new();
		foreach (var asset in assets)
		{
			// if the _currentLibrary is "[Empty]", we create a new library 
			if (_currentLibrary == null || !_libraryDataDict.ContainsKey(_currentLibrary)) OnNewAssetLibrary();
			
			Debug.Assert(_currentLibrary != null, nameof(_currentLibrary) + " != null");
			if (CurrentLibraryData.ContainsAsset(asset.path)) continue;
			if (!IsValidFile(asset.path)) continue;
			
			var res = ResourceLoader.Load(asset.path); // Expensive operation
			asset.isMesh = res is Mesh;
			if (res is Mesh or PackedScene)
			{
				CurrentLibraryData.assetData.Add(asset);
				CurrentLibraryData.dirty = true;
				validAssets.Add(asset);
				UpdateSaveDisabled();
			}
			else
			{
				GD.PrintErr($"{nameof(AssetPlacerPlugin)}: {asset.path} is not a scene or mesh. Other Resources are not supported.");
			}
		}
		if (_currentLibrary == null) return;
		_assetPaletteUi.AddAssets(validAssets);
		GeneratePreviews(validAssets, false);
	}

	private void OnRemoveAsset(string[] paths)
	{
		foreach (var path in paths)
		{
			if (CurrentLibraryData.ContainsAsset(path))
			{
				CurrentLibraryData.RemoveAsset(path);
				CurrentLibraryData.dirty = true;
				UpdateSaveDisabled();
			}
		}
		_assetPaletteUi.RemoveAssets(paths);
	}

	private void OnLibraryChange(int scrollPosition = -1)
	{
		DeselectAsset();
		// _currentLibrary is the title of the currently selected tab bar.
		// if the last library was removed, and _currentLibrary is "[Empty]",
		// we clear all the assets
		if (!_libraryDataDict.ContainsKey(_currentLibrary))
		{
			_assetPaletteUi.UpdateAllAssets(new List<Asset3DData>());
		}
		else
		{
			_assetPaletteUi.UpdateAllAssets(CurrentLibraryData.assetData, scrollPosition);
			if(!string.IsNullOrEmpty(CurrentLibraryData.savePath)) AssetPlacerPersistence.StoreGlobalData(LastSelectedLibrarySaveKey, CurrentLibraryData.savePath);
			GeneratePreviews(CurrentLibraryData.assetData, false);
		}
	}

	private void GeneratePreviews(IEnumerable<Asset3DData> libraryData, bool forceReload)
	{
		GeneratePreviews(libraryData, forceReload, -Vector3.One);
	}
	
	private void GeneratePreviews(IEnumerable<Asset3DData> libraryData, bool forceReload, Vector3 prevCustomPreviews)
	{
		var thumbnailSize = Vector2I.One * _editorInterface.GetEditorSettings()
			.GetSetting("filesystem/file_dialog/thumbnail_size").AsInt32();
		
		foreach (Asset3DData asset in libraryData)
		{
			try
			{
				PreviewGenerator._GenerateFromPath(asset.path, thumbnailSize, new Callable(this, MethodName.OnPreviewLoaded), forceReload,  GetPreviewPerspective(asset), asset.customPreview, prevCustomPreviews);
			}
			catch (AssetPreviewGenerator.PreviewForResourceUnhandledException _)
			{
				if (ResourceLoader.Exists(asset.path))
				{
					EditorResourcePreview resourcePreviewer = _editorInterface.GetResourcePreviewer();
					resourcePreviewer.QueueResourcePreview(asset.path, this,
						MethodName.OnPreviewLoaded, new Variant());
				}
				else
				{
					_assetPaletteUi.SetAssetBroken(asset.path, true);
				}
			}
		}
	}

	private AssetPreviewGenerator.Perspective GetPreviewPerspective(Asset3DData asset)
	{
		var previewPerspective = asset.previewPerspective != Asset3DData.PreviewPerspective.Default
			? asset.previewPerspective
			: CurrentLibraryData.previewPerspective;

		return AssetPreviewGenerator.GetPerspective(previewPerspective);
	}

	public void OnPreviewLoaded(string path, Texture2D preview, Texture2D thumbnailPreview, Variant userdata)
	{
		OnPreviewLoaded(path, preview);
	}
	
	public void OnPreviewLoaded(string assetPath, Variant preview)
	{
		if (preview.Obj is Texture2D previewTexture)
		{
			_assetPaletteUi.UpdateAssetPreview(assetPath, previewTexture, previewTexture, new Variant());
		}
		_assetPaletteUi.SetAssetBroken(assetPath, preview.Obj is not Texture2D);
	}

	public Node3D InstantiateAsset(Asset3DData assetData, AssetLibraryData library)
	{
		if (!ResourceLoader.Exists(assetData.path))
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Cannot find resource at {assetData.path}: File might have been deleted or moved.");
			_assetPaletteUi.SetAssetBroken(assetData.path, true);
			return null;
		}
		
		var asset = ResourceLoader.Load<Resource>(assetData.path); // Expensive operation
		Node3D assetNode = null;
		
		var updateButton = assetData.isMesh != asset is Mesh;
		assetData.isMesh = asset is Mesh;
		if (updateButton && library != null && library == CurrentLibraryData)
		{
			_assetPaletteUi.UpdateAssetButton(_selectedAsset);
			library.dirty = true;
			UpdateSaveDisabled();
		}
		
		if (asset is PackedScene scene)
		{
			assetNode = scene.Instantiate<Node3D>();
		}
		else if (asset is Mesh mesh)
		{
			var meshInstance = new MeshInstance3D();
			meshInstance.Mesh = mesh;
			assetNode = meshInstance;
		}

		if(assetNode == null)
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Cannot instantiate asset at {_selectedAsset.path}: Resource type is not supported (should be a Scene or a Mesh).");
			_assetPaletteUi.SetAssetBroken(assetData.path, true);
		}
		else
		{
			_assetPaletteUi.SetAssetBroken(assetData.path, false);
			if(library == CurrentLibraryData) ReloadAssetPreview(assetData.path);
		}
		return assetNode;
	}
	
	public void ClearHologram()
	{
		Hologram?.QueueFree();
		Hologram = null;
	}

	public void SetAssetTransformDataFromHologram() // when added to tree
	{
		if (_selectedAsset == null || Hologram == null || !Hologram.IsInsideTree()) return;
		if (!_selectedAsset.hologramInstantiated)
		{
			_selectedAsset.hologramInstantiated = true;
			_selectedAsset.defaultTransform = Hologram.GlobalTransform;
			SaveTransform();
		}
		else
		{
			var holoTransform = Hologram.GlobalTransform;
			holoTransform.Basis = _selectedAsset.lastTransform.Basis;
			Hologram.GlobalTransform = holoTransform;
		}
	}
	
	public void DeselectAsset()
	{
		_selectedAsset = null;
		SelectedAssetName = null;
		ClearHologram();
		_assetPaletteUi.MarkButtonAsDeselected();
	}

	public bool IsAssetSelected()
	{
		return _selectedAsset != null;
	}

	public void TrySelectPreviousAsset()
	{
		_assetPaletteUi.SelectAsset(_lastSelectedAssetPath);
	}

	public void SaveTransform()
	{
		_selectedAsset.lastTransform = Hologram.GlobalTransform;
		UpdateResetTransformButton(_selectedAsset);
	}

	public void UpdateResetTransformButton(Asset3DData data)
	{
		_assetPaletteUi.SetResetTransformButtonVisible(data.path, data.lastTransform != data.defaultTransform);
	}

	public Node3D CreateInstance()
	{
		Debug.Assert(Hologram != null, "Trying to create an instance without a hologram");
		LastPlacedAsset = Hologram.Duplicate() as Node3D;
		Hologram.GetParent().AddChild(LastPlacedAsset);
		return LastPlacedAsset;
	}

	private string GetAvailableLibraryName(string desiredName)
	{
		if (desiredName == AssetPaletteUi.EmptyTabTitle) desiredName = "Empty";
		var name = desiredName;
		var i = 1;
		while (_libraryDataDict.Keys.Any(x => x == name))
		{
			name = $"{desiredName} ({i})";
			i++;
		}
		return name;
	}

	private string GetFolderPathFromFilePath(string path)
	{
		var idx = path.LastIndexOf('/');

		var folder = idx >=0 ? path.Substring(0, idx) : "";
		if (path.Substring(0, idx+1).EndsWith("//")) return path.Substring(0, idx+1); //root folder
		return folder;
	}
	
	private string GetFileNameFromFilePath(string path)
	{
		var fileNameFull = path.GetFile();
		return fileNameFull.Substring(0, fileNameFull.Length - 5);
	}

	public void ResetHologramTransform()
	{
		if (_selectedAsset != null && Hologram != null)
		{
			var holoTransform = Hologram.GlobalTransform;
			holoTransform.Basis = _selectedAsset.defaultTransform.Basis;
			Hologram.GlobalTransform = holoTransform;
			SaveTransform();
		}
	}
}

#endif
