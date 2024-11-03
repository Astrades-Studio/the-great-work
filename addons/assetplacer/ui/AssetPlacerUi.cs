// AssetPlacerUi.cs
// Copyright (c) 2023 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using Godot;
using System.Globalization;

namespace AssetPlacer;

[Tool]
public partial class AssetPlacerUi : Control
{
	[Export] public NodePath snappingUiPath;
	[Export] public NodePath spawnParentSelectionUiPath;
	[Export] public NodePath placementUiPath;
	[Export] public NodePath helpDialog;
	[Export] public NodePath helpButton;
	[Export] public NodePath aboutDialog;
	[Export] public NodePath aboutButton;
	[Export] public NodePath toExternalWindowButton;
	[Export] public NodePath assetPaletteUi;
	[Export] public NodePath dynamicPreviewPanel;
	
	private HelpDialog _helpDialog;
	private AcceptDialog _aboutDialog;
	public SnappingUi snappingUi;
	public PlacementUi placementUi;
	public NodePathSelectorUi _spawnParentSelectionUi;
	private Button _toExternalWindowButton;
	public AssetPaletteUi _assetPaletteUi;
	
	#region Signals
	[Signal]
	public delegate void HelpDialogOpenedEventHandler();
	
	[Signal]
	public delegate void ToExternalWindowEventHandler();
	#endregion

	public void Init()
	{
		_spawnParentSelectionUi = GetNode<NodePathSelectorUi>(spawnParentSelectionUiPath);
		_spawnParentSelectionUi.Init();
		snappingUi = GetNode<SnappingUi>(snappingUiPath);
		snappingUi.Init();
		placementUi = GetNode<PlacementUi>(placementUiPath);
		placementUi.Init();
		_aboutDialog = GetNode<AcceptDialog>(aboutDialog);
		_helpDialog = GetNode<HelpDialog>(helpDialog);
		GetNode<Button>(helpButton).Pressed += () =>
		{
			_helpDialog.Position = GetViewport().GetWindow().Position + (Vector2I)GetViewportRect().GetCenter() - _helpDialog.Size/2;
			ClampWindowToScreen(_helpDialog, this);
			EmitSignal(SignalName.HelpDialogOpened);
			_helpDialog.Popup();
		};
		GetNode<Button>(aboutButton).Pressed += OpenAboutDialog;
		_toExternalWindowButton = GetNode<Button>(toExternalWindowButton);
		_toExternalWindowButton.Pressed += () => EmitSignal(SignalName.ToExternalWindow);
		_assetPaletteUi = GetNode<AssetPaletteUi>(assetPaletteUi);
		_assetPaletteUi.Init(GetNode<DynamicPreviewPanel>(dynamicPreviewPanel));
	}
	
	public void ApplyTheme(Control baseControl)
	{
		_spawnParentSelectionUi.ApplyTheme(baseControl);
		snappingUi.ApplyTheme(baseControl);
		placementUi.ApplyTheme(baseControl);
		
		#if GODOT4_1_OR_GREATER
		var externalWindowIcon = baseControl.GetThemeIcon("MakeFloating", "EditorIcons");
		#else
		var externalWindowIcon = baseControl.GetThemeIcon("Window", "EditorIcons");
		#endif
		_toExternalWindowButton.Icon = externalWindowIcon;
		_toExternalWindowButton.Text = "";
		
		_assetPaletteUi.ApplyTheme(baseControl);
	}
	
	public void OpenAboutDialog()
	{
		_aboutDialog.Position = GetViewport().GetWindow().Position + (Vector2I)GetViewportRect().GetCenter() - _aboutDialog.Size/2;
		ClampWindowToScreen(_aboutDialog, this);
		#if GODOT4_1_OR_GREATER
		_aboutDialog.GetParentOrNull<Node>()?.RemoveChild(_aboutDialog);
		_aboutDialog.PopupExclusive(this);
		#else
		_aboutDialog.Popup();
		#endif
	}

	public void InitHelpDialog(System.Collections.Generic.Dictionary<string, string> shortcutDictionary)
	{
		_helpDialog.InitShortcutTable(shortcutDictionary);
	}

	public void OnSceneChanged()
	{
		placementUi.OnSceneChanged();
		snappingUi.OnSceneChanged();
	}

	public void OnAttachmentChanged(bool isAttachedToEditor)
	{
		_toExternalWindowButton.Visible = isAttachedToEditor;
		if(isAttachedToEditor) {
			// prevent disposal
			_aboutDialog.GetParentOrNull<Node>()?.RemoveChild(_aboutDialog); 
			_helpDialog.GetParentOrNull<Node>()?.RemoveChild(_helpDialog);
		}
	}
	
	public static bool TryParseFloat(string text, out float val)
	{
		if (text.StartsWith('.')) text = "0" + text;
		return float.TryParse(text, NumberStyles.Float, NumberFormatInfo.InvariantInfo, out val);
	}

	public static void ClampWindowToScreen(Window w, Control controlOnScreen)
	{
		var screenPos = DisplayServer.ScreenGetPosition(controlOnScreen.GetWindow().CurrentScreen); // position of screen on a multi-monitor setup
		var min = screenPos + Vector2I.Down * 30;
		var max = screenPos + DisplayServer.ScreenGetSize(controlOnScreen.GetWindow().CurrentScreen) - w.Size -
				  Vector2I.Down * 30;
		
		if (min < max)
		{
			w.Position = w.Position.Clamp(min, max); // clamp such that entire window is on screen
		}
		else // clamp such that window's TitleBar is on the screen
		{
			w.Position = min;
		}
	}
}

#endif
