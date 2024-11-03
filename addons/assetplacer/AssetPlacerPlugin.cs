// AssetPlacerPlugin.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using Godot.Collections;

namespace AssetPlacer;
	
[Tool]
public partial class AssetPlacerPlugin : ContextlessPlugin
{
	// Feture Flags
	private const bool Terrain3DPlacementControllerFeatureFlag = true;
	
	private const string SpawnParentPathSaveKey = "spawn_parent_path";
	private const string AssetPlacerTitle = "AssetPlacer";
	public const string PluginFolderPath = "res://addons/assetplacer";
	private const string PluginFilePath = $"{PluginFolderPath}/plugin.cfg";
	
	private AssetPlacerUi _assetPlacerUi;
	private AssetPalette _assetPalette;
	private Snapping _snapping;
	private NodePathSelector _spawnParentSelection;
	private InputManager _inputManager;
	
	private Camera3D _viewportCamera;
	private bool _externalUi = false;
	private bool _mouseOverExternalUi = false;
	
	private Node _toolbarButtonContainer;
	public static string pluginVersion = "0.0";
	public static string godotVersion = "4.3";
	private Transform3D _hologramBeforeTransform;
	private float _rotatingHologramMouseStart;
	private const float FullRotationMouseViewportDistance = 0.5f;
	private Node _editedSceneRoot;
	private TooltipPanel _tooltipPanel;
	private bool _tooltipOnMouse;
	private Vector2 _tooltipPos;
	
	// placement controllers
	private AssetPlacementController _currentPlacementController;
	private PlanePlacementController _planePlacementController;
	private DummyPlacementController _dummyPlacementController;
	private SurfacePlacementController _surfacePlacementController;
	private Terrain3DPlacementController _terrain3DPlacementController;

	private enum ProcessState
	{
		Idle, PlacingHologram, RotatingAssetInstance, TransformingHologram, 
		PaintingHologram
	}

	private const string PlacingHologramTooltip = "Click to Place\n #1+Click to Place and Edit\n #2 to Transform\n #3 to Reset Transform";
	private static readonly string TransformingHologramTooltip = $"{InputManager.ConfirmKeys.FirstOrDefault().ToString()} to Confirm Transformation";
	private const string NoSpawnParentTooltip = "Set Spawn Parent!";

	private ProcessState _processState = ProcessState.Idle;
	
	public static string ReplaceTags(string str)
	{
		var newstr = str;
		newstr = newstr.Replace("##version##", pluginVersion);
		newstr = newstr.Replace("##godotversion##", godotVersion);
		return newstr;
	}

	#region Initializers and Deconstructors

	private string ReadPluginVersion()
	{
		using var file = FileAccess.Open(PluginFilePath, FileAccess.ModeFlags.Read);
		while (!file.EofReached())
		{
			string line = file.GetLine();
			if (line.StartsWith("version"))
			{
				var idx = line.IndexOf('\"');
				return line.Substring(idx+1, line.LastIndexOf('\"')-idx-1);
			}
		}

		return "#versionnotfound#";
	}

	protected override void _Init()
	{
		if (!FileAccess.FileExists(PluginFilePath))
		{
			GD.PrintErr($"Plugin location appears to be incorrect. Plugin expected at: {PluginFilePath}. " +
			            $"\nPlease follow these steps to fix: " +
			            $"\n1. Deactivate the plugin " +
			            $"\n2. Make sure the assetplacer folder is directly contained in the addons folder" +
			            $"\n3. Press 'Build' again!");
			initFailed = true;
			return;
		}
		
		#if GODOT4_2_OR_GREATER
		pluginVersion = GetPluginVersion();
		#else
		pluginVersion = ReadPluginVersion();
		#endif
		
		_inputManager = new InputManager();
		
		_editedSceneRoot = GetEditorInterface().GetEditedSceneRoot();
		
		AssetPlacerPersistence.Init();
		AssetPlacerPersistence.Instance.SetSceneRoot(_editedSceneRoot);
		
		SceneClosed += OnSceneClosed;
		SceneChanged += OnSceneChanged;
		
		GetEditorInterface().GetSelection().SelectionChanged += OnSelectionChanged;
		GetEditorInterface().GetBaseControl().ThemeChanged += OnThemeChanged;

		//////// Initialize palette
		_assetPalette = new AssetPalette();
		AddChild(_assetPalette);

		_assetPalette.Init(GetEditorInterface());
		/////////
		
		_spawnParentSelection = new NodePathSelector();
		AddChild(_spawnParentSelection);
		_spawnParentSelection.Init(GetEditorInterface(), SpawnParentPathSaveKey);

		_snapping = new Snapping();
		AddChild(_snapping);
		_snapping.Init(GetEditorInterface());
		
		InitializeUi();
		InitializePlacementControllers();
		SetState(ProcessState.Idle);
		
		_assetPlacerUi.OnSceneChanged();
		_spawnParentSelection.OnSceneChanged(_editedSceneRoot); // requires UI components to be initialized
		
		var _ = Shortcuts; // Force shortcut initialization
		Settings.InitSettings();
			
		InitializeToolbarContainer();

		_assetPalette.PostInit();
	}

	private void InitializeToolbarContainer()
	{
		// Reverse engineering to find the Toolbar over the 3D viewport
		var dummy = new Control();
		AddControlToContainer(CustomControlContainer.SpatialEditorMenu, dummy);
		_toolbarButtonContainer = dummy.GetParent().GetParent().GetParent().GetChild(0);
		RemoveControlFromContainer(CustomControlContainer.SpatialEditorMenu, dummy);
		dummy.QueueFree();
	}

	private void InitializePlacementControllers()
	{
		// Initialize Controllers
		_planePlacementController = new PlanePlacementController(_assetPlacerUi.placementUi, _snapping, GetEditorInterface());
		AddChild(_planePlacementController);
		_surfacePlacementController = new SurfacePlacementController(_assetPlacerUi.placementUi, _snapping, GetEditorInterface(), GetEditorInterface().GetEditedSceneRoot());
		AddChild(_surfacePlacementController);
		_terrain3DPlacementController = new Terrain3DPlacementController(_assetPlacerUi.placementUi, _snapping, GetEditorInterface(), GetEditorInterface().GetEditedSceneRoot());
		AddChild(_terrain3DPlacementController);
		_dummyPlacementController = new DummyPlacementController();
		AddChild(_dummyPlacementController);
		SetCurrentPlacementController(_planePlacementController);
		AddTerrain3DOptionIfEnabled();
		_assetPlacerUi.placementUi.PlaneChanged += () => _planePlacementController.OnPlaneChanged(_viewportCamera);
		_assetPlacerUi.placementUi.PlanePositionChanged += () => _planePlacementController.OnPlaneChanged(_viewportCamera);
		_assetPlacerUi.placementUi.PlacementModeChanged += (mode) =>
		{
			switch ((PlacementUi.PlacementMode) mode)
			{
				case PlacementUi.PlacementMode.Plane: 
					SetCurrentPlacementController(_planePlacementController);
					_planePlacementController.OnPlaneChanged(_viewportCamera);
					break;
				case PlacementUi.PlacementMode.Surface:
					SetCurrentPlacementController(_surfacePlacementController);
					break;
				case PlacementUi.PlacementMode.Terrain3D:
					SetCurrentPlacementController(_terrain3DPlacementController);
					break;
				case PlacementUi.PlacementMode.Dummy: 
					// You can safely print some debug stuff here
					SetCurrentPlacementController(_dummyPlacementController);
					break;
			}
		};
		_assetPlacerUi.placementUi.PlacementModeExpanded += AddTerrain3DOptionIfEnabled;
	}

	public const bool Development = false;

	public override void _EnablePlugin()
	{
		if (initFailed) return;
		if(!Development && AssetPlacerPersistence.Instance.GetShowLicenseAndSetFalse()) _assetPlacerUi.OpenAboutDialog();
	}

	public override void _DisablePlugin()
	{
		if (initFailed) return;
		AssetPlacerPersistence.TrySavePluginData();
	}

	protected override Control _CreateDrawPanel()
	{
		_tooltipPanel = new TooltipPanel();
		return _tooltipPanel;
	}

	protected override void _Cleanup()
	{
		AssetPlacerPersistence.TrySavePluginData();
		SceneClosed -= OnSceneClosed;
		SceneChanged -= OnSceneChanged;
		GetEditorInterface().GetSelection().SelectionChanged -= OnSelectionChanged;
		GetEditorInterface().GetBaseControl().ThemeChanged -= OnThemeChanged;
		
		SetCurrentPlacementController(null);
		_assetPalette.ClearHologram();
		CleanupAssetPlacerUi();
		_snapping.ClearGrid();
		_assetPalette.Cleanup();
		_assetPalette.QueueFree();
		_spawnParentSelection.QueueFree();
		_snapping.QueueFree();
		AssetPlacerPersistence.Cleanup();
	}
	
	private void InitializeUi()
	{
		if (_assetPlacerUi != null) return;

		var assetPlacerContainerScene = ResourceLoader.Load<PackedScene>("res://addons/assetplacer/ui/AssetPlacerUi.tscn");
		_assetPlacerUi = assetPlacerContainerScene.Instantiate<AssetPlacerUi>();
		_assetPlacerUi.Init();
		_assetPlacerUi.ApplyTheme(GetEditorInterface().GetBaseControl());
		AddControlToBottomPanel(_assetPlacerUi, AssetPlacerTitle);
		_assetPlacerUi.placementUi._terrain3DSelector.Init(GetEditorInterface(), PlacementUi.Terrain3DSaveKey);
		_assetPlacerUi.placementUi._terrain3DSelector.OnSceneChanged(_editedSceneRoot);
		
		_assetPalette.SetUi(_assetPlacerUi._assetPaletteUi);
		_spawnParentSelection.SetUi(_assetPlacerUi._spawnParentSelectionUi);
		_snapping.SetUi(_assetPlacerUi.snappingUi);
		
		GetWindow().MouseEntered += () =>
		{
			// Switch focus to editor when moving from external window to editor.
			if (_externalUi && _assetPalette.IsAssetSelected() && !_mouseOverExternalUi && _assetPlacerUi.GetParent<Window>().HasFocus())
			{
				GetWindow().GrabFocus();
			}
		};
		_assetPlacerUi.HelpDialogOpened += () => _assetPlacerUi.InitHelpDialog(Shortcuts.GetShortcutStringDictionary());
		_assetPlacerUi.ToExternalWindow += UiToExternalWindow;
	}

	private void CleanupAssetPlacerUi()
	{
		if (_assetPlacerUi!=null)
		{
			if (_externalUi)
			{
				RemoveExternalUiWindow();
			}
			else
			{
				RemoveControlFromBottomPanel(_assetPlacerUi);
			}
			_assetPlacerUi.QueueFree();
			_assetPlacerUi = null;
			_planePlacementController?.Cleanup(); 
			_snapping.ClearGrid();
		}
	}

	private void InitShortcuts(Shortcuts shortcutsObj)
	{
		// shortcut for changing plane position
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_viewportCamera == null || _currentPlacementController != _planePlacementController || InputManager.rmbPressed) return false;
			_planePlacementController.ConfigurePlane(_inputManager.viewportMousePos, GetFocused3DViewport() ?? GetFirstViewport());
			return true;
		}, Shortcuts.PlacementPlanePosition, Key.G);
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_viewportCamera == null || _processState != ProcessState.PlacingHologram || InputManager.rmbPressed) return false;
			SetState(ProcessState.TransformingHologram);
			return false;
		}, Shortcuts.TransformAsset, Key.E, Key.R);
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.Idle) return false;
			if(!_externalUi) MakeBottomPanelItemVisible(_assetPlacerUi);
			_assetPalette.TrySelectPreviousAsset();
			return true; 
		}, Shortcuts.SelectPreviousAsset, Key.Space);
		
		#region PlaneShortcuts
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState is not (ProcessState.Idle or ProcessState.PlacingHologram) || _currentPlacementController != _planePlacementController) return false;
			_assetPlacerUi.placementUi.SetPlane(Vector3.Axis.X);
			return true; 
		}, Shortcuts.SelectYZPlane, Key.Z);
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState is not (ProcessState.Idle or ProcessState.PlacingHologram) || _currentPlacementController != _planePlacementController) return false;
			_assetPlacerUi.placementUi.SetPlane(Vector3.Axis.Y);
			return true; 
		}, Shortcuts.SelectXZPlane, Key.X);
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState is not (ProcessState.Idle or ProcessState.PlacingHologram) || _currentPlacementController != _planePlacementController) return false;
			_assetPlacerUi.placementUi.SetPlane(Vector3.Axis.Z);
			return true; 
		}, Shortcuts.SelectXYPlane, Key.C);
		#endregion
		
		#region TransformShortcuts
		shortcutsObj.AddKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.ResetHologramTransform();
			if(_processState == ProcessState.TransformingHologram) _hologramBeforeTransform = _assetPalette.Hologram.Transform;
			return true;
		}, Shortcuts.ResetTransform, true, false, Key.E);
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.GlobalRotate(Vector3.Right, Mathf.DegToRad(-90));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.RotateX, Key.A);
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.GlobalRotate(Vector3.Up, Mathf.DegToRad(-90));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.RotateY, Key.S);
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.GlobalRotate(Vector3.Back, Mathf.DegToRad(-90));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.RotateZ, Key.D);
		
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.Scale *= new Vector3(-1,1,1);
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.FlipX, Key.Key1);
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.Scale *= new Vector3(1,-1,1);
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.FlipY, Key.Key2);
		shortcutsObj.AddSimpleKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			_assetPalette.Hologram.Scale *= new Vector3(1,1,-1);
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.FlipZ, Key.Key3);
		
		const string shortcutShiftRotation = "Shortcut_Shift_Rotation_Step";
		Settings.RegisterSetting(Settings.DefaultCategory, shortcutShiftRotation, 45f, Variant.Type.Float, PropertyHint.Range, "-180,180,degrees");
		
		shortcutsObj.AddKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			var step = Settings.GetSetting(Settings.DefaultCategory, shortcutShiftRotation).AsSingle();
			_assetPalette.Hologram.GlobalRotate(Vector3.Right, Mathf.DegToRad(-step));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.ShiftRotateX, true, false, Key.A);
		shortcutsObj.AddKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			var step = Settings.GetSetting(Settings.DefaultCategory, shortcutShiftRotation).AsSingle();
			_assetPalette.Hologram.GlobalRotate(Vector3.Up, Mathf.DegToRad(-step));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.ShiftRotateY, true, false, Key.S);
		shortcutsObj.AddKeys3DGuiShortcut(() =>
		{
			if (_processState != ProcessState.PlacingHologram && _processState != ProcessState.TransformingHologram || InputManager.rmbPressed) return false;
			var step = Settings.GetSetting(Settings.DefaultCategory, shortcutShiftRotation).AsSingle();
			_assetPalette.Hologram.GlobalRotate(Vector3.Back, Mathf.DegToRad(-step));
			_assetPalette.SaveTransform();
			return true; 
		}, Shortcuts.ShiftRotateZ, true, false, Key.D);
		#endregion
		
		#region SnappingShorctus
		shortcutsObj.AddKeys3DGuiShortcut(()=>
		{
			_snapping.DoubleSnapStep();
			return true;
		}, Shortcuts.DoubleSnapStep, false, true, Key.Up);
		shortcutsObj.AddKeys3DGuiShortcut(()=>
		{
			_snapping.HalveSnapStep();
			return true;
		}, Shortcuts.HalveSnapStep, false, true, Key.Down);
		#endregion
	}

	#endregion
	
	private void SetToolTip(string text, params Color[] colors)
	{
		var font = GetEditorInterface().GetBaseControl().GetThemeFont("main", "EditorFonts");
		var pos = _tooltipOnMouse ? _inputManager.screenMousePosition : _tooltipPos;
		((TooltipPanel) DrawPanel).SetTooltip(text, font, pos, _inputManager.tooltipRect, colors);
	}

	
	#region Notifications and Signals
	
	public override void _Notification(int what)
	{
		if (initFailed) return;
		if (what == NotificationCrash 
		    || what == NotificationApplicationFocusOut
		    || what == NotificationWMCloseRequest
		    || what == NotificationWMWindowFocusOut
		    || what == NotificationEditorPreSave)
		{
			AssetPlacerPersistence.TrySavePluginData();
		}
	}
	
	private void OnThemeChanged()
	{
		_assetPlacerUi.ApplyTheme(GetEditorInterface().GetBaseControl());
	}
	
	private void OnSelectionChanged()
	{
		var selection = GetEditorInterface().GetSelection().GetSelectedNodes();
		_currentPlacementController?.OnSelectionChanged();
		_assetPalette?.OnSelectionChanged();
		
		if (_processState is ProcessState.TransformingHologram or ProcessState.PlacingHologram)
		{
			bool hologramSelected = selection.Count == 1 && selection[0] == _assetPalette.Hologram;
			bool selectionEmpty = _processState is ProcessState.PlacingHologram && selection.Count == 0;
			if (hologramSelected || selectionEmpty)
			{
				if (_processState is ProcessState.PlacingHologram)
				{
					if(selection.Contains(_assetPalette.Hologram)) GetEditorInterface().GetSelection().RemoveNode(_assetPalette.Hologram);
				}
				_spawnParentSelection.OnSelectionChanged(new Array<Node>());
				_assetPlacerUi.placementUi._terrain3DSelector.OnSelectionChanged(new Array<Node>());
				return;
			}
			else // several assets selected or transforming hologram deselected
			{
				if(selection.Contains(_assetPalette.Hologram)) GetEditorInterface().GetSelection().RemoveNode(_assetPalette.Hologram);
				SetState(ProcessState.Idle);
				return;
			}
		}
		_spawnParentSelection.OnSelectionChanged(selection);
		_assetPlacerUi.placementUi._terrain3DSelector.OnSelectionChanged(selection);
	}
	

	private void OnSceneClosed(string filePath)
	{
		// if this was the currently edited scene
		if (GetEditorInterface().GetEditedSceneRoot()?.SceneFilePath == filePath)
		{
			AssetPlacerPersistence.Instance.SavePluginData();
			AssetPlacerPersistence.Instance.SetSceneRoot(null);
			SetState(ProcessState.Idle);
		}
	}

	private void OnSceneChanged(Node root)
	{
		AssetPlacerPersistence.Instance.SavePluginData();
		AssetPlacerPersistence.Instance.SetSceneRoot(root);
		SetState(ProcessState.Idle);
		OnSelectionChanged();
		_spawnParentSelection.OnSceneChanged(root);
		_assetPlacerUi.placementUi._terrain3DSelector.OnSceneChanged(root);
		_surfacePlacementController?.SetSceneRoot(root);
		_assetPlacerUi.OnSceneChanged();
		_planePlacementController?.OnSceneRootChanged();
		_editedSceneRoot = root;
	}

	private void UiToExternalWindow()
	{
		_externalUi = true;
		RemoveControlFromBottomPanel(_assetPlacerUi);
		var w = new Window();
		GetEditorInterface().GetBaseControl().GetWindow().AddChild(w);
		w.Title = AssetPlacerTitle;
		w.Exclusive = false;
		w.Transient = true;
		w.WrapControls = true;
		w.CloseRequested += UiToBottomPanel;
		w.MouseEntered += () => _mouseOverExternalUi = true;
		w.MouseExited += () => _mouseOverExternalUi = false;
		w.ThemeTypeVariation = "embedded_border";
		var bg = new Panel();
		w.AddChild(bg);
		w.AddChild(_assetPlacerUi);
		_assetPlacerUi.Visible = true;
		w.Size = (Vector2I) _assetPlacerUi.Size;
		_assetPlacerUi.SetAnchorsPreset(Control.LayoutPreset.FullRect);
		//CallDeferred("ResizeExternalWindow", w);
		bg.Size = w.Size;
		bg.ThemeTypeVariation = "TabContainer";
		var baseControl = GetEditorInterface().GetBaseControl();
		w.Position = baseControl.GetViewport().GetWindow().Position + (Vector2I) baseControl.GetViewportRect().GetCenter() - w.Size/2;
		_assetPlacerUi.OnAttachmentChanged(false);
		AssetPlacerUi.ClampWindowToScreen(w, baseControl);
	}

	private void UiToBottomPanel()
	{
		_assetPlacerUi.OnAttachmentChanged(true);
		if(_externalUi) RemoveExternalUiWindow();
		_mouseOverExternalUi = false;
		_externalUi = false;
		AddControlToBottomPanel(_assetPlacerUi, AssetPlacerTitle);
		MakeBottomPanelItemVisible(_assetPlacerUi);
	}
	
	private void RemoveExternalUiWindow()
	{
		var w = _assetPlacerUi.GetParent<Window>();
		w.RemoveChild(_assetPlacerUi);
		GetEditorInterface().GetBaseControl().GetWindow().RemoveChild(w);
		w.QueueFree();
	}
	#endregion
	
	
	#region Built-in Process
	
	private double t = 0;
	protected override void _ProcessUpdate(double delta)
	{
		if (initFailed) return;
		if (_snapping == null)
		{
			GD.PrintErr($"{nameof(AssetPlacerPlugin)}: Please reload Asset Placer Plugin from the Project Settings panel!");
			ProcessMode = ProcessModeEnum.Disabled;
			_assetPlacerUi.ProcessMode = ProcessModeEnum.Disabled;
			SetProcessInput(false);
			return;
		}
		t += delta;
		CheckEditedSceneRoot();
		if (_spawnParentSelection.Node == null)
		{
			if(_assetPalette.IsAssetSelected()) SetToolTip(NoSpawnParentTooltip, Colors.Red);
			return;
		}

		if (_viewportCamera != null)
		{
			var controllerTooltip = _currentPlacementController?.Process(_editedSceneRoot, _viewportCamera, InputManager.rmbPressed);
			// STATE MACHINE
			switch (_processState)
			{
				case ProcessState.Idle:
					if (_assetPalette.Hologram != null) SetState(ProcessState.PlacingHologram);
					SetToolTip("");
					break;
				case ProcessState.PlacingHologram:
					if (_assetPalette.Hologram == null)
					{
						SetState(ProcessState.Idle);
						break;
					}
					ProcessPlacingHologram();
					break;
				case ProcessState.TransformingHologram:
					SetToolTip(TransformingHologramTooltip, new Color("#FFB800"));
					break;
				case ProcessState.RotatingAssetInstance:
					ProcessRotatingInstance();
					break;
				case ProcessState.PaintingHologram:
					ProcessPaintingHologram();
					break;
			}
			
			if(controllerTooltip != null) SetToolTip(controllerTooltip);
		}
		else
		{
			SetToolTip("");
		}

		if (t >= 1) ////////////////////
		{
			t = 0;
		} /////////////////////////////
	}
	
	private void CheckEditedSceneRoot()
	{
		var currentRoot = GetEditorInterface().GetEditedSceneRoot();
		if (currentRoot != _editedSceneRoot) // Edited Scene Root changed (rename, deletion, scene closed, other node made root, why-so-ever)
		{
			UpdateEditedSceneRoot(currentRoot, false);
		}
	}

	private void UpdateEditedSceneRoot(Node currentRoot, bool onSceneChanged)
	{
		_editedSceneRoot = currentRoot;
		AssetPlacerPersistence.Instance.SetSceneRoot(_editedSceneRoot);
		_spawnParentSelection.SetSceneRoot(_editedSceneRoot);
		_assetPlacerUi.placementUi._terrain3DSelector.SetSceneRoot(_editedSceneRoot);
		_surfacePlacementController?.SetSceneRoot(_editedSceneRoot);
		_terrain3DPlacementController?.SetSceneRoot(_editedSceneRoot);
		_planePlacementController?.OnSceneRootChanged();
		// when adding something here, check if you need to add it to OnSceneChanged or OnSceneClosed as well
	}

	#endregion
	
	
	#region State Machine Process methods

	private void SetState(ProcessState state)
	{
		var before = _processState;
		_processState = state;
		switch (state)
		{
			case ProcessState.PlacingHologram:
				GetEditorInterface().GetSelection().Clear();
				_tooltipOnMouse = true;
				break;
			case ProcessState.TransformingHologram:
				_hologramBeforeTransform = _assetPalette.Hologram.Transform;
				GetEditorInterface().GetSelection().Clear();
				GetEditorInterface().GetSelection().AddNode(_assetPalette.Hologram);
				_tooltipOnMouse = true;
				break;
			case ProcessState.Idle:
				if (before == ProcessState.TransformingHologram)
				{
					_assetPalette.Hologram.Transform = _hologramBeforeTransform;
				}
				if (_assetPalette.IsAssetSelected())
				{
					_assetPalette.DeselectAsset();
					SetToolTip("");
				}
				_tooltipOnMouse = true;
				break;
			case ProcessState.RotatingAssetInstance:
				_rotatingHologramMouseStart = GetViewport().GetMousePosition().X / GetViewport().GetVisibleRect().Size.X;
				SetToolTip("Move mouse left/right to rotate");
				_tooltipOnMouse = false;
				break;
			case ProcessState.PaintingHologram:
				SetToolTip("Drag to place");
				_tooltipOnMouse = true;
				break;
		}
	}
	
	private string _lastPlacingTooltip = "";
	private Transform3D _lastPlacingAssetTransform = new();
	private void ProcessPlacingHologram()
	{
		// update hologram position
		var parentOrNull = _assetPalette.Hologram.GetParentOrNull<Node>();
		bool positionValid = false;
		string tooltip = "";
		Color? tooltipColor = null;
		if (IsMouseOverValidFocused3dViewport() && !InputManager.rmbPressed)
		{
			var placingNodes = new List<Node3D>{_assetPalette.Hologram};
			var placementInfo = _currentPlacementController.GetPlacementPosition(_viewportCamera, _inputManager.viewportMousePos, placingNodes);
			var positionInfo = placementInfo.positionInfo;
			if (positionInfo.posValid)
			{
				if (parentOrNull == null)
				{
					var hologramTransform = _assetPalette.Hologram.Transform; // without parent the hologram has the size & rotation it should
					_spawnParentSelection.Node.AddChild(_assetPalette.Hologram); // now hologram has a parent
					_assetPalette.Hologram.GlobalTransform = hologramTransform; // set its global transform to counter the parent's transform
					_assetPalette.SetAssetTransformDataFromHologram();
				}
				_snapping.ShowGrid(false);
				if (SnappingEnabled)
				{
					if(InputManager.ctrlPressed) _snapping.ShowGrid(true);
					var snapStep = InputManager.shiftPressed ? _snapping.TranslateShiftSnapStep : _snapping.TranslateSnapStep;
					positionInfo.pos = _currentPlacementController.SnapToPosition(positionInfo, snapStep);
				}
				
				var transform = AlignTransformWithPlacementInfo(_assetPalette.Hologram.GlobalTransform, positionInfo);
				_assetPalette.Hologram.GlobalTransform = transform;
				positionValid = true;

				if (!SnappingEnabled || !VectorUtils.AreTransformsEqualApprox(_lastPlacingAssetTransform, transform))
				{
					_lastPlacingTooltip = "";
				}
				
				// set tooltip
				var coords =
					FormattableString.Invariant($"({positionInfo.pos.X:N3}, {positionInfo.pos.Y:N3}, {positionInfo.pos.Z:N3})\n");
				var shortcutTooltip = PlacingHologramTooltip.Replace("#1",Settings.GetSetting(Settings.DefaultCategory, Settings.UseShiftSetting).AsBool() ? "Shift" : "Alt");
				shortcutTooltip = shortcutTooltip.Replace("#2", Shortcuts.GetShortcutString(Shortcuts.TransformAsset));
				shortcutTooltip = shortcutTooltip.Replace("#3", Shortcuts.GetShortcutString(Shortcuts.ResetTransform));
				
				tooltipColor = Colors.White;
				tooltip = coords + shortcutTooltip;
			}

			if(placementInfo.placementTooltip != null) tooltip = placementInfo.placementTooltip;
			if(placementInfo.placementTooltipColor != null) tooltipColor = placementInfo.placementTooltipColor;
		}
			
		if(!positionValid)
		{
			var localTransform = _assetPalette.Hologram.Transform;
			parentOrNull?.RemoveChild(_assetPalette.Hologram);
			_assetPalette.Hologram.Transform = localTransform;
		}

		if (!string.IsNullOrEmpty(_lastPlacingTooltip))
		{
			tooltip = $"{_lastPlacingTooltip}\n" + tooltip;
			if(tooltipColor.HasValue) SetToolTip(tooltip, Colors.LightYellow, tooltipColor.Value);
			else SetToolTip(tooltip);
		}
		else
		{
			if(tooltipColor.HasValue) SetToolTip(tooltip, tooltipColor.Value);
			else SetToolTip(tooltip);
		}
	}

	private Transform3D AlignTransformWithPlacementInfo(Transform3D transform, PlacementPositionInfo positionInfo)
	{
		if (positionInfo is SurfacePlacementPositionInfo surfacePlacementInfo && surfacePlacementInfo.align)
		{
			transform =
				transform.Align(surfacePlacementInfo.alignmentDir(transform), surfacePlacementInfo.surfaceNormal);
		}

		transform.Origin = positionInfo.pos;
		return transform;
	}

	private bool SnappingEnabled => _snapping != null && _snapping.TranslateSnappingActive() != InputManager.ctrlPressed; //xor

	private void ProcessRotatingInstance()
	{
		_tooltipPos = _viewportCamera.UnprojectPosition(_assetPalette.LastPlacedAsset.GlobalPosition)
					  + _viewportCamera.GetViewport().GetScreenTransform().Origin;
		var transform = _assetPalette.LastPlacedAsset.Transform;
		if (!InputManager.lmbPressed)
		{
			_assetPalette.LastPlacedAsset.GetParent().RemoveChild(_assetPalette.LastPlacedAsset); // will be done in undoRedo system
			
			// undo system
			var undo = GetUndoRedo();
			undo.CreateAction($"Place {_assetPalette.SelectedAssetName} asset", UndoRedo.MergeMode.Disable, _spawnParentSelection.Node);
			undo.AddDoMethod(this, nameof(PlaceAssetAction), _assetPalette.LastPlacedAsset, _spawnParentSelection.Node, _assetPalette.LastPlacedAsset.Name, transform);
			undo.AddUndoMethod(this, nameof(UndoPlaceAsset), _assetPalette.LastPlacedAsset, _spawnParentSelection.Node);
			undo.AddDoReference(_assetPalette.LastPlacedAsset);
			undo.CommitAction();

			var altPlacement = Settings.GetSetting(Settings.DefaultCategory, Settings.UseShiftSetting).AsBool() ? InputManager.shiftPressed : InputManager.altPressed;
			if (altPlacement)
			{
				GetEditorInterface().CallDeferred("edit_node", _assetPalette.LastPlacedAsset);
				var editorSelection = GetEditorInterface().GetSelection();
				editorSelection.Clear();
				editorSelection.AddNode(_assetPalette.LastPlacedAsset);
				_assetPalette.DeselectAsset();
				SetToolTip("");
				SetState(ProcessState.Idle);
			} else
			{
				SetState(ProcessState.PlacingHologram);
			}

			return;
		}
		// rotate asset
		const float rotationDeadZone = 0.01f;
		var dist = GetMouseDistWithDeadzone(_rotatingHologramMouseStart, rotationDeadZone);
		var rotation = (dist) * Mathf.Tau / FullRotationMouseViewportDistance % Mathf.Tau;
		
		var rotString = FormattableString.Invariant($"{Mathf.RadToDeg(rotation):N3}");
		SetToolTip($"{rotString}\nMove mouse left/right to rotate");
		_currentPlacementController.RotateNode(_assetPalette.LastPlacedAsset, _assetPalette.Hologram.Rotation, rotation);
		
	}

	private float GetMouseDistWithDeadzone(float startPos, float mouseDeadZone)
	{
		var mousePos = GetViewport().GetMousePosition().X / GetViewport().GetVisibleRect().Size.X;
		var dist = mousePos - startPos;
		dist -= Mathf.Sign(dist) * Mathf.Min(mouseDeadZone, Mathf.Abs(dist));
		return dist;
	}


	private List<Node3D> _paintingAssets = new();
	private Vector2 _lastPaintingMousePos = -Vector2.One;
	private string _lastPaintingTooltip = "";
	private Vector3 _lastPaintingAssetPos = new();
	private void ProcessPaintingHologram()
	{
		var asset = _assetPalette.LastPlacedAsset;
		if (!InputManager.lmbPressed)
		{
			var list = new Node3DList(_paintingAssets); // nodes need to be in tree for this
			_paintingAssets.ForEach(a=>a.GetParent().RemoveChild(a)); // parent will be added in undoRedo system
			
			// undoRedo system
			var undo = GetUndoRedo();
			var actionName =
				$"Place {_paintingAssets.Count} {_assetPalette.SelectedAssetName} {(_paintingAssets.Count > 1 ? "assets" : "asset")}";
			undo.CreateAction(actionName, UndoRedo.MergeMode.Disable, _spawnParentSelection.Node);
			undo.AddDoMethod(this, nameof(PlaceAssetsAction), list, _spawnParentSelection.Node, asset.Name);
			undo.AddUndoMethod(this, nameof(UndoPlaceAssets), list, _spawnParentSelection.Node);
			undo.AddDoReference(list);
			undo.CommitAction();

			var altPlacement = Settings.GetSetting(Settings.DefaultCategory, Settings.UseShiftSetting).AsBool() ? InputManager.shiftPressed : InputManager.altPressed;
			if (altPlacement)
			{
				GetEditorInterface().CallDeferred("edit_node", asset);
				var editorSelection = GetEditorInterface().GetSelection();
				editorSelection.Clear();
				_paintingAssets.ForEach(a=>editorSelection.AddNode(a));
				_assetPalette.DeselectAsset();
				SetToolTip("");
				SetState(ProcessState.Idle);
			} else
			{
				SetState(ProcessState.PlacingHologram);
			}

			_paintingAssets.Clear();
			_snapping.ShowGrid(false);
			return;
		}
		_snapping.ShowGrid(true);
		// paint new assets
		if (_inputManager.viewportMousePos != _lastPaintingMousePos)
		{
			_lastPaintingMousePos = _inputManager.viewportMousePos;
			
			var placingNodes = new List<Node3D>(_paintingAssets);
			if(_assetPalette.Hologram != null) placingNodes.Add(_assetPalette.Hologram);
			var placementInfo = _currentPlacementController.GetPlacementPosition(_viewportCamera, _inputManager.viewportMousePos, placingNodes);
			var positionInfo = placementInfo.positionInfo;
			if (positionInfo.posValid && asset != null)
			{
				var snapStep = InputManager.shiftPressed ? _snapping.TranslateShiftSnapStep : _snapping.TranslateSnapStep;
				positionInfo.pos = _currentPlacementController.SnapToPosition(positionInfo, snapStep);
				if (_paintingAssets.Count == 0 ||
					positionInfo.pos != _lastPaintingAssetPos) // don't check same position twice
				{
					_lastPaintingAssetPos = positionInfo.pos;
					// check if asset at that position placed yet
					if (_paintingAssets.All(a =>
							!VectorUtils.AreApproximatelyEqualPositions(a.GlobalTransform.Origin, positionInfo.pos)))
					{
						var parent = asset.GetParent();

						//// check if position is occupied
						Vector3 localPosition;
						if (parent is Node3D parent3D)
							localPosition = positionInfo.pos - parent3D.GlobalPosition;
						else
							localPosition = positionInfo.pos;

						if (!IsPositionOccupied(asset, localPosition, out _lastPaintingTooltip))
						{
							var duplicate = asset.Duplicate() as Node3D;
							_paintingAssets.Add(duplicate);
							parent.AddChild(duplicate);
							var duplicateTransform =
								AlignTransformWithPlacementInfo(duplicate!.GlobalTransform, positionInfo);
							duplicate.GlobalTransform = duplicateTransform;
						}
						////
					}
				}
			}
		}

		var tooltip = _paintingAssets.Count == 1 ? "Drag to place assets" : $"Placing {_paintingAssets.Count} assets";
		if (string.IsNullOrEmpty(_lastPaintingTooltip))
		{
			SetToolTip(tooltip, Colors.White);
		}
		else
		{
			tooltip += $"\n{_lastPaintingTooltip}";
			SetToolTip(tooltip, Colors.White, Colors.LightYellow);
		}
	}
	#endregion
	
	
	#region Input Methods

	protected override void _ForwardInput(InputEvent @event)
	{
		_inputManager._ForwardInput(@event);
	}

	protected override bool _Forward3DViewportInput(Viewport viewport, InputEvent @event)
	{
		if (ProcessMode == ProcessModeEnum.Disabled) return false;
		
		// need to always check, to update rmbPressed
		InputManager.InputEventType inputEventType = _inputManager.DetermineInputEventType(@event);
		
		// if we preview the scene, the viewports camera is incorrect due to a Godotbug.
		if(IsEditorViewportPreviewingCamera(viewport)) return false;
		
		_inputManager._Forward3DViewportInput(viewport, @event);

		_viewportCamera = viewport.GetCamera3D(); // todo: get preview camera here, if preview is enabled and you find out how...
		if (!(inputEventType == InputManager.InputEventType.Movement && InputManager.rmbPressed))
		{
			if (Shortcuts.Input3DGui(@event)) return true; // execute shortcuts
		}
		
		if (!InputManager.rmbPressed) { // process plane movement
			if(_currentPlacementController?.ProcessInput(inputEventType, _inputManager.viewportMousePos) == true) return true;
		}
		
		if (inputEventType == InputManager.InputEventType.Cancel)
		{
			switch (_processState)
			{
				case ProcessState.Idle: case ProcessState.PlacingHologram:
					if (_assetPalette.IsAssetSelected())
					{
						SwitchToSelectTool();
						_assetPalette.DeselectAsset();
						SetToolTip("");
						return true;
					}
					break;
				case ProcessState.TransformingHologram:
					SwitchToSelectTool();
					_assetPalette.Hologram.Transform = _hologramBeforeTransform;
					SetState(ProcessState.PlacingHologram);
					return true;
				case ProcessState.RotatingAssetInstance:
					_assetPalette.LastPlacedAsset?.QueueFree();
					SwitchToSelectTool();
					SetState(ProcessState.PlacingHologram);
					return true;
			}
		}

		if (inputEventType == InputManager.InputEventType.Confirm && _processState == ProcessState.TransformingHologram)
		{
			_assetPalette.SaveTransform();
			SetState(ProcessState.PlacingHologram);
			SwitchToSelectTool();
			return true;
		}

		if (_processState == ProcessState.PlacingHologram && _spawnParentSelection.Node != null)
		{
			return HologramPlacementInput(inputEventType);
		}
		
		return false;
	}
	private bool HologramPlacementInput(InputManager.InputEventType inputEventType)
	{
		// place asset
		if (inputEventType is InputManager.InputEventType.Placement or InputManager.InputEventType.AltPlacement)
		{
			if (SnappingEnabled)
				TryInstanceAssetAndPaint();
			else
				TryInstanceAssetAndRotate();
			return true;
		}
		
		return false;
	}

	private Shortcuts _shortcuts;
	private Shortcuts Shortcuts
	{
		get
		{
			if (_shortcuts == null)
			{
				_shortcuts = new Shortcuts();
				InitShortcuts(_shortcuts);
			}

			return _shortcuts;
		}
	}

	private void SwitchToSelectTool()
	{
		FindSelectToolButton(_toolbarButtonContainer);
	}

	private void FindSelectToolButton(Node parent)
	{
		foreach (var child in parent.GetChildren())
		{
			if (child is Button button) // first button is select tool
			{
				button.EmitSignal("pressed");
				return;
			}
		}
	}
	
	#endregion


	#region Asset Placement
	private void TryInstanceAssetAndRotate()
	{
		TryInstanceAsset(ProcessState.RotatingAssetInstance);
	}

	private void TryInstanceAssetAndPaint()
	{
		if (IsPositionOccupied(_assetPalette.Hologram, out var tooltip))
		{
			_lastPlacingAssetTransform = _assetPalette.Hologram.GlobalTransform;
			_lastPlacingTooltip = tooltip;
			return;
		}
		_lastPlacingTooltip = "";
		_lastPaintingTooltip = tooltip;
		var instance = TryInstanceAsset(ProcessState.PaintingHologram);
		if (instance == null) return;
		_paintingAssets.Clear();
		_paintingAssets.Add(instance);
	}

	private Node3D TryInstanceAsset(ProcessState nextState)
	{
		var holoParent = _assetPalette.Hologram.GetParentOrNull<Node>();
		if (holoParent == null) return null;

		// create an instance of the hologram, but add its parent in the do-function
		var instance = _assetPalette.CreateInstance();
		instance.Name = _assetPalette.SelectedAssetName;
		SetState(nextState);
		holoParent.RemoveChild(_assetPalette.Hologram);
		return instance;
	}

	private bool IsPositionOccupied(Node3D node, out string tooltip)
	{
		return IsPositionOccupied(node, node.Position, out tooltip);
	}
	
	private bool IsPositionOccupied(Node3D node, Vector3 localPosition, out string tooltip)
	{
		tooltip = "";
		var parent = node.GetParent();
		if (parent == null) return false;
		var placingNodeTransform = node.Transform;
		placingNodeTransform.Origin = localPosition;
		
		var children = parent.GetChildren();
		children.Remove(node);
		
		const int maxChildCheckCount = 1000; // at this point, other processes get so slow, that this should not matter
		if (children.Count > maxChildCheckCount)
		{
			tooltip = "Too many children - some duplication checks skipped.";
			children = children.GetSliceRange(children.Count-maxChildCheckCount, children.Count);
		}

		// iterate over all children of node's parent to check if their position is equal to that of node
		foreach (var child in children)
		{
			if (child is Node3D chileNode3D)
			{
				// checking local transform is sufficient, since they have the same parent
				if (VectorUtils.AreTransformsEqualApprox(chileNode3D.Transform, placingNodeTransform))
				{
					// same asset
					if (chileNode3D.SceneFilePath == node.SceneFilePath)
					{
						tooltip = "Position occupied.";
						return true;
					}
				}
			}
		}

		return false;
	}

	public void PlaceAssetAction(Node3D asset, Node parent, string name, Transform3D transform3D)
	{
		parent.AddChild(asset);
		asset.Name = name;
		asset.Transform = transform3D;
		asset.Owner = parent.GetTree().EditedSceneRoot;
	}	
	public void PlaceAssetsAction(Node3DList assets, Node parent, string name)
	{
		foreach (var asset in assets.NodeTransforms.Keys)
		{
			PlaceAssetAction(asset, parent, name, assets.NodeTransforms[asset]);
		}
	}

	public void UndoPlaceAsset(Node asset, Node parent)
	{
		parent.RemoveChild(asset);
	}
	
	public void UndoPlaceAssets(Node3DList assets, Node parent)
	{
		foreach (var asset in assets.NodeTransforms.Keys)
		{
			UndoPlaceAsset(asset, parent);
		}
	}
	private void SetCurrentPlacementController(AssetPlacementController controller)
	{
		if(_currentPlacementController != null) _currentPlacementController.Active = false;
		_currentPlacementController = controller;
		if (_currentPlacementController == null) return;
		controller.Active = true;
		_snapping.LineCnt = Mathf.RoundToInt(Snapping.DefaultLineCnt * _currentPlacementController.snappingGridSize);
		_snapping.UpdateGridMesh();
		_assetPalette.SetAssetTransformDataFromHologram();
	}

	private void AddTerrain3DOptionIfEnabled()
	{
		if (!_assetPlacerUi.placementUi.PlacementOptionButtonHasItem(PlacementUi.PlacementMode.Terrain3D))
		{
			if (Terrain3DPlacementControllerFeatureFlag && IsPluginEnabled(PluginTerrain3D))
			{
				_assetPlacerUi.placementUi.AddTerrain3DOption();
			}
		}
	}
	#endregion
	
}

#endif
