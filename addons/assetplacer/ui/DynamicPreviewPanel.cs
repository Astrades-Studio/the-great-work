// DynamicPreviewPanel.cs
// Copyright (c) 2024 CookieBadger. All Rights Reserved.

#if TOOLS
#nullable disable
using Godot;

namespace AssetPlacer;

[Tool]
public partial class DynamicPreviewPanel : Panel
{
	public const string PreviewColor = "Dynamic_Preview_Background_Color";
	private const Key ConfirmPreviewKey = Key.Space;
	[Export] private NodePath _textureRectPath;
	[Export] private NodePath _closeButtonPath;
	[Export] private NodePath _updateButtonPath;
	[Export] private NodePath _previewPanelPath;
	[Export] private NodePath _assetNameLabelPath;
	[Export] private NodePath _backgroundPanelPath;

	private TextureRect _textureRect;
	private Button _closeButton;
	private Button _updateButton;
	private Control _previewPanel;
	private Label _assetNameLabel;
	private Panel _backgroundPanel;
	
	private DynamicPreviewController _dynamicPreviewController;
	private AssetPlacerButton _assetButton;
	
	[Signal]
	public delegate void CloseEventHandler(string assetPath, bool updatePreviews);

	public void InitUi()
	{
		_textureRect = GetNode<TextureRect>(_textureRectPath);
		_closeButton = GetNode<Button>(_closeButtonPath);
		_updateButton = GetNode<Button>(_updateButtonPath);
		_updateButton.TooltipText = $"Update the thumbnail shown in the library ({ConfirmPreviewKey.ToString()})";
		_previewPanel = GetNode<Control>(_previewPanelPath);
		_assetNameLabel = GetNode<Label>(_assetNameLabelPath);
		
		Resized += Reposition;
		_closeButton.Pressed += () => ClosePreview(false);
		_updateButton.Pressed += () => ClosePreview(true);
		_backgroundPanel = GetNode<Panel>(_backgroundPanelPath);
		Settings.RegisterSetting(Settings.DefaultCategory, PreviewColor, new Color("777777"), Variant.Type.Color);
	}

	public override void _Process(double delta)
	{
		if (Engine.IsEditorHint() && _dynamicPreviewController != null && _dynamicPreviewController.Active)
		{
			var theta = _dynamicPreviewController.SphericalCameraCoordinates.Y;
			var material = _backgroundPanel.Material as ShaderMaterial;
			material?.SetShaderParameter("theta", theta);
			var color = Settings.GetSetting(Settings.DefaultCategory, PreviewColor);
			material?.SetShaderParameter("color", color.AsColor());
		}
	}
	
	public void InitViewport(ViewportTexture vpTexture, DynamicPreviewController dynamicPreviewController)
	{
		_dynamicPreviewController = dynamicPreviewController;
		_textureRect.Texture = vpTexture;
	}

	public void ApplyTheme(Control baseControl)
	{
		_closeButton.Icon = baseControl.GetThemeIcon("Close", "EditorIcons");
		_closeButton.Text = "";
	}
	
	public override void _Input(InputEvent @event)
	{
		if (!Engine.IsEditorHint()) return;

		if(!Visible) return;

		if (@event is InputEventKey keyEvent && _textureRect.HasFocus())
		{
			if ((keyEvent.Keycode == AssetPlacerButton.ToggleDynamicPreviewKey || keyEvent.Keycode == Key.Escape || keyEvent.Keycode == ConfirmPreviewKey) && keyEvent.Pressed && !keyEvent.IsEcho())
			{
				ClosePreview(keyEvent.Keycode == ConfirmPreviewKey);
				GetTree().Root.SetInputAsHandled();
			}
		}
		
		var handle = _dynamicPreviewController.HandleInput(@event, _textureRect);
		if(handle) GetTree().Root.SetInputAsHandled();
	}

	public void ShowPreview(AssetPlacerButton assetButton)
	{
		_assetButton = assetButton;
		_assetNameLabel.Text = assetButton.assetName;
		_assetNameLabel.TooltipText = assetButton.assetPath;
		Reposition();
		_textureRect.GrabFocus();
	}
	
	private void Reposition()
	{
		if (_assetButton == null || !Visible) return;
		var buttonPosRelativeToParent = _assetButton.GetGlobalRect().GetCenter() - GlobalPosition;
		var posOnButton = buttonPosRelativeToParent - new Vector2(_previewPanel.Size.X/2f, _previewPanel.Size.Y/2f);
		var pos = GetParent<Control>().Size - _previewPanel.Size;
		var maxPos = new Vector2(Mathf.Max(pos.X, 0f), Mathf.Max(pos.Y, 0f));
		_previewPanel.Position = posOnButton.Clamp(Vector2.Zero, maxPos);
	}

	private void ClosePreview(bool updatePreview)
	{
		EmitSignal(SignalName.Close, _assetButton.assetPath, updatePreview);
	}
}
#endif
